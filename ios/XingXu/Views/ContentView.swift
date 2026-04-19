import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedTab = 0
    @State private var showAddTask = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "checklist")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Label("日历", systemImage: "calendar")
                }
                .tag(1)
            
            AnalyticsView()
                .tabItem {
                    Label("分析", systemImage: "chart.bar")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(3)
        }
        .environmentObject(dataManager)
        .accentColor(.primary)
        .onAppear {
            // iOS 15+ tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
            UITabBar.appearance().standardAppearance = appearance
        }
    }
}
