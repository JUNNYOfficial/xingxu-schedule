import SwiftUI

struct TemplateLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var selectedTemplate: ScheduleTemplate? = nil
    @State private var showApplySheet = false
    @State private var showSaveSheet = false
    @State private var saveTemplateName = ""
    @State private var templateToDelete: ScheduleTemplate? = nil
    @State private var showDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部标题栏
                headerView
                
                // 保存当前日程为模板
                saveCurrentButton
                
                // 我的模板
                if !dataManager.customTemplates.isEmpty {
                    customTemplatesSection
                }
                
                // 预设模板
                presetTemplatesSection
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showApplySheet) {
            if let template = selectedTemplate {
                TemplateApplyView(template: template)
                    .environmentObject(dataManager)
            }
        }
        .sheet(isPresented: $showSaveSheet) {
            SaveTemplateSheet(name: $saveTemplateName) { name in
                dataManager.saveCustomTemplate(from: dataManager.currentDate, name: name)
            }
        }
        .alert("删除模板", isPresented: $showDeleteAlert, presenting: templateToDelete) { template in
            Button("删除", role: .destructive) {
                dataManager.deleteCustomTemplate(id: template.id)
            }
            Button("取消", role: .cancel) {}
        } message: { template in
            Text("确定要删除「\(template.name)」吗？")
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("📋 模板库")
                    .font(.title2.bold())
                Text("\(dataManager.allTemplates.count) 套可用模板")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Save Current Button
    
    private var saveCurrentButton: some View {
        let todayTasks = dataManager.tasksForDate(dataManager.currentDate)
        
        return Button(action: {
            saveTemplateName = ""
            showSaveSheet = true
        }) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.48, green: 0.61, blue: 0.75).opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "plus.square.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.48, green: 0.61, blue: 0.75))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("保存当前日程为模板")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(todayTasks.isEmpty ? "今日暂无任务" : "今日有 \(todayTasks.count) 个任务可保存")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(todayTasks.isEmpty)
        .opacity(todayTasks.isEmpty ? 0.5 : 1)
    }
    
    // MARK: - Custom Templates Section
    
    private var customTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("我的模板")
                    .font(.title3.bold())
                Spacer()
                Text("\(dataManager.customTemplates.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                ForEach(dataManager.customTemplates) { template in
                    templateCard(template: template, showDelete: true)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Preset Templates Section
    
    private var presetTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("预设模板")
                .font(.title3.bold())
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                ForEach(ScheduleTemplate.presets) { template in
                    templateCard(template: template, showDelete: false)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Template Card
    
    private func templateCard(template: ScheduleTemplate, showDelete: Bool) -> some View {
        Button(action: {
            selectedTemplate = template
            showApplySheet = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // 顶部彩色条
                Rectangle()
                    .fill(template.themeColor)
                    .frame(height: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                VStack(alignment: .leading, spacing: 12) {
                    // 标题行
                    HStack(spacing: 10) {
                        Text(template.icon)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.headline)
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if showDelete {
                            Button(action: {
                                templateToDelete = template
                                showDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.7))
                                    .padding(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // 迷你时间轴预览
                    HStack(spacing: 0) {
                        // 时间轴
                        VStack(spacing: 0) {
                            ForEach(Array(template.tasks.prefix(4).enumerated()), id: \.offset) { index, task in
                                HStack(spacing: 8) {
                                    // 时间点
                                    Circle()
                                        .fill(template.themeColor.opacity(0.2))
                                        .frame(width: 8, height: 8)
                                        .overlay(
                                            Circle()
                                                .fill(template.themeColor)
                                                .frame(width: 4, height: 4)
                                        )
                                    
                                    // 任务名
                                    Text(task.time)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Text(task.name)
                                        .font(.system(size: 11))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                }
                                
                                if index < min(template.tasks.count, 4) - 1 {
                                    Rectangle()
                                        .fill(template.themeColor.opacity(0.15))
                                        .frame(width: 1, height: 16)
                                        .padding(.leading, 3.5)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // 右侧：应用按钮
                        VStack(spacing: 4) {
                            Text("\(template.tasks.count)")
                                .font(.title2.bold())
                                .foregroundColor(template.themeColor)
                            Text("个任务")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Template Apply View (Sheet)

struct TemplateApplyView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    let template: ScheduleTemplate
    
    @State private var targetDate: TargetDate = .today
    
    enum TargetDate: String, CaseIterable {
        case today = "今天"
        case tomorrow = "明天"
        case dayAfter = "后天"
        
        var dateString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let calendar = Calendar.current
            switch self {
            case .today:
                return formatter.string(from: Date())
            case .tomorrow:
                return formatter.string(from: calendar.date(byAdding: .day, value: 1, to: Date())!)
            case .dayAfter:
                return formatter.string(from: calendar.date(byAdding: .day, value: 2, to: Date())!)
            }
        }
        
        var displayLabel: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let dateObj = formatter.date(from: dateString) else {
                return rawValue
            }
            formatter.dateFormat = "M/d"
            return "\(rawValue) (\(formatter.string(from: dateObj)))"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 模板标题
                    templateHeader
                    
                    // 日期选择
                    datePickerSection
                    
                    // 时间轴预览
                    timelinePreview
                    
                    // 应用按钮
                    applyButton
                }
                .padding()
            }
            .navigationTitle("应用模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var templateHeader: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16)
                .fill(template.themeColor.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(template.icon)
                        .font(.title)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.title3.bold())
                Text(template.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("共 \(template.tasks.count) 个任务")
                    .font(.caption)
                    .foregroundColor(template.themeColor)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("应用到哪一天？")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(TargetDate.allCases, id: \.self) { date in
                    Button(action: { targetDate = date }) {
                        VStack(spacing: 2) {
                            Text(date.rawValue)
                                .font(.subheadline.bold())
                            Text(date.displayLabel.components(separatedBy: "(").last?.replacingOccurrences(of: ")", with: "") ?? "")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(targetDate == date ? template.themeColor : Color(.systemGray6))
                        .foregroundColor(targetDate == date ? .white : .primary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var timelinePreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("任务预览")
                .font(.headline)
                .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                ForEach(Array(template.tasks.enumerated()), id: \.offset) { index, task in
                    HStack(alignment: .top, spacing: 12) {
                        // 左侧时间轴
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(template.themeColor.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Text("\(index + 1)")
                                    .font(.caption2.bold())
                                    .foregroundColor(template.themeColor)
                            }
                            
                            if index < template.tasks.count - 1 {
                                Rectangle()
                                    .fill(template.themeColor.opacity(0.2))
                                    .frame(width: 2)
                                    .frame(minHeight: 30)
                            }
                        }
                        
                        // 右侧任务卡片
                        HStack(spacing: 10) {
                            Text(task.icon)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.name)
                                    .font(.body)
                                HStack(spacing: 6) {
                                    Text(task.time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if !task.tag.isEmpty {
                                        Text(task.tag)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(tagColor(task.tag).opacity(0.12))
                                            .foregroundColor(tagColor(task.tag))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(12)
                        .padding(.bottom, index < template.tasks.count - 1 ? 8 : 0)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var applyButton: some View {
        Button(action: { applyTemplate() }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("应用到此日期")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(template.themeColor)
            .cornerRadius(16)
        }
    }
    
    private func applyTemplate() {
        let dateStr = targetDate.dateString
        
        for task in template.tasks {
            let newTask = TaskItem(
                name: task.name,
                time: task.time,
                icon: task.icon,
                date: dateStr,
                tag: task.tag
            )
            dataManager.addTask(newTask)
        }
        
        dismiss()
    }
    
    private func tagColor(_ tag: String) -> Color {
        // 自闭症友好：统一柔和蓝灰，不同明度区分
        switch tag {
        case "生活": return Color(red: 0.48, green: 0.61, blue: 0.75)
        case "学习": return Color(red: 0.42, green: 0.55, blue: 0.69)
        case "娱乐": return Color(red: 0.56, green: 0.69, blue: 0.83)
        case "健康": return Color(red: 0.35, green: 0.48, blue: 0.62)
        default: return Color(red: 0.48, green: 0.61, blue: 0.75)
        }
    }
}

// MARK: - Save Template Sheet

struct SaveTemplateSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var name: String
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 0.48, green: 0.61, blue: 0.75))
                    .padding(.top, 20)
                
                Text("保存为模板")
                    .font(.title2.bold())
                
                Text("给这套日程起个名字，以后可以一键复用")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("例如：周一上学日", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    onSave(name)
                    dismiss()
                }) {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.mint)
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.5 : 1)
            }
            .padding(.vertical)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
