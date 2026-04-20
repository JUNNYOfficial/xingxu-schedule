import Foundation
import SwiftUI

/// 应用设置
struct AppSettings: Codable, Equatable {
    var theme: AppTheme
    var fontSize: FontSize
    var notificationsEnabled: Bool
    var notificationMinutes: Int
    var onlyRemindImportant: Bool
    var doNotDisturbStartHour: Int
    var doNotDisturbEndHour: Int
    var childModeEnabled: Bool
    var highContrastEnabled: Bool
    var colorCodingEnabled: Bool
    var healthSyncEnabled: Bool
    var cycleTrackingEnabled: Bool
    var cycleReminderEnabled: Bool
    var fullscreenAlarmEnabled: Bool
    var nickname: String?
    var avatarEmoji: String?
    var userId: String?
    var dailyWaterGoal: Int
    var homeLayout: [HomeSectionItem]
    
    init(
        theme: AppTheme = .system,
        fontSize: FontSize = .normal,
        notificationsEnabled: Bool = false,
        notificationMinutes: Int = 10,
        onlyRemindImportant: Bool = false,
        doNotDisturbStartHour: Int = 22,
        doNotDisturbEndHour: Int = 8,
        childModeEnabled: Bool = false,
        highContrastEnabled: Bool = false,
        colorCodingEnabled: Bool = true,
        healthSyncEnabled: Bool = false,
        cycleTrackingEnabled: Bool = false,
        cycleReminderEnabled: Bool = false,
        fullscreenAlarmEnabled: Bool = false,
        nickname: String? = nil,
        avatarEmoji: String? = nil,
        userId: String? = nil,
        dailyWaterGoal: Int = 2000,
        homeLayout: [HomeSectionItem]? = nil
    ) {
        self.theme = theme
        self.fontSize = fontSize
        self.notificationsEnabled = notificationsEnabled
        self.notificationMinutes = notificationMinutes
        self.onlyRemindImportant = onlyRemindImportant
        self.doNotDisturbStartHour = doNotDisturbStartHour
        self.doNotDisturbEndHour = doNotDisturbEndHour
        self.childModeEnabled = childModeEnabled
        self.highContrastEnabled = highContrastEnabled
        self.colorCodingEnabled = colorCodingEnabled
        self.healthSyncEnabled = healthSyncEnabled
        self.cycleTrackingEnabled = cycleTrackingEnabled
        self.cycleReminderEnabled = cycleReminderEnabled
        self.fullscreenAlarmEnabled = fullscreenAlarmEnabled
        self.nickname = nickname
        self.avatarEmoji = avatarEmoji
        self.userId = userId
        self.dailyWaterGoal = dailyWaterGoal
        self.homeLayout = homeLayout ?? HomeSectionItem.defaultLayout
    }
    
