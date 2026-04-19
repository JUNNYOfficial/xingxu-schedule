import Foundation

/// iCloud 同步数据包
struct SyncData: Codable {
    let tasks: [TaskItem]
    let moods: [MoodEntry]
    let settings: AppSettings
    let templates: [ScheduleTemplate]
    let syncTimestamp: Date
}

/// iCloud 键值存储同步管理器
@MainActor
class iCloudSyncManager: ObservableObject {
    static let shared = iCloudSyncManager()
    
    private let store = NSUbiquitousKeyValueStore.default
    private let syncKey = "xingxu_sync_data_v2"
    private let syncEnabledKey = "xingxu_icloud_sync_enabled"
    
    /// 是否开启 iCloud 同步
    @Published var isSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSyncEnabled, forKey: syncEnabledKey)
            if isSyncEnabled {
                syncToCloud()
            }
        }
    }
    
    /// iCloud 是否可用（用户已登录）
    var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
    
    /// 上次同步时间
    var lastSyncTime: Date? {
        get { UserDefaults.standard.object(forKey: "xingxu_last_sync") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "xingxu_last_sync") }
    }
    
    private init() {
        isSyncEnabled = UserDefaults.standard.bool(forKey: syncEnabledKey)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
        store.synchronize()
    }
    
    // MARK: - 上传到 iCloud
    
    func syncToCloud() {
        guard isSyncEnabled, isAvailable else { return }
        
        let data = SyncData(
            tasks: DataManager.shared.tasks,
            moods: DataManager.shared.moods,
            settings: DataManager.shared.settings,
            templates: DataManager.shared.customTemplates,
            syncTimestamp: Date()
        )
        
        guard let encoded = try? JSONEncoder().encode(data) else {
            print("[iCloud] 编码失败")
            return
        }
        
        store.set(encoded, forKey: syncKey)
        let success = store.synchronize()
        lastSyncTime = Date()
        print("[iCloud] 上传同步 \(success ? "成功" : "待处理")")
    }
    
    // MARK: - 从 iCloud 下载并合并
    
    func syncFromCloud() {
        guard isSyncEnabled, isAvailable else { return }
        
        store.synchronize()
        
        guard let data = store.data(forKey: syncKey),
              let decoded = try? JSONDecoder().decode(SyncData.self, from: data) else {
            return
        }
        
        let dm = DataManager.shared
        
        // 合并任务（按 modifiedAt 取较新）
        dm.tasks = mergeItems(local: dm.tasks, cloud: decoded.tasks)
        dm.saveTasks()
        
        // 合并心情记录
        dm.moods = mergeItems(local: dm.moods, cloud: decoded.moods)
        dm.saveMoods()
        
        // 合并自定义模板
        dm.customTemplates = mergeItems(local: dm.customTemplates, cloud: decoded.templates)
        dm.saveCustomTemplates()
        
        // 设置：取云端的（设置通常整包替换）
        if decoded.syncTimestamp > (lastSyncTime ?? .distantPast) {
            dm.settings = decoded.settings
            dm.saveSettings()
        }
        
        lastSyncTime = Date()
        print("[iCloud] 下载合并完成")
    }
    
    // MARK: - 合并逻辑
    
    private func mergeItems<T: Identifiable & Equatable>(
        local: [T],
        cloud: [T]
    ) -> [T] where T: HasModifiedAt {
        var result: [T] = []
        let localDict = Dictionary(grouping: local, by: { $0.id })
        let cloudDict = Dictionary(grouping: cloud, by: { $0.id })
        
        let allIds = Set(localDict.keys).union(cloudDict.keys)
        
        for id in allIds {
            let localItem = localDict[id]?.first
            let cloudItem = cloudDict[id]?.first
            
            if let local = localItem, let cloud = cloudItem {
                // 两者都有，取 modifiedAt 较新的
                result.append(local.modifiedAt >= cloud.modifiedAt ? local : cloud)
            } else if let local = localItem {
                result.append(local)
            } else if let cloud = cloudItem {
                result.append(cloud)
            }
        }
        
        return result
    }
    
    // MARK: - 外部变更监听
    
    @objc private func handleExternalChange(_ notification: Notification) {
        guard isSyncEnabled else { return }
        
        if let userInfo = notification.userInfo,
           let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int {
            switch reason {
            case NSUbiquitousKeyValueStoreServerChange:
                print("[iCloud] 检测到云端变更，开始合并")
                syncFromCloud()
            case NSUbiquitousKeyValueStoreInitialSyncChange:
                print("[iCloud] 首次同步，合并云端数据")
                syncFromCloud()
            default:
                break
            }
        }
    }
}

// MARK: - 协议：支持 modifiedAt 的模型

protocol HasModifiedAt {
    var id: String { get }
    var modifiedAt: Date { get }
}

extension TaskItem: HasModifiedAt {}
extension MoodEntry: HasModifiedAt {}
extension ScheduleTemplate: HasModifiedAt {}
