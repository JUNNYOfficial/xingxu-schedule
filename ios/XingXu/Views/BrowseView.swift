import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var showTemplateLibrary = false
    
    private var filteredTasks: [TaskItem] {
        if searchText.isEmpty { return [] }
        return dataManager.tasks.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // 搜索栏
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索任务", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                
                // 搜索结果
                if !searchText.isEmpty {
                    Section("搜索结果") {
                        if filteredTasks.isEmpty {
                            Text("未找到匹配的任务")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(filteredTasks) { task in
                                HStack {
                                    Text(task.icon)
                                    Text(task.name)
                                    Spacer()
                                    Text(task.date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    // 核心类别
                    Section("核心类别") {
                        NavigationLink(destination: CalendarView()) {
                            BrowseRow(
                                icon: "calendar",
                                iconColor: .white,
                                bgColor: Color(red: 1.0, green: 0.55, blue: 0.35),
                                title: "日程与日历",
                                subtitle: "查看日历和所有日期的任务"
                            )
                        }
                        
                        NavigationLink(destination: MoodHistoryView()) {
                            BrowseRow(
                                icon: "heart.fill",
                                iconColor: .white,
                                bgColor: Color(red: 1.0, green: 0.4, blue: 0.55),
                                title: "心情与健康",
                                subtitle: "心情记录和历史趋势"
                            )
                        }
                        
                        NavigationLink(destination: AnalyticsView()) {
                            BrowseRow(
                                icon: "chart.bar.fill",
                                iconColor: .white,
                                bgColor: Color(red: 0.35, green: 0.75, blue: 0.55),
                                title: "数据分析",
                                subtitle: "完成率趋势和智能建议"
                            )
                        }
                    }
                    
                    // 工具
                    Section("工具") {
                        Button(action: { showTemplateLibrary = true }) {
                            BrowseRow(
                                icon: "square.grid.2x2",
                                iconColor: .white,
                                bgColor: Color(red: 0.4, green: 0.6, blue: 0.9),
                                title: "模板库",
                                subtitle: "一键套用预设日程"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: SettingsView()) {
                            BrowseRow(
                                icon: "gear",
                                iconColor: .white,
                                bgColor: Color(red: 0.5, green: 0.5, blue: 0.55),
                                title: "设置",
                                subtitle: "主题、字体、通知和数据管理"
                            )
                        }
                    }
                    
                    // 快速统计
                    Section("快速统计") {
                        let stats = dataManager.stats(forDays: 30)
                        QuickStatsGrid(stats: stats)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("浏览")
            .sheet(isPresented: $showTemplateLibrary) {
                TemplateLibraryView()
            }
        }
    }
}

// MARK: - Browse Row

struct BrowseRow: View {
    let icon: String
    let iconColor: Color
    let bgColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(bgColor)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    let stats: DailyStats
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickStatCard(
                value: "\(stats.totalTasks)",
                label: "近30天任务",
                color: .indigo
            )
            QuickStatCard(
                value: "\(Int(stats.completionRate))%",
                label: "完成率",
                color: Color(red: 0.5, green: 0.72, blue: 0.85)
            )
            QuickStatCard(
                value: "\(stats.completedTasks)",
                label: "已完成",
                color: .mint
            )
            QuickStatCard(
                value: "\(stats.moods.count)",
                label: "心情记录",
                color: Color(red: 1.0, green: 0.4, blue: 0.55)
            )
        }
    }
}

struct QuickStatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
