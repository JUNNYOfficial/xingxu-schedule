import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showAddTask = false
    @State private var showMoodPicker = false
    @State private var editingTask: TaskItem? = nil
    @State private var showTodayDetail = false
    @State private var showAnalytics = false
    @State private var showTemplateLibrary = false
    @State private var showSettings = false
    @State private var showCycleTracking = false
    @State private var showLayoutEditor = false
    @StateObject private var healthManager = HealthManager.shared
    
    // 自闭症友好：统一柔和色系
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    private let softBackground = Color(red: 0.48, green: 0.61, blue: 0.75).opacity(0.08)
    
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
    
    @ViewBuilder
    private func sectionView(for section: HomeSection) -> some View {
        switch section {
        case .progress:
            progressCard
        case .todaySchedule:
            todayScheduleSection
        case .moodOverview:
            moodOverviewSection
        case .cycleOverview:
            cycleOverviewSection
        case .healthOverview:
            healthOverviewSection
        case .weeklyTrend:
            weeklyTrendSection
        }
    }
    
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
                VStack(spacing: 16) {
                    headerGreeting
                    
                    let visibleSections = dataManager.settings.homeLayout.filter { $0.isVisible }
                    ForEach(visibleSections) { item in
                        sectionView(for: item.section)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(primaryTint)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showTodayDetail = true }) {
                            Label("今日日程", systemImage: "calendar")
                        }
                        Button(action: { showMoodPicker = true }) {
                            Label("记录心情", systemImage: "heart")
                        }
                        Button(action: { showCycleTracking = true }) {
                            Label("周期追踪", systemImage: "drop")
                        }
                        Button(action: { showAnalytics = true }) {
                            Label("数据分析", systemImage: "chart.bar")
                        }
                        Button(action: { showTemplateLibrary = true }) {
                            Label("日程模板", systemImage: "doc.on.doc")
                        }
                        Divider()
                        Button(action: { showLayoutEditor = true }) {
                            Label("主页布局", systemImage: "rectangle.3.group")
                        }
                        Button(action: { showSettings = true }) {
                            Label("设置", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(primaryTint)
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
            .sheet(isPresented: $showAnalytics) {
                AnalyticsView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showTemplateLibrary) {
                TemplateLibraryView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showCycleTracking) {
                CycleTrackingView()
                    .environmentObject(dataManager)
            }
            .sheet(isPresented: $showLayoutEditor) {
                HomeLayoutEditorView()
                    .environmentObject(dataManager)
            }
            .navigationDestination(isPresented: $showTodayDetail) {
                TodayView()
            }
            .onAppear {
                Task {
                    await healthManager.refreshAllData()
                }
            }
        }
    }
    
    // MARK: - Header
    
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
    
    // MARK: - Progress Card
    
    private var progressCard: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(primaryTint.opacity(0.12), lineWidth: 8)
                    .frame(width: 80, height: 80)
                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(primaryTint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                }
                Text(progress > 0 ? "\(Int(progress * 100))%" : "--")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(progress > 0 ? primaryTint : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("今日进度")
                    .font(.headline)
                Text("\(completedCount)/\(todayTasks.count) 任务")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let mood = todayMood {
                    Text("\(mood.emoji) 心情 \(mood.value)/5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("😊 心情未记录")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.4))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 3)
        .padding(.horizontal)
        .onTapGesture {
            showTodayDetail = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日进度，\(completedCount)个任务已完成，共\(todayTasks.count)个任务，\(todayMood != nil ? "心情\(todayMood!.value)分" : "心情未记录")")
        .accessibilityHint("双击查看今日日程详情")
    }
    
    // MARK: - Quick Access Grid
    
    // MARK: - Today Schedule
    
    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日日程")
                    .font(.title3.bold())
                Spacer()
                Button("查看全部") { showTodayDetail = true }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("查看全部日程")
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                if todayTasks.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "今日暂无日程",
                        subtitle: "点击右上角 + 添加第一个任务",
                        action: { showAddTask = true },
                        actionTitle: "添加任务"
                    )
                    .padding()
                } else {
                    ForEach(todayTasks.prefix(4)) { task in
                        Button(action: { editingTask = task }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(task.completed ? primaryTint : Color.gray.opacity(0.25))
                                    .frame(width: 8, height: 8)
                                
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
                                        .font(.caption2)
                                        .foregroundColor(primaryTint)
                                }
                            }
                            .padding()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("\(task.completed ? "已完成" : "未完成")任务：\(task.name)，时间 \(task.displayTime)")
                        
                        if task.id != todayTasks.prefix(4).last?.id {
                            Divider()
                                .padding(.leading, 44)
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
    
    // MARK: - Mood Overview
    
    private var moodOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("心情概览")
                    .font(.title3.bold())
                Spacer()
                Button("记录") { showMoodPicker = true }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("记录今日心情")
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                let recentMoods = weeklyStats.moods.suffix(7)
                if recentMoods.isEmpty {
                    EmptyStateView(
                        icon: "face.smiling",
                        title: "近7天无心情记录",
                        subtitle: "记录心情有助于了解自己的情绪变化",
                        action: { showMoodPicker = true },
                        actionTitle: "记录心情"
                    )
                } else {
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(recentMoods) { mood in
                            VStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.title3)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: mood.color).opacity(0.35))
                                    .frame(width: 24, height: CGFloat(mood.value) * 10)
                                Text(shortDate(mood.date))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Cycle Overview
    
    private var cycleOverviewSection: some View {
        let prediction = CyclePredictor.predict(records: dataManager.menstrualRecords)
        let hasData = !dataManager.menstrualRecords.isEmpty
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("周期追踪")
                    .font(.title3.bold())
                Spacer()
                if hasData {
                    Button("详情") { showCycleTracking = true }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            if !hasData {
                EmptyStateView(
                    icon: "drop.fill",
                    title: "开始追踪周期",
                    subtitle: "了解自己的身体规律，提前做好准备",
                    action: { showCycleTracking = true },
                    actionTitle: "添加记录"
                )
                .padding(.horizontal)
            } else {
                HStack(spacing: 12) {
                    // 预测卡片
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title3)
                                .foregroundColor(prediction.isPremenstrualAlert ? Color(hex: "#D4886A") : primaryTint)
                            Spacer()
                        }
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            if let earliest = prediction.nextWindowEarliest, let _ = prediction.nextWindowLatest {
                                let daysUntil = daysBetween(Date(), earliest)
                                if daysUntil <= 0 {
                                    Text("快了")
                                        .font(.headline)
                                } else {
                                    Text("\(daysUntil)")
                                        .font(.system(size: 28, weight: .bold))
                                    Text("天")
                                        .font(.subheadline)
                                }
                            } else {
                                Text("--")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(prediction.daysUntilDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    
                    // 阶段卡片
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color(hex: prediction.currentPhase.color))
                                .frame(width: 10, height: 10)
                            Spacer()
                        }
                        Text(prediction.currentPhase.rawValue)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(prediction.currentPhase.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Health Overview
    
    private var healthOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("健康概览")
                    .font(.title3.bold())
                Spacer()
                if !healthManager.isAvailable {
                    Text("不支持")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                healthCard(
                    icon: "figure.walk",
                    title: "运动",
                    value: healthManager.todayExerciseMinutes > 0
                        ? "\(Int(healthManager.todayExerciseMinutes))分钟"
                        : "--",
                    color: primaryTint
                )
                healthCard(
                    icon: "brain.head.profile",
                    title: "正念",
                    value: healthManager.todayMindfulMinutes > 0
                        ? "\(Int(healthManager.todayMindfulMinutes))分钟"
                        : "--",
                    color: primaryTint
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func healthCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Weekly Trend
    
    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周趋势")
                .font(.title3.bold())
                .padding(.horizontal)
            
            HStack(spacing: 10) {
                miniStat(value: "\(weeklyStats.totalTasks)", label: "总任务")
                miniStat(value: "\(weeklyStats.completedTasks)", label: "已完成")
                miniStat(value: "\(Int(weeklyStats.completionRate))%", label: "完成率")
                miniStat(value: "\(weeklyStats.dailyData.filter { $0.total > 0 }.count)", label: "活跃天")
            }
            .padding(.horizontal)
        }
    }
    
    private func miniStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(primaryTint)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .accessibilityLabel("\(label) \(value)")
    }
    
    // MARK: - Helpers
    
    private func shortDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return "" }
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    private func daysBetween(_ from: Date, _ to: Date) -> Int {
        Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
    }
}
