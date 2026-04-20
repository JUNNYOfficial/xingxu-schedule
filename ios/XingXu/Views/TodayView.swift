import SwiftUI

struct TodayView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showAddTask = false
    @State private var editingTask: TaskItem? = nil
    @State private var showMoodPicker = false
    @State private var showTemplateLibrary = false
    @State private var showNotificationAlert = false
    @State private var animateCompleteId: String? = nil
    @State private var showTimeline = true
    
    private var todayTasks: [TaskItem] {
        dataManager.tasksForDate(dataManager.currentDate)
    }
    
    private var completedCount: Int {
        todayTasks.filter(\.completed).count
    }
    
    private var progress: Double {
        todayTasks.isEmpty ? 0 : Double(completedCount) / Double(todayTasks.count)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 16) {
                    // 日期头部
                    dateHeader
                    
                    // 进度环
                    if !todayTasks.isEmpty {
                        progressSection
                    }
                    
                    // 心情记录
                    moodSection
                    
                    // 快速添加
                    quickAddButton
                    
                    // 时间线视图
                    if showTimeline && !todayTasks.isEmpty {
                        timelineSection
                    }
                    
                    // 任务列表
                    taskListSection
                }
                .padding()
            }
            
            // 回到今天浮动按钮
            if !isToday {
                Button(action: backToToday) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.caption)
                        Text("今天")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.48, green: 0.61, blue: 0.75))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("今日日程")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
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
        .sheet(isPresented: $showTemplateLibrary) {
            TemplateLibraryView()
        }
        .alert("开启通知提醒", isPresented: $showNotificationAlert) {
            Button("以后再说", role: .cancel) {}
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("开启通知后，星序可以在任务开始前提醒你，帮助更好地管理日程。")
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "xingxu_notification_denied") {
                showNotificationAlert = true
                    UserDefaults.standard.set(false, forKey: "xingxu_notification_denied")
                }
            }
    }
    
    // MARK: - Subviews
    
    private var dateHeader: some View {
        HStack {
            Button(action: previousDate) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("前一天")
            
            VStack(alignment: .center, spacing: 4) {
                Text(formattedDate(dataManager.currentDate))
                    .font(.title2.bold())
                Text(weekday(dataManager.currentDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("当前日期 \(formattedDate(dataManager.currentDate)) \(weekday(dataManager.currentDate))")
            
            Button(action: nextDate) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("后一天")
        }
    }
    
    private var progressSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        completionColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                VStack(spacing: 2) {
                    Text("\(completedCount)/\(todayTasks.count)")
                        .font(.title3.bold())
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100, height: 100)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("今日进度")
                    .font(.headline)
                if completedCount == todayTasks.count && !todayTasks.isEmpty {
                    Label("全部完成！", systemImage: "checkmark.seal.fill")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.48, green: 0.61, blue: 0.75))
                } else {
                    Text("还剩 \(todayTasks.count - completedCount) 个任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var moodSection: some View {
        Button(action: { showMoodPicker = true }) {
            HStack {
                if let mood = dataManager.moodForDate(dataManager.currentDate) {
                    Text(mood.emoji)
                        .font(.title2)
                    Text("今日心情: \(mood.value)/5")
                        .font(.subheadline)
                } else {
                    Image(systemName: "face.smiling")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("记录今日心情")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var quickAddButton: some View {
        HStack(spacing: 12) {
            Button(action: { showAddTask = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("添加任务")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(Color.primary.opacity(0.1))
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("添加新任务")
            .accessibilityHint("双击打开添加任务页面")
            
            Button(action: { showTemplateLibrary = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "square.grid.2x2")
                        .font(.title2)
                    Text("模板")
                        .font(.caption)
                }
                .frame(width: 80)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("日程模板库")
            .accessibilityHint("双击打开模板库，一键套用预设日程")
        }
    }
    
    private var taskListSection: some View {
        VStack(spacing: 12) {
            if todayTasks.isEmpty {
                EmptyStateView(
                    icon: "checklist",
                    title: "今日暂无任务",
                    subtitle: "添加任务来规划你的一天",
                    action: { showAddTask = true },
                    actionTitle: "添加任务"
                )
                .padding()
            } else {
                ForEach(todayTasks) { task in
                    TaskRow(task: task, onToggle: {
                        dataManager.toggleComplete(id: task.id)
                    }, onEdit: {
                        editingTask = task
                    }, onDelete: {
                        dataManager.deleteTask(id: task.id)
                    })
                }
                .onMove { indices, offset in
                    dataManager.moveTask(for: dataManager.currentDate, from: indices, to: offset)
                }
            }
        }
    }
    
    // MARK: - Timeline
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日时间线")
                    .font(.headline)
                Spacer()
                Button(action: { showTimeline = false }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                timelineContent
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var timelineContent: some View {
        let startHour = 7
        let endHour = 22
        let totalMinutes = (endHour - startHour) * 60
        let minuteWidth: CGFloat = 3.5
        let totalWidth = CGFloat(totalMinutes) * minuteWidth
        let hourHeight: CGFloat = 44
        
        return ZStack(alignment: .topLeading) {
            // 时间刻度背景
            HStack(spacing: 0) {
                ForEach(startHour..<endHour, id: \.self) { hour in
                    VStack(spacing: 2) {
                        Text("\(hour):00")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Rectangle()
                            .fill(Color.gray.opacity(0.08))
                            .frame(width: CGFloat(60) * minuteWidth, height: hourHeight)
                    }
                    .frame(width: CGFloat(60) * minuteWidth)
                }
            }
            .frame(width: totalWidth)
            
            // 任务条
            ForEach(todayTasks) { task in
                timelineTaskBar(task: task, startHour: startHour, minuteWidth: minuteWidth, barHeight: hourHeight)
            }
        }
        .frame(width: totalWidth, height: hourHeight + 20)
    }
    
    private func timelineTaskBar(task: TaskItem, startHour: Int, minuteWidth: CGFloat, barHeight: CGFloat) -> some View {
        let taskStart = timeValue(task.time)
        let startMinutes = startHour * 60
        let offset = CGFloat(taskStart - startMinutes) * minuteWidth
        let duration = task.durationMinutes ?? (task.endTime.map { timeValue($0) - taskStart } ?? 30)
        let width = max(CGFloat(duration) * minuteWidth, 40)
        let tagColor = Color(hex: task.tagColor)
        
        return VStack(alignment: .leading, spacing: 2) {
            Text(task.name)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .foregroundColor(.primary)
            if let duration = task.durationMinutes {
                Text("\(duration)分钟")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(width: width, height: barHeight - 4, alignment: .leading)
        .background(tagColor.opacity(task.completed ? 0.15 : 0.3))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(tagColor.opacity(task.completed ? 0.1 : 0.5), lineWidth: 1)
        )
        .offset(x: offset, y: 16)
    }
    
    private func timeValue(_ timeStr: String) -> Int {
        let parts = timeStr.split(separator: ":")
        let h = Int(parts.first ?? "0") ?? 0
        let m = Int(parts.last ?? "0") ?? 0
        return h * 60 + m
    }
    
    // MARK: - Helpers
    
    private var completionColor: Color {
        let tint = Color(red: 0.48, green: 0.61, blue: 0.75)
        if progress >= 1.0 { return tint }
        if progress >= 0.6 { return tint.opacity(0.7) }
        return tint.opacity(0.4)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    
    private func weekday(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return "" }
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekdayStr = weekdays[Calendar.current.component(.weekday, from: date) - 1]
        
        let todayStr = formatter.string(from: Date())
        if dateString == todayStr {
            return "今天 · \(weekdayStr)"
        }
        return weekdayStr
    }
    
    private func previousDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dataManager.currentDate) else { return }
        let newDate = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        dataManager.currentDate = formatter.string(from: newDate)
    }
    
    private func nextDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dataManager.currentDate) else { return }
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        dataManager.currentDate = formatter.string(from: newDate)
    }
    
    private var isToday: Bool {
        dataManager.currentDate == {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: Date())
        }()
    }
    
    private func backToToday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        dataManager.currentDate = formatter.string(from: Date())
    }
}
