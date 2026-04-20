import SwiftUI
import UniformTypeIdentifiers
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var appleAuth = AppleAuthManager.shared
    @State private var showClearAlert = false
    @State private var showFileImporter = false
    @State private var importError: String? = nil
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if appleAuth.isSignedIn {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(red: 0.48, green: 0.61, blue: 0.75))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appleAuth.userName.isEmpty ? "Apple ID 用户" : appleAuth.userName)
                                    .font(.headline)
                                if !appleAuth.userEmail.isEmpty {
                                    Text(appleAuth.userEmail)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("退出登录") {
                                appleAuth.signOut()
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { _ in },
                            onCompletion: { result in
                                switch result {
                                case .success:
                                    appleAuth.signInWithApple()
                                case .failure(let error):
                                    print("登录失败: \(error)")
                                }
                            }
                        )
                        .frame(height: 44)
                        .cornerRadius(8)
                    }
                } header: {
                    Text("账户")
                } footer: {
                    Text("使用 Apple ID 登录后，数据可跨设备同步")
                        .font(.caption)
                }
                
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
                    Toggle("高对比度", isOn: $dataManager.settings.highContrastEnabled)
                    Toggle("颜色编码", isOn: $dataManager.settings.colorCodingEnabled)
                }
                
                Section("iCloud") {
                    Toggle("iCloud 同步", isOn: Binding(
                        get: { iCloudSyncManager.shared.isSyncEnabled },
                        set: { iCloudSyncManager.shared.isSyncEnabled = $0 }
                    ))
                    if iCloudSyncManager.shared.isSyncEnabled {
                        if let lastSync = iCloudSyncManager.shared.lastSyncTime {
                            Text("上次同步：\(formatSyncTime(lastSync))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if !iCloudSyncManager.shared.isAvailable {
                            Text("请登录 iCloud 以使用同步功能")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Section {
                    Toggle("同步到 Apple 健康", isOn: Binding(
                        get: { dataManager.settings.healthSyncEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let granted = await HealthManager.shared.requestAuthorization()
                                    await MainActor.run {
                                        dataManager.settings.healthSyncEnabled = granted
                                        dataManager.saveSettings()
                                    }
                                }
                            } else {
                                dataManager.settings.healthSyncEnabled = false
                                dataManager.saveSettings()
                            }
                        }
                    ))
                    if !HealthManager.shared.isAvailable {
                        Text("当前设备不支持 Apple 健康")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("健康")
                } footer: {
                    Text("将正念时间和心情记录同步到 Apple 健康，帮助您更全面地了解身心状态")
                        .font(.caption)
                }
                
                Section {
                    Toggle("开启周期追踪", isOn: $dataManager.settings.cycleTrackingEnabled)
                    if dataManager.settings.cycleTrackingEnabled {
                        Toggle("经前提醒", isOn: $dataManager.settings.cycleReminderEnabled)
                    }
                } header: {
                    Text("周期")
                } footer: {
                    Text(dataManager.settings.cycleTrackingEnabled
                         ? "记录月经周期，经前自动发送温和提醒。所有数据仅存储在本地"
                         : "记录月经周期，了解身体规律。所有数据仅存储在本地，完全隐私")
                        .font(.caption)
                }
                
                Section {
                    Toggle("重要任务全屏闹钟", isOn: $dataManager.settings.fullscreenAlarmEnabled)
                } header: {
                    Text("闹钟")
                } footer: {
                    Text(dataManager.settings.fullscreenAlarmEnabled
                         ? "重要任务提醒时将显示全屏闹钟，不易错过"
                         : "开启后，标记为\"重要\"的任务提醒时会显示全屏闹钟界面")
                        .font(.caption)
                }
                
                Section {
                    Toggle("启用提醒", isOn: Binding(
                        get: { dataManager.settings.notificationsEnabled },
                        set: { newValue in
                            if newValue {
                                requestNotificationPermission { granted in
                                    dataManager.settings.notificationsEnabled = granted
                                    dataManager.saveSettings()
                                }
                            } else {
                                dataManager.settings.notificationsEnabled = false
                                dataManager.saveSettings()
                            }
                        }
                    ))
                    if dataManager.settings.notificationsEnabled {
                        Picker("默认提前", selection: $dataManager.settings.notificationMinutes) {
                            Text("5分钟").tag(5)
                            Text("10分钟").tag(10)
                            Text("15分钟").tag(15)
                            Text("30分钟").tag(30)
                        }
                        
                        Toggle("只提醒重要任务", isOn: $dataManager.settings.onlyRemindImportant)
                        
                        HStack {
                            Text("勿扰时段")
                            Spacer()
                            Text("\(dataManager.settings.doNotDisturbStartHour):00 — \(dataManager.settings.doNotDisturbEndHour):00")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Text("开始")
                            Spacer()
                            Picker("", selection: $dataManager.settings.doNotDisturbStartHour) {
                                ForEach(18..<24, id: \.self) { h in
                                    Text("\(h):00").tag(h)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                        }
                        
                        HStack {
                            Text("结束")
                            Spacer()
                            Picker("", selection: $dataManager.settings.doNotDisturbEndHour) {
                                ForEach(5..<12, id: \.self) { h in
                                    Text("\(h):00").tag(h)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                        }
                    }
                } header: {
                    Text("通知")
                } footer: {
                    Text(dataManager.settings.notificationsEnabled
                         ? "只有明确设置了提醒的任务才会通知"
                         : "通知默认关闭，需要时请在添加任务时手动开启")
                        .font(.caption)
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
                dataManager.customTemplates = export.customTemplates
                dataManager.saveTasks()
                dataManager.saveMoods()
                dataManager.saveSettings()
                dataManager.saveCustomTemplates()
                
            } catch {
                importError = "解析失败: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            importError = "选择文件失败: \(error.localizedDescription)"
        }
    }
    
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func formatSyncTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func exportData() {
        let export = ExportData(
            tasks: dataManager.tasks,
            moods: dataManager.moods,
            settings: dataManager.settings,
            customTemplates: dataManager.customTemplates
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
