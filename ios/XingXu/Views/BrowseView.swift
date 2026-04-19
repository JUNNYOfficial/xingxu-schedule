import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var searchText = ""
    @State private var showTemplateLibrary = false
    @State private var selectedSearchDate: String = ""
    @State private var showDayTasks = false
    
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
                            .submitLabel(.search)
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }) {
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
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "未找到匹配的任务",
                                subtitle: "试试其他关键词"
                            )
                        } else {
                            ForEach(filteredTasks) { task in
                                Button(action: {
                                    selectedSearchDate = task.date
                                    showDayTasks = true
                                }) {
                                    HStack {
                                        Text(task.icon)
                                        Text(task.name)
                                        Spacer()
                                        Text(task.date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.secondary.opacity(0.5))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                } else {
                    // 核心类别
                    Section("核心类别") {
                        NavigationLink(destination: CalendarView()) {
                            BrowseRow(
                                icon: "calendar",
                                title: "日程与日历",
                                subtitle: "查看日历和所有日期的任务"
                            )
                        }
                        
                        NavigationLink(destination: MoodHistoryView()) {
                            BrowseRow(
                                icon: "heart.fill",
                                title: "心情与健康",
                                subtitle: "心情记录和历史趋势"
                            )
                        }
                        
                        NavigationLink(destination: AnalyticsView()) {
                            BrowseRow(
                                icon: "chart.bar.fill",
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
                                title: "模板库",
                                subtitle: "一键套用预设日程"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: SettingsView()) {
                            BrowseRow(
                                icon: "gear",
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
            .sheet(isPresented: $showDayTasks) {
                DayTasksSheet(date: selectedSearchDate)
            }
        }
    }
}

// MARK: - Browse Row

struct BrowseRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    private let tint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.1))
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)，\(subtitle)")
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    let stats: DailyStats
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickStatCard(value: "\(stats.totalTasks)", label: "近30天任务")
            QuickStatCard(value: "\(Int(stats.completionRate))%", label: "完成率")
            QuickStatCard(value: "\(stats.completedTasks)", label: "已完成")
            QuickStatCard(value: "\(stats.moods.count)", label: "心情记录")
        }
    }
}

// MARK: - Day Tasks Sheet

struct DayTasksSheet: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    let date: String
    
    private var dayTasks: [TaskItem] {
        dataManager.tasksForDate(date)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d = formatter.date(from: date) else { return date }
        formatter.dateFormat = "M月d日"
        return formatter.string(from: d)
    }
    
    var body: some View {
        NavigationView {
            List {
                if dayTasks.isEmpty {
                    Section {
                        EmptyStateView(
                            icon: "calendar",
                            title: "\(formattedDate) 暂无任务"
                        )
                    }
                } else {
                    Section("\(formattedDate) 共 \(dayTasks.count) 个任务") {
                        ForEach(dayTasks) { task in
                            HStack(spacing: 12) {
                                Text(task.icon)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.name)
                                        .font(.body)
                                        .strikethrough(task.completed)
                                        .foregroundColor(task.completed ? .secondary : .primary)
                                    Text(task.displayTime)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if task.completed {
                                    Image(systemName: "checkmark")
                                        .font(.caption2)
                                        .foregroundColor(Color(red: 0.48, green: 0.61, blue: 0.75))
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct QuickStatCard: View {
    let value: String
    let label: String
    
    private let tint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(tint)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .accessibilityLabel("\(label) \(value)")
    }
}
