import SwiftUI
import Combine

struct ProfileView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingLogoutAlert = false
    @State private var contributionCount: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // User Header
                        VStack(spacing: AppSpacing.md) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.accentColor)

                            Text(authService.currentUser?.username ?? "")
                                .font(.title)
                                .fontWeight(.bold)

                            Text(authService.currentUser?.email ?? "")
                                .font(.body)
                                .foregroundColor(.secondary)

                            if let role = authService.currentUser?.role {
                                Text(role.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(Color.primary.opacity(0.1))
                                    .cornerRadius(AppRadius.small)
                            }
                        }
                        .padding(.top, AppSpacing.xl)

                        // Contribution Stats
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("total_contributions".localized)
                                .font(.headline)

                            GlassCard {
                                HStack {
                                    Spacer()
                                    Text("\(contributionCount)")
                                        .font(.system(size: 48, weight: .bold))
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        // Settings List
                        VStack(spacing: 0) {
                            SettingsRow(icon: "globe", title: "Language Preferences") {}
                            Divider().padding(.leading, 50)
                            SettingsRow(icon: "bell", title: "Notifications") {}
                            Divider().padding(.leading, 50)
                            SettingsRow(icon: "info.circle", title: "About") {}
                            Divider().padding(.leading, 50)
                            SettingsRow(icon: "hand.raised", title: "Privacy Policy") {}
                        }
                        .glassCardStyle()
                        .padding(.horizontal, AppSpacing.lg)

                        // Logout Button
                        Button(action: { showingLogoutAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("logout".localized)
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(AppRadius.medium)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.xl)
                    }
                }
            }
            .navigationTitle("nav_profile".localized)
            .alert("logout".localized, isPresented: $showingLogoutAlert) {
                Button("logout".localized, role: .destructive) {
                    authService.logout()
                }
                Button("cancel".localized, role: .cancel) {}
            } message: {
                Text("logout_confirmation".localized)
            }
        }
        .onAppear {
            loadContributionCount()
        }
    }

    private func loadContributionCount() {
        Task {
            do {
                let request = NetworkService.shared.createRequest(endpoint: "/user/contributions/count")
                let response: [String: Int] = try await NetworkService.shared.performRequest(
                    request, responseType: [String: Int].self
                )
                await MainActor.run {
                    self.contributionCount = response["count"] ?? 0
                }
            } catch {
                // Handle error silently
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(AppSpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""

    func loadUserProfile() async {
        // Implementation if needed
    }
}
