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
            
            Spacer()
            
            Text(monthYearString)
                .font(.title3.bold())
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }
    
    private var calendarGrid: some View {
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)!.count
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth()) - 1
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        
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
            
            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // 空白填充
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Text("")
                        .frame(height: 40)
                }
                
                ForEach(1...daysInMonth, id: \.self) { day in
                    let dateStr = dateString(day: day)
                    let isSelected = dateStr == selectedDateString
                    let isToday = dateStr == todayString
                    let dayTasks = dataManager.tasksForDate(dateStr)
                    let hasTasks = !dayTasks.isEmpty
                    let allCompleted = hasTasks && dayTasks.allSatisfy(\.completed)
                    
                    Button(action: {
                        selectedDate = dateFrom(day: day)
                    }) {
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color.primary : Color.clear)
                                .frame(width: 36, height: 36)
                            
                            Text("\(day)")
                                .font(.body)
                                .foregroundColor(isSelected ? Color(.systemBackground) : (isToday ? .primary : .primary))
                                .fontWeight(isToday ? .bold : .regular)
                            
                            if hasTasks {
                                Circle()
                                    .fill(allCompleted ? Color.green : Color.orange)
                                    .frame(width: 6, height: 6)
                                    .offset(y: 12)
                            }
                        }
                        .frame(height: 40)
                    }
                    .buttonStyle(PlainButtonStyle())
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
                Text("暂无任务")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
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
    
    private func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate)!
    }
    
    private func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate)!
    }
}
