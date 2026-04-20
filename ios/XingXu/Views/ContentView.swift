import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedTab = 0
    @AppStorage("xingxu_has_seen_onboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else {
                mainContent
            }
        }
    }
    
    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            SummaryView()
                .tabItem {
                    Label("摘要", systemImage: "heart.text.square.fill")
                }
                .tag(0)
            
            BrowseView()
                .tabItem {
                    Label("浏览", systemImage: "square.grid.2x2")
                }
                .tag(1)
        }
        .environmentObject(dataManager)
        .dynamicTypeSize(dataManager.settings.fontSize.dynamicTypeSize)
        .preferredColorScheme(dataManager.settings.theme.colorScheme)
        .tint(Color(red: 0.48, green: 0.61, blue: 0.75))
        .overlay(
            Group {
                if let alarmTask = dataManager.activeAlarmTask {
                    AlarmView(task: alarmTask)
                        .environmentObject(dataManager)
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
        )
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
            UITabBar.appearance().standardAppearance = appearance
            
            // 统一 Tab Bar 选中色为自闭症友好蓝灰
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.selected.iconColor = UIColor(Color(red: 0.48, green: 0.61, blue: 0.75))
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color(red: 0.48, green: 0.61, blue: 0.75))]
            itemAppearance.normal.iconColor = UIColor.systemGray
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
