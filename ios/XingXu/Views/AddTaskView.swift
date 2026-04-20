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
    @State private var durationMinutes: Int? = nil
    @State private var subSteps: [TaskSubStep] = []
    @State private var newStepText = ""
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
    
    private let durationOptions: [(Int?, String)] = [
        (nil, "未设置"),
        (15, "15分钟"),
        (30, "30分钟"),
        (45, "45分钟"),
        (60, "1小时"),
        (90, "1.5小时"),
        (120, "2小时")
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
            _durationMinutes = State(initialValue: task.durationMinutes)
            _subSteps = State(initialValue: task.subSteps)
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
                                                            .background(icon == emoji ? Color(red: 0.48, green: 0.61, blue: 0.75).opacity(0.15) : Color.clear)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 8)
                                                                    .stroke(icon == emoji ? Color(red: 0.48, green: 0.61, blue: 0.75) : Color.clear, lineWidth: 1.5)
                                                            )
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
                
                Section {
                    Picker("预估时长", selection: Binding(
                        get: { durationMinutes },
                        set: { newValue in
                            durationMinutes = newValue
                            updateEndTimeFromDuration()
                        }
                    )) {
                        ForEach(durationOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                } header: {
                    Text("预估时长")
                } footer: {
                    Text(durationMinutes == nil
                         ? "设置时长后自动计算结束时间"
                         : "结束时间：\(endTime.isEmpty ? "与开始相同" : endTime)")
                        .font(.caption)
                }
                
                // 子步骤编辑（Social Story）
                Section {
                    ForEach($subSteps) { $step in
                        HStack {
                            TextField("步骤名称", text: $step.title)
                            Button(action: {
                                withAnimation {
                                    subSteps.removeAll { $0.id == step.id }
                                    reindexSubSteps()
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                    }
                    .onMove(perform: moveSubStep)
                    
                    HStack {
                        TextField("新步骤，如：穿衣服", text: $newStepText)
                        Button(action: addSubStep) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(red: 0.48, green: 0.61, blue: 0.75))
                        }
                        .disabled(newStepText.isEmpty)
                    }
                } header: {
                    Text("步骤拆解（可选）")
                } footer: {
                    Text("将复杂任务拆成小步骤，完成一步勾一步，降低认知负荷")
                        .font(.caption)
                }
                
                Section("分类") {
                    Picker("标签", selection: $tag) {
                        Text("无标签").tag("")
                        ForEach(TaskTags.all, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                }
                
                Section {
                    Picker("提醒时间", selection: $remindMinutes) {
                        ForEach(remindOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                } header: {
                    Text("提醒")
                } footer: {
                    Text(remindMinutes == nil
                         ? "不发送通知，需要时可在设置中开启"
                         : "将在任务开始前发送温和提醒")
                        .font(.caption)
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
            .alert("时间冲突", isPresented: $showTimeConflictAlert) {
                Button("取消", role: .cancel) {}
                Button("仍要添加") {
                    showTimeConflictAlert = false
                    forceSaveTask()
                }
            } message: {
                Text("该时段与「\(conflictTaskName)」有重叠，是否仍要添加？")
            }
        }
    }
    
    @State private var showTimeConflictAlert = false
    @State private var conflictTaskName = ""
    
    private func saveTask() {
        // 时间冲突检测
        if editingTask == nil {
            let newStart = timeValue(time)
            let newEnd = endTime.isEmpty ? newStart + 1 : timeValue(endTime)
            let dayTasks = dataManager.tasksForDate(date)
            for existing in dayTasks {
                if existing.id == editingTask?.id { continue }
                let existStart = timeValue(existing.time)
                let existEnd = existing.endTime.map(timeValue) ?? existStart + 1
                if max(newStart, existStart) < min(newEnd, existEnd) {
                    conflictTaskName = existing.name
                    showTimeConflictAlert = true
                    return
                }
            }
        }
        
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
            remindMinutes: remindMinutes,
            durationMinutes: durationMinutes,
            subSteps: subSteps
        )
        
        if editingTask != nil {
            dataManager.updateTask(task)
        } else {
            dataManager.addTask(task)
        }
        dismiss()
    }
    
    private func forceSaveTask() {
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
            remindMinutes: remindMinutes,
            durationMinutes: durationMinutes,
            subSteps: subSteps
        )
        
        if editingTask != nil {
            dataManager.updateTask(task)
        } else {
            dataManager.addTask(task)
        }
        dismiss()
    }
    
    private func updateEndTimeFromDuration() {
        guard let duration = durationMinutes else {
            endTime = ""
            return
        }
        let start = timeValue(time)
        let endTotal = start + duration
        let endH = endTotal / 60
        let endM = endTotal % 60
        endTime = String(format: "%02d:%02d", endH, endM)
    }
    
    private func addSubStep() {
        guard !newStepText.isEmpty else { return }
        let step = TaskSubStep(title: newStepText.trimmingCharacters(in: .whitespaces), sortOrder: subSteps.count)
        subSteps.append(step)
        newStepText = ""
    }
    
    private func moveSubStep(from source: IndexSet, to destination: Int) {
        subSteps.move(fromOffsets: source, toOffset: destination)
        reindexSubSteps()
    }
    
    private func reindexSubSteps() {
        for i in subSteps.indices {
            subSteps[i].sortOrder = i
        }
    }
    
    private func timeValue(_ timeStr: String) -> Int {
        let parts = timeStr.split(separator: ":")
        let h = Int(parts.first ?? "0") ?? 0
        let m = Int(parts.last ?? "0") ?? 0
        return h * 60 + m
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
