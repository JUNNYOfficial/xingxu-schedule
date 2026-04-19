import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showAddTask = false
    @State private var showTodayDetail = false
    @State private var editingTask: TaskItem? = nil
    
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 收藏夹
                    favoritesSection
                    
                    // 今日日程
                    todayScheduleSection
                    
                    // 心情概览
                    moodOverviewSection
                    
                    // 本周趋势
                    weeklyTrendSection
                }
                .padding(.vertical)
            }
            .navigationTitle("摘要")
            .navigationBarTitleDisplayMode(.large)
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
            .background(
                NavigationLink(destination: TodayView(), isActive: $showTodayDetail) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }
    
    // MARK: - 收藏夹
    
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("收藏夹")
                .font(.title2.bold())
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    progressCard
                    moodCard
                    completionCard
                    activeDaysCard
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var progressCard: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progress >= 1.0 ? Color.mint : progress >= 0.6 ? Color(red: 0.5, green: 0.72, blue: 0.85) : Color(red: 1.0, green: 0.7, blue: 0.3),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 80, height: 80)
                
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 20, weight: .bold))
                }
            }
            
            Text("今日进度")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 160, height: 160)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var moodCard: some View {
        VStack(spacing: 8) {
            if let mood = todayMood {
                Text(mood.emoji)
                    .font(.system(size: 48))
                Text("\(mood.value)/5")
                    .font(.title3.bold())
                Text("今日心情")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "face.smiling")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("未记录")
                    .font(.title3.bold())
                Text("今日心情")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 160, height: 160)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var completionCard: some View {
        VStack(spacing: 8) {
            Text("\(Int(weeklyStats.completionRate))%")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color(red: 0.5, green: 0.72, blue: 0.85))
            
            Text("本周完成率")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(0..<7) { i in
                    let dayData = weeklyStats.dailyData[safe: i]
                    let hasData = dayData?.total ?? 0 > 0
                    let rate = hasData ? Double(dayData!.completed) / Double(dayData!.total) : 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(hasData ? (rate >= 1.0 ? Color.mint : Color(red: 0.5, green: 0.72, blue: 0.85)) : Color.gray.opacity(0.1))
                        .frame(width: 12, height: max(4, rate * 30))
                }
            }
        }
        .frame(width: 160, height: 160)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var activeDaysCard: some View {
        VStack(spacing: 8) {
            Text("\(weeklyStats.dailyData.filter { $0.total > 0 }.count)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.indigo)
            
            Text("活跃天数")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("本周")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.top, 4)
        }
        .frame(width: 160, height: 160)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 今日日程
    
    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日日程")
                    .font(.title2.bold())
                Spacer()
                Button("查看全部") {
                    showTodayDetail = true
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                if todayTasks.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checklist")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("今日暂无任务")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("添加第一个任务") {
                            showAddTask = true
                        }
                        .font(.caption)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
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
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // MARK: - 心情概览
    
    private var moodOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("心情概览")
                    .font(.title2.bold())
                Spacer()
                Button("记录") {
                    // 打开心情选择 sheet
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
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // MARK: - 本周趋势
    
    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周趋势")
                .font(.title2.bold())
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    statItem(value: "\(weeklyStats.totalTasks)", label: "总任务", color: .indigo)
                    statItem(value: "\(weeklyStats.completedTasks)", label: "已完成", color: .mint)
                }
                
                HStack(spacing: 16) {
                    statItem(value: "\(Int(weeklyStats.completionRate))%", label: "完成率", color: Color(red: 0.5, green: 0.72, blue: 0.85))
                    statItem(value: "\(weeklyStats.dailyData.filter { $0.total > 0 }.count)天", label: "活跃天数", color: Color(red: 0.6, green: 0.5, blue: 0.9))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