    enum CodingKeys: String, CodingKey {
        case theme, fontSize, notificationsEnabled, notificationMinutes
        case onlyRemindImportant, doNotDisturbStartHour, doNotDisturbEndHour
        case childModeEnabled, highContrastEnabled, colorCodingEnabled
        case healthSyncEnabled, cycleTrackingEnabled, cycleReminderEnabled, fullscreenAlarmEnabled
        case nickname, avatarEmoji, userId, dailyWaterGoal
        case homeLayout
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.theme = try container.decode(AppTheme.self, forKey: .theme)
        self.fontSize = try container.decode(FontSize.self, forKey: .fontSize)
        self.notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
        self.notificationMinutes = try container.decodeIfPresent(Int.self, forKey: .notificationMinutes) ?? 10
        self.onlyRemindImportant = try container.decodeIfPresent(Bool.self, forKey: .onlyRemindImportant) ?? false
        self.doNotDisturbStartHour = try container.decodeIfPresent(Int.self, forKey: .doNotDisturbStartHour) ?? 22
        self.doNotDisturbEndHour = try container.decodeIfPresent(Int.self, forKey: .doNotDisturbEndHour) ?? 8
        self.childModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .childModeEnabled) ?? false
        self.highContrastEnabled = try container.decodeIfPresent(Bool.self, forKey: .highContrastEnabled) ?? false
        self.colorCodingEnabled = try container.decodeIfPresent(Bool.self, forKey: .colorCodingEnabled) ?? true
        self.healthSyncEnabled = try container.decodeIfPresent(Bool.self, forKey: .healthSyncEnabled) ?? false
        self.cycleTrackingEnabled = try container.decodeIfPresent(Bool.self, forKey: .cycleTrackingEnabled) ?? false
        self.cycleReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .cycleReminderEnabled) ?? false
        self.fullscreenAlarmEnabled = try container.decodeIfPresent(Bool.self, forKey: .fullscreenAlarmEnabled) ?? false
        self.nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        self.avatarEmoji = try container.decodeIfPresent(String.self, forKey: .avatarEmoji)
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
        self.dailyWaterGoal = try container.decodeIfPresent(Int.self, forKey: .dailyWaterGoal) ?? 2000
        self.homeLayout = try container.decodeIfPresent([HomeSectionItem].self, forKey: .homeLayout) ?? HomeSectionItem.defaultLayout
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    case blue = "blue"
    case green = "green"
    case warm = "warm"
    case highContrast = "highContrast"
    
    var displayName: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        case .blue: return "天空蓝"
        case .green: return "自然绿"
        case .warm: return "暖色调"
        case .highContrast: return "高对比度"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light, .highContrast: return .light
        case .dark: return .dark
        case .system, .blue, .green, .warm: return nil
        }
    }
    
    var tintColor: Color? {
        switch self {
        case .blue: return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .green: return Color(red: 0.48, green: 0.61, blue: 0.75)
        case .warm: return Color(red: 0.95, green: 0.65, blue: 0.4)
        case .highContrast: return .black
        default: return nil
        }
    }
}

/// 数据导出/导入结构
struct ExportData: Codable {
    let tasks: [TaskItem]
    let moods: [MoodEntry]
    let settings: AppSettings
    let customTemplates: [ScheduleTemplate]
}

/// 主页区块类型
enum HomeSection: String, Codable, CaseIterable, Identifiable {
    case progress = "progress"
    case todaySchedule = "todaySchedule"
    case moodOverview = "moodOverview"
    case cycleOverview = "cycleOverview"
    case healthOverview = "healthOverview"
    case weeklyTrend = "weeklyTrend"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .progress: return "今日进度"
        case .todaySchedule: return "今日日程"
        case .moodOverview: return "心情概览"
        case .cycleOverview: return "周期追踪"
        case .healthOverview: return "健康概览"
        case .weeklyTrend: return "本周趋势"
        }
    }
    
    var icon: String {
        switch self {
        case .progress: return "chart.pie"
        case .todaySchedule: return "list.bullet"
        case .moodOverview: return "face.smiling"
        case .cycleOverview: return "drop"
        case .healthOverview: return "heart"
        case .weeklyTrend: return "chart.bar"
        }
    }
}

/// 主页布局项（顺序 + 显隐）
struct HomeSectionItem: Codable, Equatable, Identifiable {
    var id: String { section.rawValue }
    var section: HomeSection
    var isVisible: Bool
    
    static let defaultLayout: [HomeSectionItem] = [
        HomeSectionItem(section: .progress, isVisible: true),
        HomeSectionItem(section: .todaySchedule, isVisible: true),
        HomeSectionItem(section: .moodOverview, isVisible: true),
        HomeSectionItem(section: .cycleOverview, isVisible: true),
        HomeSectionItem(section: .healthOverview, isVisible: true),
        HomeSectionItem(section: .weeklyTrend, isVisible: true),
    ]
}

enum FontSize: String, Codable, CaseIterable {
    case small = "small"
    case normal = "normal"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var displayName: String {
        switch self {
        case .small: return "小"
        case .normal: return "标准"
        case .large: return "大"
        case .extraLarge: return "超大"
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .small: return 0.85
        case .normal: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        }
    }
    
    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .small: return .small
        case .normal: return .large
        case .large: return .xxLarge
        case .extraLarge: return .accessibility3
        }
    }
}
