//
// MARK: - Profile Components

import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ProfileViewModel()
    @State private var contributionCount: Int = 0
    @State private var showingLanguagePreferences = false
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    contributionStats
                    settingsList
                    logoutButton
                }
                .padding(16)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingLanguagePreferences) {
                LanguagePreferencesSheet()
            }
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    authService.logout()
                }
            } message: {
                Text("确定要退出登录吗？")
            }
            .onAppear {
                loadContributionCount()
            }
        }
    }

    private var contributionStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Spacer()
                Text("总贡献")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

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
            SettingsRow(icon: "globe", title: "语言偏好") {
                showingLanguagePreferences = true
            }

            Divider()
                .padding(.leading, 50)

            SettingsRow(icon: "bell", title: "通知") {
                // Navigate to notifications
            }

            Divider()
                .padding(.leading, 50)

            SettingsRow(icon: "info.circle", title: "关于") {
                // Navigate to about
            }

            Divider()
                .padding(.leading, 50)

            SettingsRow(icon: "hand.raised", title: "隐私政策") {
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
                Text("退出")
                Spacer()
            }
            .foregroundColor(.red)
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            .padding(.top, 24)
        }
    }

    func loadContributionCount() {
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

struct LanguagePreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LanguagePreferencesViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("语言偏好")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, AppSpacing.lg)

                Divider()

                List {
                    ForEach(viewModel.languages) { language in
                        Button(action: {
                            viewModel.selectLanguage(language)
                            dismiss()
                        }) {
                            HStack {
                                Text(language.nativeName ?? language.name)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                if viewModel.selectedLanguage?.id == language.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
                .navigationTitle("语言偏好")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadLanguages()
            }
        }
    }
}

// MARK: - Language Preferences ViewModel

class LanguagePreferencesViewModel: ObservableObject {
    @Published var languages: [LMLexiconLanguage] = []
    @Published var selectedLanguage: LMLexiconLanguage?
    @Published var isLoading = false

    private let networkService = NetworkService.shared

    func loadLanguages() {
        isLoading = true

        Task {
            do {
                let request = networkService.createRequest(endpoint: "/languages")
                let response: [LMLexiconLanguage] = try await networkService.performRequest(
                    request, responseType: [LMLexiconLanguage].self
                )

                await MainActor.run {
                    self.languages = response
                    self.selectedLanguage = response.first { $0.id == UserDefaults.standard.integer(forKey: "preferredLanguageId") }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    func selectLanguage(_ language: LMLexiconLanguage) {
        selectedLanguage = language
        UserDefaults.standard.set(language.id, forKey: "preferredLanguageId")
    }
}

// MARK: - Profile ViewModel

class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""

    func loadUserProfile() async {
        // Implementation if needed
    }
}
