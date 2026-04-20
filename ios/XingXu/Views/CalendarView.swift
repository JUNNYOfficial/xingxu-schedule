import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedDate = Date()
    @State private var showAddTask = false
    @State private var editingTask: TaskItem? = nil
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    private var tasksForSelectedDate: [TaskItem] {
        dataManager.tasksForDate(selectedDateString)
    }
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var cyclePrediction: CyclePrediction {
        CyclePredictor.predict(records: dataManager.menstrualRecords)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 月份导航
                    monthHeader
                    
                    // 日历网格
                    calendarGrid
                    
                    // 选中日期任务
                    dayTasksSection
                }
                .padding()
            }
            .navigationTitle("日历")
            .sheet(isPresented: $showAddTask) {
                AddTaskView(date: selectedDateString)
            }
            .sheet(item: $editingTask) { task in
                AddTaskView(task: task)
            }
        }
    }
    
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            .accessibilityLabel("上一个月")
            
            Spacer()
            
            Text(monthYearString)
                .font(.title3.bold())
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
            .accessibilityLabel("下一个月")
        }
        .padding(.horizontal)
    }
    
    private var calendarGrid: some View {
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)!.count
        let firstDay = firstDayOfMonth()
        let weekdayOfFirst = calendar.component(.weekday, from: firstDay)
        let offset = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        
        // 根据用户设置动态排序星期标题
        let allWeekdays = ["日", "一", "二", "三", "四", "五", "六"]
        let weekdays: [String] = (0..<7).map { index in
            let dayIndex = (calendar.firstWeekday - 1 + index) % 7
            return allWeekdays[dayIndex]
        }
        
        return VStack(spacing: 8) {
            // 星期标题
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            
            // 日期网格：合并为一个 ForEach 避免 id 冲突
            let totalCells = offset + daysInMonth
            let rows = Int(ceil(Double(totalCells) / 7.0))
            let totalGridCells = rows * 7
            let dayValues: [Int?] = Array(repeating: nil, count: offset)
                + (1...daysInMonth).map { Int($0) }
                + Array(repeating: nil, count: totalGridCells - totalCells)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(dayValues.enumerated()), id: \.offset) { index, day in
                    if let day = day {
                        let dateStr = dateString(day: day)
                        let isSelected = dateStr == selectedDateString
                        let isToday = dateStr == todayString
                        let dayTasks = dataManager.tasksForDate(dateStr)
                        let hasTasks = !dayTasks.isEmpty
                        let allCompleted = hasTasks && dayTasks.allSatisfy(\.completed)
                        let cyclePhase = cyclePhaseForDate(dateStr)
                        
                        Button(action: {
                            selectedDate = dateFrom(day: day)
                        }) {
                            ZStack {
                                // 周期阶段背景
                                if let phase = cyclePhase {
                                    Circle()
                                        .fill(phase == .menstruation ? Color(hex: "#C27BA0").opacity(0.2) : Color(hex: "#D4886A").opacity(0.12))
                                        .frame(width: 38, height: 38)
                                }
                                
                                // 预测窗口边框
                                if isInPredictedWindow(dateStr) && cyclePhase != .menstruation {
                                    Circle()
                                        .stroke(Color(hex: "#D4886A").opacity(0.4), lineWidth: 1.5)
                                        .frame(width: 36, height: 36)
                                }
                                
                                Circle()
                                    .fill(isSelected ? Color.primary : Color.clear)
                                    .frame(width: 36, height: 36)
                                
                                Text("\(day)")
                                    .font(.body)
                                    .foregroundColor(isSelected ? Color(.systemBackground) : (isToday ? .primary : .primary))
                                    .fontWeight(isToday ? .bold : .regular)
                                
                                // 底部标记：任务圆点 + 周期小点
                                HStack(spacing: 3) {
                                    if hasTasks {
                                        Circle()
                                            .fill(allCompleted ? Color(red: 0.48, green: 0.61, blue: 0.75) : Color(red: 0.48, green: 0.61, blue: 0.75).opacity(0.4))
                                            .frame(width: 5, height: 5)
                                    }
                                    if cyclePhase == .menstruation {
                                        Circle()
                                            .fill(Color(hex: "#C27BA0"))
                                            .frame(width: 5, height: 5)
                                    }
                                }
                                .offset(y: 12)
                            }
                            .frame(height: 40)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("\(day)日\(hasTasks ? "，有\(dayTasks.count)个任务\(allCompleted ? "，全部完成" : "")" : "")\(isToday ? "，今天" : "")")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    } else {
                        Text("")
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var dayTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(formattedSelectedDate) 的任务")
                    .font(.headline)
                Spacer()
                Button(action: { showAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            
            if tasksForSelectedDate.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.plus",
                    title: "\(formattedSelectedDate) 暂无任务",
                    subtitle: "点击右上角 + 添加任务",
                    action: { showAddTask = true },
                    actionTitle: "添加任务"
                )
            } else {
                ForEach(tasksForSelectedDate) { task in
                    TaskRow(task: task, onToggle: {
                        dataManager.toggleComplete(id: task.id)
                    }, onEdit: {
                        editingTask = task
                    }, onDelete: {
                        dataManager.deleteTask(id: task.id)
                    })
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedDate)
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: selectedDate)
    }
    
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func firstDayOfMonth() -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
    }
    
    private func dateString(day: Int) -> String {
        var comp = calendar.dateComponents([.year, .month], from: selectedDate)
        comp.day = day
        let date = calendar.date(from: comp)!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func dateFrom(day: Int) -> Date {
        var comp = calendar.dateComponents([.year, .month], from: selectedDate)
        comp.day = day
        return calendar.date(from: comp)!
    }
    
    private func dateFromString(_ dateStr: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateStr)
    }
    
    /// 判断某日期是否在已知经期中
    private func cyclePhaseForDate(_ dateStr: String) -> CyclePhase? {
        guard let date = dateFromString(dateStr) else { return nil }
        
        // 检查是否在已知经期
        for record in dataManager.menstrualRecords {
            let endDate = record.endDate ?? Calendar.current.date(byAdding: .day, value: record.durationDays - 1, to: record.startDate)!
            if date >= record.startDate && date <= endDate {
                return .menstruation
            }
        }
        return nil
    }
    
    /// 判断某日期是否在预测窗口中
    private func isInPredictedWindow(_ dateStr: String) -> Bool {
        guard let date = dateFromString(dateStr) else { return false }
        guard let earliest = cyclePrediction.nextWindowEarliest,
              let latest = cyclePrediction.nextWindowLatest else { return false }
        return date >= earliest && date <= latest
    }
    
    private func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate)!
    }
    
    private func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate)!
    }
}
