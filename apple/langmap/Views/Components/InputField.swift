import SwiftUI

struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            ZStack(alignment: .leading) {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                        .font(.body)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(AppRadius.medium)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .font(.body)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(AppRadius.medium)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}
