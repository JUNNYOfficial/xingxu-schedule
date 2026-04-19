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
                    progressCard
                    quickAccessGrid
                    todayScheduleSection
                    moodOverviewSection
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
            // 左侧小圆环
            ZStack {
                Circle()
                    .stroke(themeColor.opacity(0.12), lineWidth: 8)
                    .frame(width: 80, height: 80)
                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(themeColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                }
                Text(progress > 0 ? "\(Int(progress * 100))%" : "--")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(progress > 0 ? themeColor : .secondary)
            }
            
            // 右侧数据列
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
            
            // 箭头
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
    }
    
    private var themeColor: Color {
        if progress >= 1.0 { return .mint }
        if progress >= 0.6 { return Color(red: 0.5, green: 0.72, blue: 0.85) }
        return Color(red: 1.0, green: 0.7, blue: 0.3)
    }
    
    // MARK: - Quick Access Grid
    
    private var quickAccessGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷入口")
                .font(.title3.bold())
                .padding(.horizontal)
            
            HStack(spacing: 0) {
                quickItem(title: "日历", icon: "calendar", color: Color(red: 1.0, green: 0.55, blue: 0.35)) {
                    showTodayDetail = true
                }
                quickItem(title: "心情", icon: "heart.fill", color: Color(red: 1.0, green: 0.5, blue: 0.6)) {
                    showMoodPicker = true
                }
                quickItem(title: "分析", icon: "chart.bar.fill", color: .mint) {}
                quickItem(title: "模板", icon: "doc.on.doc", color: Color(red: 0.4, green: 0.6, blue: 0.95)) {}
                quickItem(title: "添加", icon: "plus.circle.fill", color: Color(red: 1.0, green: 0.7, blue: 0.3)) {
                    showAddTask = true
                }
                quickItem(title: "设置", icon: "gearshape.fill", color: Color(red: 0.5, green: 0.65, blue: 0.8)) {}
            }
            .padding(.horizontal)
        }
    }
    
    private func quickItem(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(color)
                    )
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Today Schedule
    
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
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                if todayTasks.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("今日暂无日程")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.6))
                        Spacer()
                    }
                    .padding()
                } else {
                    ForEach(todayTasks.prefix(4)) { task in
                        Button(action: { editingTask = task }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(task.completed ? Color.mint : Color.gray.opacity(0.25))
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
                                        .foregroundColor(.mint)
                                }
                            }
                            .padding()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
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
                Button("记录") {
                    showMoodPicker = true
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                let recentMoods = weeklyStats.moods.suffix(7)
                if recentMoods.isEmpty {
                    Text("近7天无心情记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity, minHeight: 60)
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
    
    // MARK: - Weekly Trend
    
    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周趋势")
                .font(.title3.bold())
                .padding(.horizontal)
            
            HStack(spacing: 10) {
                miniStat(value: "\(weeklyStats.totalTasks)", label: "总任务", color: .indigo)
                miniStat(value: "\(weeklyStats.completedTasks)", label: "已完成", color: .mint)
                miniStat(value: "\(Int(weeklyStats.completionRate))%", label: "完成率", color: Color(red: 0.5, green: 0.72, blue: 0.85))
                miniStat(value: "\(weeklyStats.dailyData.filter { $0.total > 0 }.count)", label: "活跃天", color: Color(red: 0.6, green: 0.5, blue: 0.9))
            }
            .padding(.horizontal)
        }
    }
    
    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
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
