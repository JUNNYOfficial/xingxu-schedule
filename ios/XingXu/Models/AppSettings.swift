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
        cycleReminderEnabled: Bool = false
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
