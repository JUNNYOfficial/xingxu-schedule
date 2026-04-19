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
    var sortOrder: Int
    var createdAt: Date
    var modifiedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, time, endTime, icon, completed, date, tag
        case repeatPattern, remindMinutes, imageData, sortOrder, createdAt, modifiedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        time = try container.decode(String.self, forKey: .time)
        endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? ""
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        date = try container.decode(String.self, forKey: .date)
        tag = try container.decodeIfPresent(String.self, forKey: .tag) ?? ""
        repeatPattern = try container.decodeIfPresent(String.self, forKey: .repeatPattern) ?? "none"
        remindMinutes = try container.decodeIfPresent(Int.self, forKey: .remindMinutes)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? Date()
    }
    
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
        imageData: Data? = nil,
        sortOrder: Int = 0
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
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.modifiedAt = Date()
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
    
    /// 标签颜色 — 自闭症友好：统一柔和蓝灰色系
    var tagColor: String {
        // 不同标签用不同明度的蓝灰区分，保持低饱和度统一感
        switch tag {
        case "工作": return "#5A7A94"
        case "学习": return "#6B8BA3"
        case "生活": return "#7BA3C4"
        case "健康": return "#8FB8D4"
        case "娱乐": return "#A3CDE4"
        case "重要": return "#4A6A84"
        default: return "#9CA3AF"
        }
    }
}

/// 预定义标签
struct TaskTags {
    static let all = ["工作", "学习", "生活", "健康", "娱乐", "重要"]
    static let colors: [String: String] = [
        "工作": "#5A7A94",
        "学习": "#6B8BA3",
        "生活": "#7BA3C4",
        "健康": "#8FB8D4",
        "娱乐": "#A3CDE4",
        "重要": "#4A6A84"
    ]
}
