import SwiftUI

/// 编辑个人资料（昵称 + 头像）
struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var nickname = ""
    @State private var selectedAvatar = "🌸"
    
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    private let avatarOptions = [
        "🌸", "🌙", "⭐", "☀️", "🌈", "🍀", "🦋", "🐱",
        "🐶", "🐰", "🦊", "🐼", "🐨", "🦁", "🐯", "🐷",
        "🌵", "🌲", "🌻", "🍁", "❄️", "🔥", "💧", "🌍"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("头像") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(avatarOptions, id: \.self) { emoji in
                            Button(action: { selectedAvatar = emoji }) {
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 48, height: 48)
                                    .background(
                                        selectedAvatar == emoji
                                        ? primaryTint.opacity(0.15)
                                        : Color(.systemGray6)
                                    )
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedAvatar == emoji ? primaryTint : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("昵称") {
                    TextField("输入昵称", text: $nickname)
                        .font(.body)
                }
                
                Section("用户编号") {
                    HStack {
                        Text(dataManager.settings.userId ?? "—")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("复制") {
                            if let id = dataManager.settings.userId {
                                UIPasteboard.general.string = id
                            }
                        }
                        .font(.caption)
                        .foregroundColor(primaryTint)
                    }
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        dataManager.settings.nickname = nickname.isEmpty ? nil : nickname
                        dataManager.settings.avatarEmoji = selectedAvatar
                        dataManager.saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                nickname = dataManager.settings.nickname ?? ""
                selectedAvatar = dataManager.settings.avatarEmoji ?? "🌸"
            }
        }
    }
}
