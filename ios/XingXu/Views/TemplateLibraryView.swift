import SwiftUI

struct TemplateLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var selectedTemplate: ScheduleTemplate? = nil
    @State private var targetDate: TargetDate = .today
    @State private var showPreview = false
    
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
                return "📅 \(rawValue)"
            }
            formatter.dateFormat = "M月d日"
            let dateStr = formatter.string(from: dateObj)
            return "📅 \(rawValue) (\(dateStr))"
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if showPreview, let template = selectedTemplate {
                    previewView(template: template)
                } else {
                    templateGrid
                }
            }
            .navigationTitle("📋 日程模板库")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Template Grid
    
    private var templateGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(ScheduleTemplate.presets) { template in
                    Button(action: {
                        selectedTemplate = template
                        showPreview = true
                    }) {
                        VStack(spacing: 12) {
                            Text(template.icon)
                                .font(.system(size: 44))
                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Text("\(template.tasks.count) 个任务")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 2)
                        )
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    // MARK: - Preview View
    
    private func previewView(template: ScheduleTemplate) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // 模板标题
                HStack {
                    Text(template.icon)
                        .font(.title)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                        Text("\(template.tasks.count) 个任务")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { showPreview = false }) {
                        Image(systemName: "arrow.left")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                
                // 日期选择
                VStack(alignment: .leading, spacing: 10) {
                    Text("应用到哪一天？")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        ForEach(TargetDate.allCases, id: \.self) { date in
                            Button(action: { targetDate = date }) {
                                Text(date.displayLabel)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(targetDate == date ? Color.primary : Color(.systemGray6))
                                    .foregroundColor(targetDate == date ? Color(.systemBackground) : .primary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 任务预览列表
                VStack(alignment: .leading, spacing: 12) {
                    Text("任务预览")
                        .font(.headline)
                    
                    ForEach(Array(template.tasks.enumerated()), id: \.offset) { index, task in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                                .background(Color(.systemGray5))
                                .cornerRadius(6)
                            
                            Text(task.icon)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.name)
                                    .font(.body)
                                Text("🕐 \(task.time)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !task.tag.isEmpty {
                                Text(task.tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: TaskTags.colors[task.tag] ?? "#6B7280").opacity(0.15))
                                    .foregroundColor(Color(hex: TaskTags.colors[task.tag] ?? "#6B7280"))
                                    .cornerRadius(4)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .cornerRadius(10)
                    }
                }
                
                // 确认按钮
                Button(action: { applyTemplate(template) }) {
                    Text("确认应用")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .cornerRadius(16)
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }
    
    // MARK: - Apply Template
    
    private func applyTemplate(_ template: ScheduleTemplate) {
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
    
    // MARK: - Helpers
    
    private func date(from string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string) ?? Date()
    }
}
