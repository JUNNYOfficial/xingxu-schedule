import Foundation
import WidgetKit
import UserNotifications
import UIKit

/// 核心数据管理器
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let suiteName = "group.com.xingxu.schedule"
    private let tasksKey = "xingxu_tasks"
    private let moodsKey = "xingxu_moods"
    private let settingsKey = "xingxu_settings"
    private let currentDateKey = "xingxu_current_date"
    private let lastRepeatGenKey = "xingxu_last_repeat_gen"
    private let customTemplatesKey = "xingxu_custom_templates"
    private let menstrualRecordsKey = "xingxu_menstrual_records"
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    @Published var tasks: [TaskItem] = []
    @Published var moods: [MoodEntry] = []
    @Published var settings: AppSettings = AppSettings()
    @Published var customTemplates: [ScheduleTemplate] = []
    @Published var menstrualRecords: [MenstrualRecord] = []
    @Published var currentDate: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }()
    
    private init() {
        loadAll()
        loadCustomTemplates()
        loadMenstrualRecords()
        generateRepeatingTasksIfNeeded()
        insertSampleDataIfNeeded()
        insertSampleCycleDataIfNeeded()
    }
    
    // MARK: - Sample Data
    
    private func insertSampleDataIfNeeded() {
        guard let defaults = defaults else { return }
        let key = "xingxu_has_launched_before"
        guard !defaults.bool(forKey: key) else { return }
        
        let today = currentDate
        tasks = [
            TaskItem(name: "起床整理", time: "07:30", icon: "🛏️", completed: true, date: today, tag: "生活"),
            TaskItem(name: "刷牙洗脸", time: "07:45", icon: "🪥", completed: true, date: today, tag: "健康"),
            TaskItem(name: "吃早餐", time: "08:00", icon: "🍳", date: today, tag: "生活"),
            TaskItem(name: "上学", time: "08:30", icon: "🎒", date: today, tag: "学习")
        ]
        
        moods = [
            MoodEntry(date: today, value: 4, note: "今天心情不错")
        ]
        
        saveTasks()
        saveMoods()
        defaults.set(true, forKey: key)
    }
    
    private func insertSampleCycleDataIfNeeded() {
        guard let defaults = defaults else { return }
        let key = "xingxu_has_cycle_sample"
        guard !defaults.bool(forKey: key) else { return }
        
        // 插入3条示例周期记录（模拟不规律周期：28天、35天、26天）
        let calendar = Calendar.current
        let today = Date()
        
        menstrualRecords = [
            MenstrualRecord(
                startDate: calendar.date(byAdding: .day, value: -89, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -85, to: today),
                flowLevel: .medium,
                symptoms: [.cramps, .moodSwings]
            ),
            MenstrualRecord(
                startDate: calendar.date(byAdding: .day, value: -54, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -50, to: today),
                flowLevel: .light,
                symptoms: [.fatigue, .sensorySensitivity]
            ),
            MenstrualRecord(
                startDate: calendar.date(byAdding: .day, value: -28, to: today)!,
                endDate: calendar.date(byAdding: .day, value: -24, to: today),
                flowLevel: .heavy,
                symptoms: [.cramps, .anxiety, .socialWithdrawal]
            )
        ]
        
        saveMenstrualRecords()
        defaults.set(true, forKey: key)
    }
    
    // MARK: - Load
    
    func loadAll() {
        loadTasks()
        loadMoods()
        loadSettings()
        loadCustomTemplates()
        loadMenstrualRecords()
    }
    
    func loadTasks() {
        guard let defaults = defaults,
              let data = defaults.data(forKey: tasksKey),
              let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) else {
            tasks = []
            return
        }
        tasks = decoded
    }
    
    func loadMoods() {
        guard let defaults = defaults,
              let data = defaults.data(forKey: moodsKey),
              let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) else {
            moods = []
            return
        }
        moods = decoded
    }
    
    func loadSettings() {
        guard let defaults = defaults,
              let data = defaults.data(forKey: settingsKey),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            settings = AppSettings()
            return
        }
        settings = decoded
    }
    
    // MARK: - Save
    
    func saveTasks() {
        guard let defaults = defaults,
              let encoded = try? JSONEncoder().encode(tasks) else { return }
        defaults.set(encoded, forKey: tasksKey)
        syncToWidget()
        iCloudSyncManager.shared.syncToCloud()
    }
    
    func saveMoods() {
        guard let defaults = defaults,
              let encoded = try? JSONEncoder().encode(moods) else { return }
        defaults.set(encoded, forKey: moodsKey)
        iCloudSyncManager.shared.syncToCloud()
    }
    
    func saveSettings() {
        guard let defaults = defaults,
              let encoded = try? JSONEncoder().encode(settings) else { return }
        defaults.set(encoded, forKey: settingsKey)
        iCloudSyncManager.shared.syncToCloud()
    }
    
    // MARK: - Custom Templates
    
    func loadCustomTemplates() {
        guard let defaults = defaults,
              let data = defaults.data(forKey: customTemplatesKey),
              let decoded = try? JSONDecoder().decode([ScheduleTemplate].self, from: data) else {
            customTemplates = []
            return
        }
        customTemplates = decoded
    }
    
    func saveCustomTemplates() {
        guard let defaults = defaults,
              let encoded = try? JSONEncoder().encode(customTemplates) else { return }
        defaults.set(encoded, forKey: customTemplatesKey)
        iCloudSyncManager.shared.syncToCloud()
    }
    
    func loadMenstrualRecords() {
        guard let defaults = defaults,
              let data = defaults.data(forKey: menstrualRecordsKey),
              let decoded = try? JSONDecoder().decode([MenstrualRecord].self, from: data) else {
            menstrualRecords = []
            return
        }
        menstrualRecords = decoded
    }
    
    func saveMenstrualRecords() {
        guard let defaults = defaults,
              let encoded = try? JSONEncoder().encode(menstrualRecords) else { return }
        defaults.set(encoded, forKey: menstrualRecordsKey)
        scheduleCycleNotification()
    }
    
    func addMenstrualRecord(_ record: MenstrualRecord) {
        var newRecord = record
        newRecord.modifiedAt = Date()
        menstrualRecords.append(newRecord)
        saveMenstrualRecords()
    }
    
    func deleteMenstrualRecord(id: String) {
        menstrualRecords.removeAll { $0.id == id }
        saveMenstrualRecords()
    }
    
    func saveCustomTemplate(from date: String, name: String) {
        let dayTasks = tasksForDate(date)
        guard !dayTasks.isEmpty else { return }
        
        let templateTasks = dayTasks.map {
            TemplateTask(name: $0.name, time: $0.time, icon: $0.icon, tag: $0.tag)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateObj = formatter.date(from: date) ?? Date()
        formatter.dateFormat = "M月d日"
        let dateStr = formatter.string(from: dateObj)
        
        let template = ScheduleTemplate(
            name: name.isEmpty ? "\(dateStr)的日程" : name,
            icon: "📋",
            description: "共 \(templateTasks.count) 个任务",
            tasks: templateTasks,
            color: "#5B7CF5",
            isUserCreated: true
        )
        
        customTemplates.append(template)
        saveCustomTemplates()
    }
    
    func deleteCustomTemplate(id: String) {
        customTemplates.removeAll { $0.id == id }
        saveCustomTemplates()
    }
    
    var allTemplates: [ScheduleTemplate] {
        ScheduleTemplate.presets + customTemplates
    }
    
    // MARK: - Task Operations
    
    func tasksForDate(_ date: String) -> [TaskItem] {
        tasks.filter { $0.date == date }
            .sorted {
                if $0.sortOrder != $1.sortOrder {
                    return $0.sortOrder < $1.sortOrder
                }
                return $0.timeValue < $1.timeValue
            }
    }
    
    func addTask(_ task: TaskItem) {
        var newTask = task
        newTask.modifiedAt = Date()
        tasks.append(newTask)
        saveTasks()
        scheduleNotification(for: newTask)
    }
    
    func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updated = task
            updated.modifiedAt = Date()
            tasks[index] = updated
            saveTasks()
            scheduleNotification(for: updated)
        }
    }
    
    func deleteTask(id: String) {
        tasks.removeAll { $0.id == id }
        saveTasks()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func moveTask(for date: String, from indices: IndexSet, to offset: Int) {
        var dayTasks = tasks.filter { $0.date == date }
        dayTasks.sort {
            if $0.sortOrder != $1.sortOrder {
                return $0.sortOrder < $1.sortOrder
            }
            return $0.timeValue < $1.timeValue
        }
        dayTasks.move(fromOffsets: indices, toOffset: offset)
        for (index, task) in dayTasks.enumerated() {
            if let i = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[i].sortOrder = index
                tasks[i].modifiedAt = Date()
            }
        }
        saveTasks()
    }
    
    func toggleComplete(id: String) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].completed.toggle()
            tasks[index].modifiedAt = Date()
            
            // 如果任务完成，所有子步骤也标记完成
            if tasks[index].completed {
                for i in tasks[index].subSteps.indices {
                    tasks[index].subSteps[i].completed = true
                }
            }
            
            saveTasks()
            
            if tasks[index].completed {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            } else {
                scheduleNotification(for: tasks[index])
            }
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    func toggleSubStep(taskId: String, subStepId: String) {
        if let taskIndex = tasks.firstIndex(where: { $0.id == taskId }) {
            if let stepIndex = tasks[taskIndex].subSteps.firstIndex(where: { $0.id == subStepId }) {
                tasks[taskIndex].subSteps[stepIndex].completed.toggle()
                tasks[taskIndex].modifiedAt = Date()
                
                // 如果所有子步骤完成，任务也标记完成
                let allDone = tasks[taskIndex].subSteps.allSatisfy(\.completed)
                if allDone && !tasks[taskIndex].subSteps.isEmpty {
                    tasks[taskIndex].completed = true
                } else if !allDone {
                    tasks[taskIndex].completed = false
                }
                
                saveTasks()
                
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    func clearTasksForDate(_ date: String) {
        let idsToRemove = tasks.filter { $0.date == date }.map(\.id)
        tasks.removeAll { $0.date == date }
        saveTasks()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
    }
    
    // MARK: - Mood Operations
    
    func moodForDate(_ date: String) -> MoodEntry? {
        moods.first { $0.date == date }
    }
    
    func saveMood(_ mood: MoodEntry) {
        var updated = mood
        updated.modifiedAt = Date()
        moods.removeAll { $0.date == updated.date }
        moods.append(updated)
        saveMoods()
        
        // 同步到 HealthKit
        if settings.healthSyncEnabled {
            Task {
                await HealthManager.shared.syncMoodToHealth(updated)
            }
        }
    }
    
    // MARK: - Statistics
    
    func stats(forDays: Int) -> DailyStats {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -(forDays - 1), to: endDate)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var dailyData: [(date: String, total: Int, completed: Int)] = []
        var current = startDate
        
        while current <= endDate {
            let dateStr = formatter.string(from: current)
            let dayTasks = tasksForDate(dateStr)
            dailyData.append((dateStr, dayTasks.count, dayTasks.filter(\.completed).count))
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        let total = dailyData.reduce(0) { $0 + $1.total }
        let completed = dailyData.reduce(0) { $0 + $1.completed }
        let rate = total > 0 ? Double(completed) / Double(total) * 100 : 0
        
        // Hour stats
        var hourStats: [Int: (total: Int, completed: Int)] = [:]
        for h in 0..<24 { hourStats[h] = (0, 0) }
        
        for task in tasks {
            let hour = task.timeValue / 60
            if let stat = hourStats[hour] {
                hourStats[hour] = (stat.total + 1, stat.completed + (task.completed ? 1 : 0))
            }
        }
        
        // Tag stats
        var tagStats: [String: Int] = [:]
        for task in tasks {
            tagStats[task.tag, default: 0] += 1
        }
        
        // Mood data
        let filteredMoods = moods.filter { m in
            dailyData.contains { $0.date == m.date }
        }.sorted { $0.date < $1.date }
        
        return DailyStats(
            dailyData: dailyData,
            totalTasks: total,
            completedTasks: completed,
            completionRate: rate,
            hourStats: hourStats,
            tagStats: tagStats,
            moods: filteredMoods
        )
    }
    
    // MARK: - Widget Sync
    
    func syncToWidget() {
        let dayTasks = tasksForDate(currentDate)
        let widgetData = WidgetScheduleData(
            date: currentDate,
            tasks: dayTasks.map {
                WidgetTask(
                    id: $0.id,
                    name: $0.name,
                    time: $0.time,
                    completed: $0.completed,
                    tag: $0.tag,
                    icon: $0.icon
                )
            },
            totalTasks: dayTasks.count,
            completedTasks: dayTasks.filter(\.completed).count,
            updatedAt: Date()
        )
        SharedDataManager.shared.saveScheduleData(widgetData)
        WidgetCenter.shared.reloadTimelines(ofKind: "XingXuWidget")
    }
    
    // MARK: - Repeating Tasks
    
    func generateRepeatingTasksIfNeeded() {
        guard let defaults = defaults else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        
        let sourceTasks = tasks.filter { $0.repeatPattern != "none" }
        guard !sourceTasks.isEmpty else { return }
        
        // 确定生成起始日期
        let lastGenString = defaults.string(forKey: lastRepeatGenKey) ?? ""
        var startDate: Date
        if let lastGen = formatter.date(from: lastGenString) {
            startDate = Calendar.current.date(byAdding: .day, value: 1, to: lastGen)!
        } else {
            // 首次运行：从最早母任务的日期开始
            if let earliest = sourceTasks.compactMap({ formatter.date(from: $0.date) }).min() {
                startDate = earliest
            } else {
                return
            }
        }
        
        // 生成到未来 7 天
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        guard startDate <= endDate else { return }
        
        var current = startDate
        var generatedCount = 0
        
        while current <= endDate {
            let dateStr = formatter.string(from: current)
            
            for source in sourceTasks {
                guard shouldGenerateRepeat(for: dateStr, source: source) else { continue }
                
                // 检查是否已存在同名同时间的任务（排除母任务本身）
                let exists = tasks.contains {
                    $0.name == source.name && $0.time == source.time && $0.date == dateStr
                }
                if exists { continue }
                
                let newTask = TaskItem(
                    name: source.name,
                    time: source.time,
                    endTime: source.endTime,
                    icon: source.icon,
                    completed: false,
                    date: dateStr,
                    tag: source.tag,
                    repeatPattern: "none",
                    remindMinutes: source.remindMinutes
                )
                tasks.append(newTask)
                generatedCount += 1
            }
            
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        
        if generatedCount > 0 {
            saveTasks()
        }
        defaults.set(formatter.string(from: today), forKey: lastRepeatGenKey)
    }
    
    private func shouldGenerateRepeat(for dateString: String, source: TaskItem) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString),
              let sourceDate = formatter.date(from: source.date) else { return false }
        
        // 不覆盖母任务当天
        if Calendar.current.isDate(date, inSameDayAs: sourceDate) { return false }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = (weekday == 1 || weekday == 7)
        
        switch source.repeatPattern {
        case "daily":
            return true
        case "weekly":
            return calendar.component(.weekday, from: date) == calendar.component(.weekday, from: sourceDate)
        case "workdays":
            return !isWeekend
        case "weekends":
            return isWeekend
        case "monthly":
            return calendar.component(.day, from: date) == calendar.component(.day, from: sourceDate)
        default:
            return false
        }
    }
    
    // MARK: - Notifications
    
    private func scheduleNotification(for task: TaskItem) {
        guard settings.notificationsEnabled,
              let remind = task.remindMinutes,
              !task.completed else { return }
        
        // 只提醒重要任务
        if settings.onlyRemindImportant && task.tag != "重要" { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let taskDateTime = formatter.date(from: "\(task.date) \(task.time)") else { return }
        
        let remindDate = Calendar.current.date(byAdding: .minute, value: -remind, to: taskDateTime)!
        guard remindDate > Date() else { return }
        
        // 勿扰时段检查
        let hour = Calendar.current.component(.hour, from: remindDate)
        let start = settings.doNotDisturbStartHour
        let end = settings.doNotDisturbEndHour
        let inDND: Bool
        if start > end {
            // 跨午夜，如 22:00-08:00
            inDND = hour >= start || hour < end
        } else {
            inDND = hour >= start && hour < end
        }
        guard !inDND else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "星序"
        content.body = "「\(task.name)」快要开始了"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: remindDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: task.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// 调度经前预警通知
    private func scheduleCycleNotification() {
        guard settings.notificationsEnabled,
              settings.cycleReminderEnabled,
              !menstrualRecords.isEmpty else { return }
        
        let prediction = CyclePredictor.predict(records: menstrualRecords)
        guard let earliest = prediction.nextWindowEarliest,
              let latest = prediction.nextWindowLatest else { return }
        
        let center = UNUserNotificationCenter.current()
        let cycleNotificationId = "xingxu_cycle_reminder"
        
        // 取消旧的周期通知
        center.removePendingNotificationRequests(withIdentifiers: [cycleNotificationId])
        
        let today = Date()
        let calendar = Calendar.current
        
        // 计算预警日期：预测窗口前3天开始提醒
        guard let alertDate = calendar.date(byAdding: .day, value: -3, to: earliest) else { return }
        
        // 如果预警日期已过但窗口未结束，立即提醒
        if alertDate <= today && today <= latest {
            let content = UNMutableNotificationContent()
            content.title = "星序 · 周期提醒"
            content.body = "这几天周期可能要来了，可以提前做好准备"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: cycleNotificationId, content: content, trigger: trigger)
            center.add(request)
            return
        }
        
        // 如果预警日期在未来，安排定时通知
        guard alertDate > today else { return }
        
        // 勿扰检查
        let alertHour = calendar.component(.hour, from: alertDate)
        let start = settings.doNotDisturbStartHour
        let end = settings.doNotDisturbEndHour
        let inDND: Bool
        if start > end {
            inDND = alertHour >= start || alertHour < end
        } else {
            inDND = alertHour >= start && alertHour < end
        }
        
        // 如果在勿扰时段，调整到勿扰结束后
        var finalAlertDate = alertDate
        if inDND {
            var components = calendar.dateComponents([.year, .month, .day], from: alertDate)
            components.hour = end
            components.minute = 0
            if let adjusted = calendar.date(from: components) {
                finalAlertDate = adjusted
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "星序 · 周期提醒"
        
        // 根据规律度调整文案
        if prediction.regularityScore < 30 {
            content.body = "这几天周期可能要来了（时间不太固定），可以提前做好准备"
        } else {
            content.body = "周期快要来了，可以提前做好准备"
        }
        content.sound = .default
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalAlertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: cycleNotificationId, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("周期通知调度失败: \(error)")
            }
        }
    }
}

// MARK: - Statistics Model

struct DailyStats {
    let dailyData: [(date: String, total: Int, completed: Int)]
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
    let hourStats: [Int: (total: Int, completed: Int)]
    let tagStats: [String: Int]
    let moods: [MoodEntry]
}
