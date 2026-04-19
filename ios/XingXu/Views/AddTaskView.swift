import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    var editingTask: TaskItem?
    var date: String
    
    @State private var name = ""
    @State private var time = "09:00"
    @State private var endTime = ""
    @State private var icon = ""
    @State private var tag = ""
    @State private var repeatPattern = "none"
    @State private var remindMinutes: Int? = nil
    @State private var showEmojiPicker = false
    
    private let emojiGroups: [(String, [String])] = [
        ("日常", ["🛏️", "🪥", "🍽️", "🚿", "👕", "🎒", "🚶", "🏠", "🧹", "🥣"]),
        ("学习", ["📚", "✏️", "🎨", "🎹", "🧩", "📖", "🔢", "📝", "🎓", "🔬"]),
        ("健康", ["🏃", "🏥", "🛁", "💊", "😴", "🍎", "🦷", "🧘", "💪", "🩺"]),
        ("娱乐", ["🎮", "🎡", "🎬", "🎵", "🏖️", "✈️", "🎪", "🎯", "🏸", "🧸"]),
        ("其他", ["⭐", "⏰", "📱", "💡", "🎁", "🌟", "❤️", "🔔", "☀️", "🌙"])
    ]
    
    private let repeatOptions = [
        ("none", "不重复"),
        ("daily", "每天"),
        ("weekly", "每周"),
        ("workdays", "工作日"),
        ("weekends", "周末"),
        ("monthly", "每月")
    ]
    
    private let remindOptions: [(Int?, String)] = [
        (nil, "不提醒"),
        (5, "提前5分钟"),
        (10, "提前10分钟"),
        (15, "提前15分钟"),
        (30, "提前30分钟"),
        (60, "提前1小时")
    ]
    
    init(task: TaskItem? = nil, date: String = "") {
        self.editingTask = task
        self.date = task?.date ?? date
        
        if let task = task {
            _name = State(initialValue: task.name)
            _time = State(initialValue: task.time)
            _endTime = State(initialValue: task.endTime ?? "")
            _icon = State(initialValue: task.icon)
            _tag = State(initialValue: task.tag)
            _repeatPattern = State(initialValue: task.repeatPattern)
            _remindMinutes = State(initialValue: task.remindMinutes)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("任务信息") {
                    TextField("任务名称", text: $name)
                    
                    HStack {
                        Text("开始时间")
                        Spacer()
                        DatePicker("", selection: Binding(
                            get: { timeDate(from: time) },
                            set: { time = timeString(from: $0) }
                        ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("结束时间")
                        Spacer()
                        DatePicker("", selection: Binding(
                            get: { timeDate(from: endTime.isEmpty ? time : endTime) },
                            set: { endTime = timeString(from: $0) }
                        ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        if !endTime.isEmpty {
                            Button("清除") { endTime = "" }
                                .font(.caption)
                        }
                    }
                    
                    // Emoji 选择器
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("图标")
                            Spacer()
                            if !icon.isEmpty {
                                Text(icon)
                                    .font(.title2)
                            }
                            Button(showEmojiPicker ? "收起" : "选择") {
                                showEmojiPicker.toggle()
                            }
                            .font(.subheadline)
                        }
                        
                        if showEmojiPicker {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(emojiGroups, id: \.0) { group in
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(group.0)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                                                ForEach(group.1, id: \.self) { emoji in
                                                    Button(action: {
                                                        icon = emoji
                                                        showEmojiPicker = false
                                                    }) {
                                                        Text(emoji)
                                                            .font(.title3)
                                                            .frame(width: 36, height: 36)
                                                            .background(icon == emoji ? Color(.systemGray5) : Color.clear)
                                                            .cornerRadius(8)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                        }
                                    }
                                    
                                    if !icon.isEmpty {
                                        Button("清除图标") {
                                            icon = ""
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }
                            }
                            .frame(height: 280)
                        }
                    }
                }
                
                Section("分类") {
                    Picker("标签", selection: $tag) {
                        Text("无标签").tag("")
                        ForEach(TaskTags.all, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                }
                
                Section("提醒") {
                    Picker("提醒时间", selection: $remindMinutes) {
                        ForEach(remindOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                }
                
                Section("重复") {
                    Picker("重复模式", selection: $repeatPattern) {
                        ForEach(repeatOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                }
                
                if editingTask != nil {
                    Section {
                        Button(role: .destructive) {
                            if let task = editingTask {
                                dataManager.deleteTask(id: task.id)
                                dismiss()
                            }
                        } label: {
                            Text("删除任务")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle(editingTask == nil ? "添加任务" : "编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveTask() }
                        .disabled(name.isEmpty)
                        .accessibilityLabel("保存任务")
                        .accessibilityHint(name.isEmpty ? "请先填写任务名称" : "双击保存任务")
                }
            }
        }
    }
    
    private func saveTask() {
        let task = TaskItem(
            id: editingTask?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            time: time,
            endTime: endTime.isEmpty ? nil : endTime,
            icon: icon,
            completed: editingTask?.completed ?? false,
            date: date,
            tag: tag,
            repeatPattern: repeatPattern,
            remindMinutes: remindMinutes
        )
        
        if editingTask != nil {
            dataManager.updateTask(task)
        } else {
            dataManager.addTask(task)
        }
        dismiss()
    }
    
    private func timeDate(from string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: string) ?? Date()
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
