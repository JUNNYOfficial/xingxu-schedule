import Foundation
import SwiftUI

/// 日程模板
struct ScheduleTemplate: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var icon: String
    var description: String
    var tasks: [TemplateTask]
    var isDefault: Bool
    var color: String
    var isUserCreated: Bool
    var modifiedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, description, tasks
        case isDefault, color, isUserCreated, modifiedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "📋"
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        tasks = try container.decodeIfPresent([TemplateTask].self, forKey: .tasks) ?? []
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#5B7CF5"
        isUserCreated = try container.decodeIfPresent(Bool.self, forKey: .isUserCreated) ?? false
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? Date()
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String,
        description: String,
        tasks: [TemplateTask],
        isDefault: Bool = false,
        color: String = "#5B7CF5",
        isUserCreated: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.tasks = tasks
        self.isDefault = isDefault
        self.color = color
        self.isUserCreated = isUserCreated
        self.modifiedAt = Date()
    }
    
    /// SwiftUI Color from hex string
    var themeColor: Color {
        Color(hex: color)
    }
}

/// 模板中的任务
struct TemplateTask: Codable, Equatable {
    var name: String
    var time: String
    var icon: String
    var tag: String
}

// MARK: - 预设模板

extension ScheduleTemplate {
    static let presets: [ScheduleTemplate] = [
        ScheduleTemplate(
            id: "morning",
            name: "早晨 routine",
            icon: "🌅",
            description: "起床、洗漱、早餐、出门",
            tasks: [
                TemplateTask(name: "起床", time: "07:00", icon: "🛏️", tag: "生活"),
                TemplateTask(name: "刷牙洗脸", time: "07:15", icon: "🪥", tag: "生活"),
                TemplateTask(name: "吃早餐", time: "07:30", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "换衣服", time: "07:50", icon: "👕", tag: "生活"),
                TemplateTask(name: "准备出门", time: "08:00", icon: "🎒", tag: "生活")
            ],
            isDefault: true,
            color: "#5A7A94"
        ),
        ScheduleTemplate(
            id: "evening",
            name: "睡前 routine",
            icon: "🌙",
            description: "晚餐、洗澡、刷牙、读故事、睡觉",
            tasks: [
                TemplateTask(name: "吃晚餐", time: "18:00", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "洗澡", time: "19:30", icon: "🛁", tag: "生活"),
                TemplateTask(name: "刷牙", time: "20:00", icon: "🪥", tag: "生活"),
                TemplateTask(name: "读故事书", time: "20:15", icon: "📚", tag: "学习"),
                TemplateTask(name: "睡觉", time: "20:30", icon: "🛏️", tag: "生活")
            ],
            isDefault: true,
            color: "#6B8BA3"
        ),
        ScheduleTemplate(
            id: "school",
            name: "上学日",
            icon: "🎒",
            description: "完整的一天：从起床到睡觉",
            tasks: [
                TemplateTask(name: "起床", time: "07:00", icon: "🛏️", tag: "生活"),
                TemplateTask(name: "刷牙洗脸", time: "07:15", icon: "🪥", tag: "生活"),
                TemplateTask(name: "吃早餐", time: "07:30", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "出门上学", time: "08:00", icon: "🚶", tag: "生活"),
                TemplateTask(name: "到校", time: "08:30", icon: "🏫", tag: "学习"),
                TemplateTask(name: "课间休息", time: "10:00", icon: "🏃", tag: "娱乐"),
                TemplateTask(name: "午餐时间", time: "12:00", icon: "🍱", tag: "生活"),
                TemplateTask(name: "放学", time: "16:00", icon: "🏠", tag: "生活"),
                TemplateTask(name: "做作业", time: "16:30", icon: "✏️", tag: "学习"),
                TemplateTask(name: "吃晚餐", time: "18:00", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "洗澡", time: "19:30", icon: "🛁", tag: "生活"),
                TemplateTask(name: "睡觉", time: "20:30", icon: "🌙", tag: "生活")
            ],
            isDefault: true,
            color: "#7BA3C4"
        ),
        ScheduleTemplate(
            id: "weekend",
            name: "周末",
            icon: "🎡",
            description: "公园、游戏、放松",
            tasks: [
                TemplateTask(name: "起床", time: "08:00", icon: "🛏️", tag: "生活"),
                TemplateTask(name: "刷牙洗脸", time: "08:15", icon: "🪥", tag: "生活"),
                TemplateTask(name: "吃早餐", time: "08:30", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "去公园玩", time: "09:30", icon: "🎡", tag: "娱乐"),
                TemplateTask(name: "吃午餐", time: "12:00", icon: "🍱", tag: "生活"),
                TemplateTask(name: "玩游戏/玩具", time: "14:00", icon: "🎮", tag: "娱乐"),
                TemplateTask(name: "吃晚餐", time: "18:00", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "洗澡", time: "19:30", icon: "🛁", tag: "生活"),
                TemplateTask(name: "睡觉", time: "20:30", icon: "🌙", tag: "生活")
            ],
            isDefault: true,
            color: "#8FB8D4"
        ),
        ScheduleTemplate(
            id: "hospital",
            name: "去医院",
            icon: "🏥",
            description: "就医日的完整安排",
            tasks: [
                TemplateTask(name: "起床", time: "07:00", icon: "🛏️", tag: "生活"),
                TemplateTask(name: "刷牙洗脸", time: "07:15", icon: "🪥", tag: "生活"),
                TemplateTask(name: "吃早餐", time: "07:30", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "准备出门", time: "08:00", icon: "🎒", tag: "生活"),
                TemplateTask(name: "去医院", time: "08:30", icon: "🏥", tag: "健康"),
                TemplateTask(name: "候诊等待", time: "09:00", icon: "🪑", tag: "健康"),
                TemplateTask(name: "看医生", time: "09:30", icon: "👨‍⚕️", tag: "健康"),
                TemplateTask(name: "回家", time: "11:00", icon: "🏠", tag: "生活"),
                TemplateTask(name: "休息", time: "11:30", icon: "😴", tag: "生活"),
                TemplateTask(name: "吃午餐", time: "12:00", icon: "🍱", tag: "生活")
            ],
            isDefault: true,
            color: "#7BA3C4"
        ),
        ScheduleTemplate(
            id: "sensory",
            name: "感统训练日",
            icon: "🏃",
            description: "含感统课、作业、休息",
            tasks: [
                TemplateTask(name: "起床", time: "07:00", icon: "🛏️", tag: "生活"),
                TemplateTask(name: "刷牙洗脸", time: "07:15", icon: "🪥", tag: "生活"),
                TemplateTask(name: "吃早餐", time: "07:30", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "出门", time: "08:30", icon: "🚶", tag: "生活"),
                TemplateTask(name: "感统训练课", time: "09:00", icon: "🏃", tag: "健康"),
                TemplateTask(name: "吃午餐", time: "12:00", icon: "🍱", tag: "生活"),
                TemplateTask(name: "午休", time: "12:45", icon: "😴", tag: "生活"),
                TemplateTask(name: "做作业", time: "14:30", icon: "✏️", tag: "学习"),
                TemplateTask(name: "吃晚餐", time: "18:00", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "洗澡", time: "19:30", icon: "🛁", tag: "生活"),
                TemplateTask(name: "睡觉", time: "20:30", icon: "🌙", tag: "生活")
            ],
            isDefault: true,
            color: "#6B8BA3"
        ),
        ScheduleTemplate(
            id: "home",
            name: "居家日",
            icon: "🏠",
            description: "学习、游戏、画画",
            tasks: [
                TemplateTask(name: "起床", time: "08:00", icon: "🛏️", tag: "生活"),
                TemplateTask(name: "刷牙洗脸", time: "08:15", icon: "🪥", tag: "生活"),
                TemplateTask(name: "吃早餐", time: "08:30", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "学习时间", time: "09:00", icon: "📚", tag: "学习"),
                TemplateTask(name: "吃点心", time: "10:00", icon: "🍪", tag: "生活"),
                TemplateTask(name: "自由游戏", time: "10:30", icon: "🎮", tag: "娱乐"),
                TemplateTask(name: "吃午餐", time: "12:00", icon: "🍱", tag: "生活"),
                TemplateTask(name: "午休", time: "12:45", icon: "😴", tag: "生活"),
                TemplateTask(name: "画画/手工", time: "14:00", icon: "🎨", tag: "娱乐"),
                TemplateTask(name: "吃晚餐", time: "18:00", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "洗澡", time: "19:30", icon: "🛁", tag: "生活"),
                TemplateTask(name: "睡觉", time: "20:30", icon: "🌙", tag: "生活")
            ],
            isDefault: true,
            color: "#8FB8D4"
        ),
        ScheduleTemplate(
            id: "outing",
            name: "外出日",
            icon: "✈️",
            description: "外出活动、旅行、游玩",
            tasks: [
                TemplateTask(name: "起床", time: "07:30", icon: "🛏️", tag: "生活"),
                TemplateTask(name: "刷牙洗脸", time: "07:45", icon: "🪥", tag: "生活"),
                TemplateTask(name: "吃早餐", time: "08:00", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "准备出门", time: "08:30", icon: "🎒", tag: "生活"),
                TemplateTask(name: "外出活动", time: "09:00", icon: "✈️", tag: "娱乐"),
                TemplateTask(name: "吃午餐", time: "12:00", icon: "🍱", tag: "生活"),
                TemplateTask(name: "继续活动", time: "13:30", icon: "🎡", tag: "娱乐"),
                TemplateTask(name: "回家", time: "16:00", icon: "🏠", tag: "生活"),
                TemplateTask(name: "休息", time: "16:30", icon: "😴", tag: "生活"),
                TemplateTask(name: "吃晚餐", time: "18:00", icon: "🍽️", tag: "生活"),
                TemplateTask(name: "洗澡", time: "19:30", icon: "🛁", tag: "生活"),
                TemplateTask(name: "睡觉", time: "20:30", icon: "🌙", tag: "生活")
            ],
            isDefault: true,
            color: "#A3CDE4"
        )
    ]
}
