import WidgetKit

/// 小组件时间线条目
struct ScheduleEntry: TimelineEntry {
    let date: Date
    let scheduleData: WidgetScheduleData?
}
