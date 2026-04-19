import WidgetKit

/// 小组件时间线提供者
struct ScheduleProvider: TimelineProvider {
    
    // 占位预览数据
    private let placeholderData = WidgetScheduleData(
        date: "2026-04-18",
        tasks: [
            WidgetTask(id: "1", name: "晨间阅读", time: "08:00", completed: true, tag: "学习", icon: "📚"),
            WidgetTask(id: "2", name: "午餐", time: "12:00", completed: false, tag: "生活", icon: "🍱"),
            WidgetTask(id: "3", name: "午休", time: "13:00", completed: false, tag: "健康", icon: "😴"),
            WidgetTask(id: "4", name: "运动", time: "17:00", completed: false, tag: "健康", icon: "🏃"),
            WidgetTask(id: "5", name: "晚餐", time: "18:30", completed: false, tag: "生活", icon: "🍽️")
        ],
        totalTasks: 5,
        completedTasks: 1,
        updatedAt: Date()
    )
    
    // MARK: - TimelineProvider
    
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), scheduleData: placeholderData)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let data = SharedDataManager.shared.loadScheduleData()
        let entry = ScheduleEntry(date: Date(), scheduleData: data ?? placeholderData)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let data = SharedDataManager.shared.loadScheduleData()
        let entry = ScheduleEntry(date: Date(), scheduleData: data)
        
        // 每 15 分钟刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
