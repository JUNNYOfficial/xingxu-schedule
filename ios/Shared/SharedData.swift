import Foundation

/// 小组件任务模型
struct WidgetTask: Codable, Identifiable {
    let id: String
    let name: String
    let time: String
    let completed: Bool
    let tag: String?
    let icon: String?
}

/// 小组件数据模型
struct WidgetScheduleData: Codable {
    let date: String
    let tasks: [WidgetTask]
    let totalTasks: Int
    let completedTasks: Int
    var updatedAt: Date
}

/// 通过 App Group 共享数据给小组件
class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let suiteName = "group.com.xingxu.schedule"
    private let dataKey = "widgetScheduleData"
    private let defaults: UserDefaults?
    
    private init() {
        defaults = UserDefaults(suiteName: suiteName)
    }
    
    /// 保存日程数据
    func saveScheduleData(_ data: WidgetScheduleData) {
        guard let defaults = defaults else { return }
        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: dataKey)
            defaults.set(Date().timeIntervalSince1970, forKey: "widgetLastUpdate")
        } catch {
            print("[SharedData] 保存失败: \(error)")
        }
    }
    
    /// 读取日程数据
    func loadScheduleData() -> WidgetScheduleData? {
        guard let defaults = defaults else { return nil }
        guard let data = defaults.data(forKey: dataKey) else { return nil }
        do {
            return try JSONDecoder().decode(WidgetScheduleData.self, from: data)
        } catch {
            print("[SharedData] 读取失败: \(error)")
            return nil
        }
    }
    
    /// 获取最后更新时间
    var lastUpdateTime: Date? {
        guard let defaults = defaults else { return nil }
        let timestamp = defaults.double(forKey: "widgetLastUpdate")
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
}
