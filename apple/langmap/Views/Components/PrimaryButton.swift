import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    let isDisabled: Bool
    let isLoading: Bool

    init(title: String,
         isDisabled: Bool = false,
         isLoading: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(.body, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(height: AppTouchTarget.minSize)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isDisabled {
                        Color.gray.opacity(0.3)
                    } else {
                        AppTheme.primaryGradient
                    }
                }
            )
            .cornerRadius(AppRadius.medium)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AppTheme.standardSpring, value: isPressed)
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, weight: .semibold))
                .foregroundColor(.primary)
                .frame(height: AppTouchTarget.minSize)
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(AppRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
