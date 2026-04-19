import WidgetKit
import SwiftUI

/// 星序小组件主视图
struct XingXuWidgetEntryView: View {
    var entry: ScheduleProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .systemExtraLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - 小型小组件

struct SmallWidgetView: View {
    let entry: ScheduleProvider.Entry
    
    var data: WidgetScheduleData { entry.scheduleData ?? placeholder }
    
    var placeholder: WidgetScheduleData {
        WidgetScheduleData(date: "", tasks: [], totalTasks: 0, completedTasks: 0, updatedAt: Date())
    }
    
    var progress: Double {
        guard data.totalTasks > 0 else { return 0 }
        return Double(data.completedTasks) / Double(data.totalTasks)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 标题
            HStack {
                Text("星序")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Text(formatDate(data.date))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if data.totalTasks == 0 {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    Text("今日无任务")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            } else {
                // 进度环形图
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress >= 1.0 ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    
                    VStack(spacing: 2) {
                        Text("\(data.completedTasks)/\(data.totalTasks)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        Text("已完成")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return "今天" }
        
        let today = Date()
        if Calendar.current.isDate(date, inSameDayAs: today) {
            return "今天"
        }
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - 中型小组件

struct MediumWidgetView: View {
    let entry: ScheduleProvider.Entry
    
    var data: WidgetScheduleData { entry.scheduleData ?? placeholder }
    
    var placeholder: WidgetScheduleData {
        WidgetScheduleData(date: "", tasks: [], totalTasks: 0, completedTasks: 0, updatedAt: Date())
    }
    
    var progress: Double {
        guard data.totalTasks > 0 else { return 0 }
        return Double(data.completedTasks) / Double(data.totalTasks)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧：进度
            VStack(spacing: 8) {
                Text("星序")
                    .font(.system(size: 14, weight: .bold))
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress >= 1.0 ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .frame(width: 65, height: 65)
                
                Text(formatDate(data.date))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            
            // 右侧：任务列表
            VStack(alignment: .leading, spacing: 6) {
                if data.tasks.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("今日暂无任务")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Spacer()
                } else {
                    ForEach(data.tasks.prefix(4)) { task in
                        HStack(spacing: 6) {
                            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundColor(task.completed ? .green : .gray)
                            
                            Text(task.icon ?? "")
                                .font(.system(size: 12))
                            
                            Text(task.name)
                                .font(.system(size: 13))
                                .lineLimit(1)
                                .strikethrough(task.completed)
                                .foregroundColor(task.completed ? .secondary : .primary)
                            
                            Spacer()
                            
                            Text(task.time)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if data.tasks.count > 4 {
                        Text("+\(data.tasks.count - 4) 个任务")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return "今天" }
        
        let today = Date()
        if Calendar.current.isDate(date, inSameDayAs: today) {
            return "今天"
        }
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - 大型小组件

struct LargeWidgetView: View {
    let entry: ScheduleProvider.Entry
    
    var data: WidgetScheduleData { entry.scheduleData ?? placeholder }
    
    var placeholder: WidgetScheduleData {
        WidgetScheduleData(date: "", tasks: [], totalTasks: 0, completedTasks: 0, updatedAt: Date())
    }
    
    var progress: Double {
        guard data.totalTasks > 0 else { return 0 }
        return Double(data.completedTasks) / Double(data.totalTasks)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("星序 · 今日日程")
                        .font(.system(size: 16, weight: .bold))
                    Text(formatDate(data.date))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 进度
                HStack(spacing: 8) {
                    Text("\(data.completedTasks)/\(data.totalTasks)")
                        .font(.system(size: 14, weight: .semibold))
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: progress >= 1.0 ? .green : .blue))
                        .frame(width: 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            Divider()
                .padding(.horizontal, 12)
            
            // 任务列表
            if data.tasks.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("今日暂无任务")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Text("打开星序添加今日计划")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                Spacer()
            } else {
                VStack(spacing: 0) {
                    ForEach(data.tasks.prefix(8)) { task in
                        TaskRowView(task: task)
                        if task.id != data.tasks.prefix(8).last?.id {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                    
                    if data.tasks.count > 8 {
                        HStack {
                            Spacer()
                            Text("+\(data.tasks.count - 8) 个更多任务")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 4)
                Spacer()
            }
        }
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return "" }
        
        let today = Date()
        let weekdaySymbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekday = weekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
        
        if Calendar.current.isDate(date, inSameDayAs: today) {
            return "今天 · \(weekday)"
        }
        formatter.dateFormat = "M月d日"
        return "\(formatter.string(from: date)) · \(weekday)"
    }
}

// MARK: - 任务行

struct TaskRowView: View {
    let task: WidgetTask
    
    var body: some View {
        HStack(spacing: 10) {
            // 状态图标
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(task.completed ? .green : .gray.opacity(0.5))
                .frame(width: 28)
            
            // 图标和名称
            HStack(spacing: 6) {
                if let icon = task.icon, !icon.isEmpty {
                    Text(icon)
                        .font(.system(size: 16))
                }
                
                Text(task.name)
                    .font(.system(size: 15))
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? .secondary : .primary)
            }
            
            Spacer()
            
            // 标签
            if let tag = task.tag, !tag.isEmpty {
                Text(tag)
                    .font(.system(size: 11))
                    .foregroundColor(tagColor(tag))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tagColor(tag).opacity(0.12))
                    .cornerRadius(4)
            }
            
            // 时间
            Text(task.time)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(minWidth: 42, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func tagColor(_ tag: String) -> Color {
        switch tag {
        case "工作": return .blue
        case "学习": return .purple
        case "生活": return .green
        case "健康": return .orange
        case "娱乐": return .pink
        case "重要": return .red
        default: return .gray
        }
    }
}

// MARK: - Widget 定义

struct XingXuWidget: Widget {
    let kind: String = "XingXuWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScheduleProvider()) { entry in
            XingXuWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("星序日程")
        .description("查看今日任务和完成进度")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
