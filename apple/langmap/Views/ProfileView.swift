import SwiftUI
import Combine

struct ProfileView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingLogoutAlert = false
    @State private var contributionCount: Int = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    userHeader
                    contributionStats
                    settingsList
                    logoutButton
                }
                .padding(16)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Logout", role: .destructive) {
                    authService.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
        .onAppear {
            loadContributionCount()
        }
    }

    private var userHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text(authService.currentUser?.username ?? "")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(authService.currentUser?.email ?? "")
                .font(.body)
                .foregroundColor(.secondary)

            if let role = authService.currentUser?.role {
                Text(role.capitalized)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding(.top, 24)
    }

    private var contributionStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Contributions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                Spacer()

                Text("\(contributionCount)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)

                Spacer()
            }
            .padding(24)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(12)
        }
    }

    private var settingsList: some View {
        VStack(spacing: 0) {
            SettingsRow(icon: "globe", title: "Language Preferences") {
                // Navigate to language preferences
            }

            Divider()
                .padding(.leading, 50)

            SettingsRow(icon: "bell", title: "Notifications") {
                // Navigate to notifications
            }

            Divider()
                .padding(.leading, 50)

            SettingsRow(icon: "info.circle", title: "About") {
                // Navigate to about
            }

            Divider()
                .padding(.leading, 50)

            SettingsRow(icon: "hand.raised", title: "Privacy Policy") {
                // Navigate to privacy policy
            }
        }
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }

    private var logoutButton: some View {
        Button(action: { showingLogoutAlert = true }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Logout")
                Spacer()
            }
            .foregroundColor(.red)
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.top, 24)
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
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}

class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""

    func loadUserProfile() async {
        // Implementation if needed
    }
}
