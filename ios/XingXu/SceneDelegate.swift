import UIKit
import SwiftUI
import WidgetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let contentView = ContentView()
            .environmentObject(DataManager.shared)
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        DataManager.shared.syncToWidget()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        DataManager.shared.syncToWidget()
    }
}

// MARK: - DataManager Widget Extension

extension DataManager {
    func syncToWidget() {
        let dayTasks = tasksForDate(currentDate)
        let widgetData = WidgetScheduleData(
            date: currentDate,
            tasks: dayTasks.map {
                WidgetTask(
                    id: $0.id,
                    name: $0.name,
                    time: $0.time,
                    completed: $0.completed,
                    tag: $0.tag,
                    icon: $0.icon
                )
            },
            totalTasks: dayTasks.count,
            completedTasks: dayTasks.filter(\.completed).count,
            updatedAt: Date()
        )
        SharedDataManager.shared.saveScheduleData(widgetData)
        WidgetCenter.shared.reloadTimelines(ofKind: "XingXuWidget")
    }
}
