import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    private let primaryTint = Color(red: 0.48, green: 0.61, blue: 0.75)
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(primaryTint.opacity(0.35))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(primaryTint)
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
