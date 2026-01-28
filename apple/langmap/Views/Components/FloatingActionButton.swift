import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(AppTheme.primaryGradient)
                .clipShape(Circle())
                .shadow(color: Color(hex: "6366f1").opacity(0.4), radius: 12, x: 0, y: 6)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(AppTheme.standardSpring) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
