import SwiftUI

struct MoodPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    let date: String
    @State private var selectedMood = 3
    @State private var note = ""
    
    private let moods = [
        (1, "😢", "很难过", Color.red),
        (2, "😔", "有点低落", Color.orange),
        (3, "😐", "一般", Color.gray),
        (4, "🙂", "还不错", Color.green),
        (5, "😊", "很开心", Color.blue)
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
        }
    }
    
    private func saveMood() {
        let mood = MoodEntry(date: date, value: selectedMood, note: note)
        dataManager.saveMood(mood)
        dismiss()
    }
}
