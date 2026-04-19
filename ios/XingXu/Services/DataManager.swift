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
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    @Published var tasks: [TaskItem] = []
    @Published var moods: [MoodEntry] = []
    @Published var settings: AppSettings = AppSettings()
    @Published var customTemplates: [ScheduleTemplate] = []
    @Published var currentDate: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }()
    
    private init() {
        loadAll()
        loadCustomTemplates()
        generateRepeatingTasksIfNeeded()
    }
    
    // MARK: - Load
    
    func loadAll() {
        loadTasks()
        loadMoods()
        loadSettings()
        loadCustomTemplates()
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
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
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
