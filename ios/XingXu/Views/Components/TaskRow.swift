import SwiftUI

struct TaskRow: View {
    @EnvironmentObject var dataManager: DataManager
    
    let task: TaskItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var settings: AppSettings {
        dataManager.settings
    }
    
    private var effectiveTagColor: Color {
        settings.colorCodingEnabled ? Color(hex: task.tagColor) : .gray
    }
    
    private var strokeLineWidth: CGFloat {
        settings.highContrastEnabled ? 3 : (task.completed ? 1 : 2)
    }
    
    var body: some View {
        HStack(spacing: settings.childModeEnabled ? 16 : 12) {
            // 完成按钮
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(task.completed ? Color.mint : Color.gray.opacity(settings.highContrastEnabled ? 1.0 : 0.4), lineWidth: settings.childModeEnabled ? 3 : 2)
                        .frame(width: settings.childModeEnabled ? 36 : 28, height: settings.childModeEnabled ? 36 : 28)
                    if task.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: settings.childModeEnabled ? 18 : 14, weight: .bold))
                            .foregroundColor(.mint)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(task.completed ? "取消完成 \(task.name)" : "完成 \(task.name)")
            .accessibilityHint("双击切换任务完成状态")
            
            // 图标
            if !task.icon.isEmpty {
                Text(task.icon)
                    .font(settings.childModeEnabled ? .title2 : .title3)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: settings.childModeEnabled ? 6 : 4) {
                Text(task.name)
                    .font(settings.childModeEnabled ? .title3 : .body)
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? .secondary : .primary)
                
                if !settings.childModeEnabled {
                    HStack(spacing: 8) {
                        Text(task.displayTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !task.tag.isEmpty {
                            Text(task.tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(effectiveTagColor.opacity(settings.highContrastEnabled ? 0.25 : 0.15))
                                .foregroundColor(effectiveTagColor)
                                .cornerRadius(4)
                        }
                    }
                } else {
                    Text(task.displayTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 菜单（儿童模式下隐藏）
            if !settings.childModeEnabled {
                Menu {
                    Button(action: onEdit) {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .padding(8)
                }
                .accessibilityLabel("\(task.name) 的更多选项")
                .accessibilityHint("双击打开编辑和删除菜单")
            }
        }
        .padding(settings.childModeEnabled ? 20 : 16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(effectiveTagColor.opacity(task.completed ? 0.1 : (settings.highContrastEnabled ? 0.6 : 0.3)), lineWidth: strokeLineWidth)
        )
        .cornerRadius(12)
        .opacity(task.completed ? (settings.highContrastEnabled ? 0.9 : 0.7) : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.completed ? "已完成" : "未完成")任务：\(task.name)，时间 \(task.displayTime)")
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
