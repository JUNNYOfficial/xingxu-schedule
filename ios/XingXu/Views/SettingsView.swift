import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showClearAlert = false
    @State private var showFileImporter = false
    @State private var importError: String? = nil
    
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
                    
                    Button {
                        showFileImporter = true
                    } label: {
                        Label("导入数据", systemImage: "square.and.arrow.down")
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
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                handleImport(result: result)
            }
            .alert("导入失败", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(importError ?? "")
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
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                importError = "无法访问选中的文件"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                let export = try JSONDecoder().decode(ExportData.self, from: data)
                
                dataManager.tasks = export.tasks
                dataManager.moods = export.moods
                dataManager.settings = export.settings
                dataManager.saveTasks()
                dataManager.saveMoods()
                dataManager.saveSettings()
                
            } catch {
                importError = "解析失败: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            importError = "选择文件失败: \(error.localizedDescription)"
        }
    }
    
    private func exportData() {
        let export = ExportData(
            tasks: dataManager.tasks,
            moods: dataManager.moods,
            settings: dataManager.settings
        )
        
        do {
            let jsonData = try JSONEncoder().encode(export)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let filename = "schedule-\(formatter.string(from: Date())).json"
            
            #if os(iOS)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try jsonData.write(to: tempURL)
            
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
