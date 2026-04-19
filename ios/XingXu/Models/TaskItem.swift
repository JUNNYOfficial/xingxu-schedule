import Foundation

/// 任务模型
struct TaskItem: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var time: String
    var endTime: String?
    var icon: String
    var completed: Bool
    var date: String  // YYYY-MM-DD
    var tag: String
    var repeatPattern: String
    var remindMinutes: Int?
    var imageData: Data?
    var createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        time: String,
        endTime: String? = nil,
        icon: String = "",
        completed: Bool = false,
        date: String,
        tag: String = "",
        repeatPattern: String = "none",
        remindMinutes: Int? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.time = time
        self.endTime = endTime
        self.icon = icon
        self.completed = completed
        self.date = date
        self.tag = tag
        self.repeatPattern = repeatPattern
        self.remindMinutes = remindMinutes
        self.imageData = imageData
        self.createdAt = Date()
    }
    
    /// 时间排序用的比较值
    var timeValue: Int {
        let parts = time.split(separator: ":")
        let hour = Int(parts.first ?? "0") ?? 0
        let minute = Int(parts.last ?? "0") ?? 0
        return hour * 60 + minute
    }
    
    /// 格式化显示的时间
    var displayTime: String {
        if let end = endTime, !end.isEmpty {
            return "\(time) - \(end)"
        }
        return time
    }
    
    /// 标签颜色
    var tagColor: String {
        switch tag {
        case "工作": return "#3B82F6"
        case "学习": return "#8B5CF6"
        case "生活": return "#10B981"
        case "健康": return "#F59E0B"
        case "娱乐": return "#EC4899"
        case "重要": return "#EF4444"
        default: return "#6B7280"
        }
    }
}

/// 预定义标签
struct TaskTags {
    static let all = ["工作", "学习", "生活", "健康", "娱乐", "重要"]
    static let colors: [String: String] = [
        "工作": "#3B82F6",
        "学习": "#8B5CF6",
        "生活": "#10B981",
        "健康": "#F59E0B",
        "娱乐": "#EC4899",
        "重要": "#EF4444"
    ]
}
