import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        guard url.scheme == "xingxu", url.host == "toggleTask" else { return false }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let id = components?.queryItems?.first(where: { $0.name == "id" })?.value {
            Task { @MainActor in
                DataManager.shared.toggleComplete(id: id)
            }
        }
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        // 全屏闹钟：App 在前台时也显示全屏提醒
        if userInfo["fullscreenAlarm"] as? Bool == true,
           let taskId = userInfo["taskId"] as? String {
            Task { @MainActor in
                if let task = DataManager.shared.tasks.first(where: { $0.id == taskId }) {
                    DataManager.shared.activeAlarmTask = task
                }
            }
        }
        
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // 用户点击通知时，如果是全屏闹钟任务，弹出全屏闹钟
        if userInfo["fullscreenAlarm"] as? Bool == true,
           let taskId = userInfo["taskId"] as? String {
            Task { @MainActor in
                if let task = DataManager.shared.tasks.first(where: { $0.id == taskId }) {
                    DataManager.shared.activeAlarmTask = task
                }
            }
        } else if let taskId = userInfo["taskId"] as? String {
            // 普通通知点击：标记为已完成
            Task { @MainActor in
                DataManager.shared.toggleComplete(id: taskId)
            }
        }
        
        completionHandler()
    }
}
