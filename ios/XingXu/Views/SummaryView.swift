import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showAddTask = false
    @State private var showMoodPicker = false
    @State private var editingTask: TaskItem? = nil
    @State private var showTodayDetail = false
    
    private var todayTasks: [TaskItem] {
        dataManager.tasksForDate(dataManager.currentDate)
    }
    
    private var completedCount: Int {
        todayTasks.filter(\.completed).count
    }
    
    private var progress: Double {
        todayTasks.isEmpty ? 0 : Double(completedCount) / Double(todayTasks.count)
    }
    
    private var todayMood: MoodEntry? {
        dataManager.moodForDate(dataManager.currentDate)
    }
    
    private var weeklyStats: DailyStats {
        dataManager.stats(forDays: 7)
    }
    
    // MARK: - 问候语
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "早上好"
        case 12..<14: return "中午好"
        case 14..<18: return "下午好"
        case 18..<22: return "晚上好"
        default: return "夜深了"
        }
    }
    
    private var todayDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE · M月d日"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 顶部问候
                    headerGreeting
                    
                    // 核心数据大卡片
                    coreDataCard
                    
                    // 六宫格快捷入口
                    quickAccessGrid
                    
                    // 今日日程
                    todayScheduleSection
                    
                    // 心情概览
                    moodOverviewSection
                    
                    // 本周趋势
                    weeklyTrendSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView(date: dataManager.currentDate)
            }
            .sheet(item: $editingTask) { task in
                AddTaskView(task: task)
            }
            .sheet(isPresented: $showMoodPicker) {
                MoodPickerView(date: dataManager.currentDate)
            }
            .background(
                NavigationLink(destination: TodayView(), isActive: $showTodayDetail) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }
    
    // MARK: - 顶部问候
    
    private var headerGreeting: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting) 👋")
                    .font(.title2.bold())
                Text(todayDateText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - 核心数据大卡片
    
    private var coreDataCard: some View {
        HStack(spacing: 20) {
            // 左侧大圆环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.12), lineWidth: 12)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progressRingColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 24, weight: .bold))
                    Text("完成")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 右侧数据列
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Text("\(completedCount)/\(todayTasks.count)")
                        .font(.title3.bold())
                    Text("任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack(spacing: 6) {
                    if let mood = todayMood {
                        Text(mood.emoji)
                            .font(.title3)
                        Text("\(mood.value)/5")
                            .font(.subheadline.bold())
                    } else {
                        Image(systemName: "face.smiling")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text("未记录")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text("心情")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { showTodayDetail = true }) {
                    HStack(spacing: 4) {
                        Text("查看日程")
                            .font(.caption.bold())
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(progressRingColor)
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 3)
        .padding(.horizontal)
    }
    
    private var progressRingColor: Color {
        if progress >= 1.0 { return .mint }
        if progress >= 0.6 { return Color(red: 0.5, green: 0.72, blue: 0.85) }
        return Color(red: 1.0, green: 0.7, blue: 0.3)
    }
    
    // MARK: - 六宫格快捷入口
    
    private var quickAccessGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷入口")
                .font(.title3.bold())
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                quickAccessItem(
                    title: "日程日历",
                    icon: "calendar",
                    color: Color(red: 1.0, green: 0.55, blue: 0.35),
                    destination: AnyView(CalendarView())
                )
                quickAccessItem(
                    title: "心情记录",
                    icon: "heart.fill",
                    color: Color(red: 1.0, green: 0.5, blue: 0.6),
                    destination: AnyView(MoodHistoryView())
                )
                quickAccessItem(
                    title: "数据分析",
                    icon: "chart.bar.fill",
                    color: .mint,
                    destination: AnyView(AnalyticsView())
                )
                quickAccessItem(
                    title: "模板库",
                    icon: "doc.text.fill",
                    color: Color(red: 0.4, green: 0.6, blue: 0.95),
                    destination: AnyView(TemplateLibraryView())
                )
                quickAccessButton(
                    title: "添加任务",
                    icon: "plus.circle.fill",
                    color: Color(red: 1.0, green: 0.7, blue: 0.3)
                ) {
                    showAddTask = true
                }
                quickAccessItem(
                    title: "设置",
                    icon: "gearshape.fill",
                    color: Color(red: 0.5, green: 0.65, blue: 0.8),
                    destination: AnyView(SettingsView())
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func quickAccessItem(title: String, icon: String, color: Color, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.15))
                    .frame(height: 60)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    )
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func quickAccessButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.15))
                    .frame(height: 60)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    )
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 今日日程
    
    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日日程")
                    .font(.title3.bold())
                Spacer()
                Button("查看全部") {
                    showTodayDetail = true
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                if todayTasks.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("今日暂无日程")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.6))
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    ForEach(todayTasks.prefix(4)) { task in
                        Button(action: {
                            editingTask = task
                        }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(task.completed ? Color.mint : Color.gray.opacity(0.3))
                                    .frame(width: 10, height: 10)
                                
                                if !task.icon.isEmpty {
                                    Text(task.icon)
                                        .font(.title3)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.name)
                                        .font(.body)
                                        .foregroundColor(task.completed ? .secondary : .primary)
                                        .strikethrough(task.completed)
                                    Text(task.displayTime)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if task.completed {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundColor(.mint)
                                }
                            }
                            .padding()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if task.id != todayTasks.prefix(4).last?.id {
                            Divider()
                                .padding(.leading)
                        }
                    }
                    
                    if todayTasks.count > 4 {
                        Button("查看剩余 \(todayTasks.count - 4) 个任务") {
                            showTodayDetail = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // MARK: - 心情概览
    
    private var moodOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("心情概览")
                    .font(.title3.bold())
                Spacer()
                Button("记录") {
                    showMoodPicker = true
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                let recentMoods = weeklyStats.moods.suffix(7)
                if recentMoods.isEmpty {
                    Text("近7天无心情记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(recentMoods) { mood in
                            VStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.title3)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: mood.color).opacity(0.3))
                                    .frame(width: 28, height: CGFloat(mood.value) * 12)
                                Text(shortDate(mood.date))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // MARK: - 本周趋势
    
    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周趋势")
                .font(.title3.bold())
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    statItem(value: "\(weeklyStats.totalTasks)", label: "总任务", color: .indigo)
                    statItem(value: "\(weeklyStats.completedTasks)", label: "已完成", color: .mint)
                }
                
                HStack(spacing: 12) {
                    statItem(value: "\(Int(weeklyStats.completionRate))%", label: "完成率", color: Color(red: 0.5, green: 0.72, blue: 0.85))
                    statItem(value: "\(weeklyStats.dailyData.filter { $0.total > 0 }.count)天", label: "活跃天数", color: Color(red: 0.6, green: 0.5, blue: 0.9))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helpers
    
    private func shortDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return "" }
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}


