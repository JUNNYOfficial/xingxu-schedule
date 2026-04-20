import SwiftUI

struct MoodPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let date: String
    @State private var selectedMood = 3
    @State private var note = ""
    @State private var showBreathingGuide = false
    
    private let moods = [
        (1, "😢", "很难过", Color(red: 0.35, green: 0.48, blue: 0.62)),
        (2, "😔", "有点低落", Color(red: 0.40, green: 0.53, blue: 0.67)),
        (3, "😐", "一般", Color(red: 0.48, green: 0.61, blue: 0.75)),
        (4, "🙂", "还不错", Color(red: 0.56, green: 0.69, blue: 0.83)),
        (5, "😊", "很开心", Color(red: 0.64, green: 0.77, blue: 0.90))
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("今天感觉怎么样？")
                    .font(.title2.bold())
                    .padding(.top)
                
                HStack(spacing: 16) {
                    ForEach(moods, id: \.0) { mood in
                        Button(action: { selectedMood = mood.0 }) {
                            VStack(spacing: 8) {
                                Text(mood.1)
                                    .font(.system(size: 48))
                                Text(mood.2)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                selectedMood == mood.0
                                    ? mood.3.opacity(0.2)
                                    : Color(.systemGray6)
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedMood == mood.0 ? mood.3 : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("备注（可选）")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextEditor(text: $note)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: saveMood) {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .cornerRadius(16)
                }
                .accessibilityLabel("保存心情记录")
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("心情日记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(isPresented: $showBreathingGuide, onDismiss: {
                dismiss()
            }) {
                BreathingGuideView()
            }
        }
    }
    
    private func saveMood() {
        let mood = MoodEntry(date: date, value: selectedMood, note: note)
        dataManager.saveMood(mood)
        
        // 低分心情自动建议呼吸练习
        if selectedMood <= 2 {
            showBreathingGuide = true
        } else {
            dismiss()
        }
    }
}
