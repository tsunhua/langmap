import SwiftUI

struct LanguageFilterChip: View {
    let language: LMLexiconLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            Text(language.nativeName ?? language.name)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    isSelected
                        ? AnyShapeStyle(AppTheme.primaryGradient)
                        : AnyShapeStyle(Color.primary.opacity(0.05))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(AppRadius.large)
                .shadow(
                    color: isSelected ? Color(hex: "6366f1").opacity(0.3) : Color.clear,
                    radius: 5, x: 0, y: 3
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
