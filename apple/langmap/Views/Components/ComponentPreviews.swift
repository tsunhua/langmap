import SwiftUI

// MARK: - Component Previews (TDD: These serve as visual tests)
// These previews will fail to compile until components are implemented

// This preview will fail until GlassCard is implemented
struct GlassCardPreview: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            GlassCard {
                Text("Card 1")
            }

            GlassCard(padding: AppSpacing.xl, cornerRadius: AppRadius.extraLarge) {
                Text("Card 2 with custom padding and radius")
            }

            Text("Modifier version")
                .glassCardStyle()
        }
        .padding()
    }
}

// This preview will fail until PrimaryButton is implemented
struct PrimaryButtonPreview: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            PrimaryButton(title: "Primary Button") {
                print("Tapped!")
            }

            PrimaryButton(title: "Loading", isLoading: true) {
                print("Shouldn't tap")
            }

            PrimaryButton(title: "Disabled", isDisabled: true) {
                print("Shouldn't tap")
            }

            SecondaryButton(title: "Secondary Button") {
                print("Secondary tapped!")
            }
        }
        .padding()
    }
}

// This preview will fail until SkeletonView is implemented
struct SkeletonViewPreview: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Title skeleton
            SkeletonView()
                .frame(width: 150, height: 24)

            // Text skeleton
            SkeletonView()
                .frame(width: 200, height: 16)

            // Button skeleton
            SkeletonView()
                .frame(height: AppTouchTarget.minSize)
        }
        .padding()
    }
}
