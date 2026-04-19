import Foundation
import HealthKit

/// Apple HealthKit 管理器
@MainActor
class HealthManager: ObservableObject {
    static let shared = HealthManager()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAvailable: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var todayExerciseMinutes: Double = 0
    @Published var todayMindfulMinutes: Double = 0
    
    private init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Authorization
    
    /// 请求 HealthKit 权限
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        
        var typesToRead: Set<HKObjectType> = []
        var typesToWrite: Set<HKSampleType> = []
        
        // 正念时间（读写）
        if let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            typesToRead.insert(mindfulType)
            typesToWrite.insert(mindfulType)
        }
        
        // 运动时间（读）
        if let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            typesToRead.insert(exerciseType)
        }
        
        // 心情状态（iOS 18+，读写）
        if #available(iOS 18.0, *) {
            let moodType = HKObjectType.stateOfMindType()
            typesToRead.insert(moodType)
            typesToWrite.insert(moodType)
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            isAuthorized = true
            return true
        } catch {
            print("HealthKit 授权失败: \(error)")
            return false
        }
    }
    
    /// 检查是否已授权特定类型
    func checkAuthorizationStatus() async {
        guard isAvailable else { return }
        
        var allAuthorized = true
        
        if let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            let status = healthStore.authorizationStatus(for: mindfulType)
            if status != .sharingAuthorized { allAuthorized = false }
        }
        
        if #available(iOS 18.0, *) {
            let moodType = HKObjectType.stateOfMindType()
            let status = healthStore.authorizationStatus(for: moodType)
            if status != .sharingAuthorized { allAuthorized = false }
        }
        
        isAuthorized = allAuthorized
    }
    
    // MARK: - Write Data
    
    /// 写入正念时间（将任务标记为正念时段）
    func saveMindfulSession(startDate: Date, endDate: Date) async -> Bool {
        guard isAvailable,
              let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            return false
        }
        
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )
        
        do {
            try await healthStore.save(sample)
            return true
        } catch {
            print("保存正念时间失败: \(error)")
            return false
        }
    }
    
    /// 写入心情状态（iOS 18+）
    @available(iOS 18.0, *)
    func saveStateOfMind(value: Int, date: Date, note: String? = nil) async -> Bool {
        guard isAvailable else { return false }
        
        // 将 1-5 的心情值映射到 HealthKit 的 -1.0 ~ 1.0 范围
        // 1(差) -> -1.0, 3(一般) -> 0.0, 5(很好) -> 1.0
        let normalizedValue = Double(value - 3) / 2.0
        
        let stateOfMind = HKStateOfMind(
            date: date,
            kind: .momentaryEmotion,
            valence: normalizedValue,
            labels: [],
            associations: []
        )
        
        do {
            try await healthStore.save(stateOfMind)
            return true
        } catch {
            print("保存心情状态失败: \(error)")
            return false
        }
    }
    
    /// 同步心情记录到 HealthKit（兼容 iOS 16/18）
    func syncMoodToHealth(_ mood: MoodEntry) async {
        guard DataManager.shared.settings.healthSyncEnabled else { return }
        
        if #available(iOS 18.0, *) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = formatter.date(from: mood.date) else { return }
            _ = await saveStateOfMind(value: mood.value, date: date, note: mood.note)
        }
        // iOS 16-17 不支持 StateOfMind，跳过
    }
    
    // MARK: - Read Data
    
    /// 获取今日运动时间（分钟）
    func fetchTodayExerciseTime() async {
        guard isAvailable,
              let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let self = self, let result = result, let sum = result.sumQuantity() else {
                if let error = error { print("获取运动时间失败: \(error)") }
                return
            }
            Task { @MainActor in
                self.todayExerciseMinutes = sum.doubleValue(for: .minute())
            }
        }
        
        healthStore.execute(query)
    }
    
    /// 获取今日正念时间（分钟）
    func fetchTodayMindfulTime() async {
        guard isAvailable,
              let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: mindfulType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, error in
            guard let self = self, let samples = samples else {
                if let error = error { print("获取正念时间失败: \(error)") }
                return
            }
            
            let totalMinutes = samples.reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            }
            
            Task { @MainActor in
                self.todayMindfulMinutes = totalMinutes
            }
        }
        
        healthStore.execute(query)
    }
    
    /// 刷新所有健康数据
    func refreshAllData() async {
        guard isAuthorized else { return }
        await fetchTodayExerciseTime()
        await fetchTodayMindfulTime()
    }
}
