import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showClearAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("外观") {
                    Picker("主题", selection: $dataManager.settings.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    
                    Picker("字体大小", selection: $dataManager.settings.fontSize) {
                        ForEach(FontSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                }
                
                Section("辅助功能") {
                    Toggle("儿童模式", isOn: $dataManager.settings.childModeEnabled)
                    Toggle("高对比度", isOn: $dataManager.settings.highContrastEnabled)
                    Toggle("颜色编码", isOn: $dataManager.settings.colorCodingEnabled)
                }
                
                Section("通知") {
                    Toggle("启用提醒", isOn: $dataManager.settings.notificationsEnabled)
                    if dataManager.settings.notificationsEnabled {
                        Picker("提前提醒", selection: $dataManager.settings.notificationMinutes) {
                            Text("5分钟").tag(5)
                            Text("10分钟").tag(10)
                            Text("15分钟").tag(15)
                            Text("30分钟").tag(30)
                        }
                    }
                }
                
                Section("数据") {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("清空今日任务", systemImage: "trash")
                    }
                    
                    Button {
                        exportData()
                    } label: {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("2.0.0")
                            .foregroundColor(.secondary)
                    }
                    Text("星序 - 专为自闭症群体设计的日程管理工具")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("设置")
            .onChange(of: dataManager.settings) { _ in
                dataManager.saveSettings()
            }
            .alert("确认清空", isPresented: $showClearAlert) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    dataManager.clearTasksForDate(dataManager.currentDate)
                }
            } message: {
                Text("这将删除今天的所有任务，此操作不可撤销。")
            }
        }
    }
    
    private func exportData() {
        let export = [
            "tasks": dataManager.tasks,
            "moods": dataManager.moods,
            "settings": dataManager.settings
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: export, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let filename = "schedule-\(formatter.string(from: Date())).json"
            
            #if os(iOS)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try jsonString.write(to: tempURL, atomically: true, encoding: .utf8)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
            #endif
        } catch {
            print("导出失败: \(error)")
        }
    }
}
