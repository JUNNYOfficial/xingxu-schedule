import SwiftUI

struct HomeLayoutEditorView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var layoutItems: [HomeSectionItem] = []
    @State private var editMode: EditMode = .active
    
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach($layoutItems) { $item in
                        HStack(spacing: 16) {
                            Image(systemName: item.section.icon)
                                .font(.title3)
                                .foregroundColor(primaryTint)
                                .frame(width: 28)
                            
                            Text(item.section.displayName)
                                .font(.body)
                            
                            Spacer()
                            
                            Toggle("", isOn: $item.isVisible)
                                .labelsHidden()
                                .tint(primaryTint)
                        }
                        .padding(.vertical, 4)
                        .opacity(item.isVisible ? 1.0 : 0.5)
                    }
                    .onMove(perform: moveItem)
                } header: {
                    Text("拖动调整顺序，开关控制显示")
                        .font(.caption)
                } footer: {
                    Text("关闭的区块不会出现在主页，但数据仍然保留")
                        .font(.caption)
                }
                
                Section {
                    Button(action: resetToDefault) {
                        HStack {
                            Spacer()
                            Label("恢复默认布局", systemImage: "arrow.counterclockwise")
                                .font(.subheadline)
                            Spacer()
                        }
                        .foregroundColor(primaryTint)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("主页布局")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .environment(\.editMode, $editMode)
            .onAppear {
                layoutItems = dataManager.settings.homeLayout
            }
        }
    }
    
    private func moveItem(from source: IndexSet, to destination: Int) {
        layoutItems.move(fromOffsets: source, toOffset: destination)
    }
    
    private func resetToDefault() {
        withAnimation {
            layoutItems = HomeSectionItem.defaultLayout
        }
    }
    
    private func saveAndDismiss() {
        dataManager.settings.homeLayout = layoutItems
        dataManager.saveSettings()
        dismiss()
    }
}
