import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 完成按钮
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(task.completed ? Color.green : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if task.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 图标
            if !task.icon.isEmpty {
                Text(task.icon)
                    .font(.title3)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.body)
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Text(task.displayTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !task.tag.isEmpty {
                        Text(task.tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: task.tagColor).opacity(0.15))
                            .foregroundColor(Color(hex: task.tagColor))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // 菜单
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
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: task.tagColor).opacity(task.completed ? 0.1 : 0.3), lineWidth: task.completed ? 1 : 2)
        )
        .cornerRadius(12)
        .opacity(task.completed ? 0.7 : 1.0)
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
