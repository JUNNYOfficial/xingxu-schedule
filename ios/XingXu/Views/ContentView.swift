import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
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
        .tint(dataManager.settings.theme.tintColor)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
            UITabBar.appearance().standardAppearance = appearance
        }
    }
}
