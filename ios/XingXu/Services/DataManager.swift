import Foundation
import WidgetKit

/// 核心数据管理器
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let suiteName = "group.com.xingxu.schedule"
    private let tasksKey = "xingxu_tasks"
    private let moodsKey = "xingxu_moods"
    private let settingsKey = "xingxu_settings"
    private let currentDateKey = "xingxu_current_date"
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    @Published var tasks: [TaskItem] = []
    @Published var moods: [MoodEntry] = []
    @Published var settings: AppSettings = AppSettings()
    @Published var currentDate: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }()
    
    private init() {
        loadAll()
    }
    
    // MARK: - Load
    
    func loadAll() {
        loadTasks()
        loadMoods()
        loadSettings()
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
    }
    
    func saveMoods() {
        guard let defaults = defaults,
              let encoded = try? JSONEncoder().encode(moods) else { return }
        defaults.set(encoded, forKey: moodsKey)
    }
    
    func saveSettings() {
        guard let defaults = defaults,
              let encoded = try? JSONEncoder().encode(settings) else { return }
        defaults.set(encoded, forKey: settingsKey)
    }
    
    // MARK: - Task Operations
    
    func tasksForDate(_ date: String) -> [TaskItem] {
        tasks.filter { $0.date == date }.sorted { $0.timeValue < $1.timeValue }
    }
    
    func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveTasks()
        scheduleNotification(for: task)
    }
    
    func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
            scheduleNotification(for: task)
        }
    }
    
    func deleteTask(id: String) {
        tasks.removeAll { $0.id == id }
        saveTasks()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func toggleComplete(id: String) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].completed.toggle()
            saveTasks()
        }
    }
    
    func clearTasksForDate(_ date: String) {
        tasks.removeAll { $0.date == date }
        saveTasks()
    }
    
    // MARK: - Mood Operations
    
    func moodForDate(_ date: String) -> MoodEntry? {
        moods.first { $0.date == date }
    }
    
    func saveMood(_ mood: MoodEntry) {
        moods.removeAll { $0.date == mood.date }
        moods.append(mood)
        saveMoods()
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
    
    private func syncToWidget() {
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
    
    // MARK: - Notifications
    
    private func scheduleNotification(for task: TaskItem) {
        guard settings.notificationsEnabled,
              let remind = task.remindMinutes,
              !task.completed else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let taskDateTime = formatter.date(from: "\(task.date) \(task.time)") else { return }
        
        let remindDate = Calendar.current.date(byAdding: .minute, value: -remind, to: taskDateTime)!
        guard remindDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "星序 - 任务提醒"
        content.body = "任务「\(task.name)」将在 \(remind) 分钟后开始"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: remindDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: task.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
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
