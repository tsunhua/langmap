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
    @ObservedObject private var localizationManager = LocalizationManager.shared

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
            .navigationTitle("nav_profile".localized)
            .sheet(isPresented: $showingLanguagePreferences) {
                LanguagePreferencesSheet()
            }
            .alert("logout".localized, isPresented: $showingLogoutAlert) {
                Button("cancel".localized, role: .cancel) {}
                Button("logout".localized, role: .destructive) {
                    authService.logout()
                }
            } message: {
                Text("logout_confirm".localized)
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
                Text("total_contributions".localized)
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
            SettingsRow(icon: "globe", title: "language_preferences".localized) {
                showingLanguagePreferences = true
            }

            Divider()
                .padding(.leading, 50)

            SettingsRow(icon: "bell", title: "notifications".localized) {
                // Navigate to notifications
            }

            Divider()
                .padding(.leading, 50)

            SettingsRow(icon: "info.circle", title: "about".localized) {
                // Navigate to about
            }

            Divider()
                .padding(.leading, 50)

            SettingsRow(icon: "hand.raised", title: "privacy_policy".localized) {
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
                Text("logout".localized)
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
                Text("language_preferences".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, AppSpacing.lg)

                Divider()

                List {
                    ForEach(viewModel.supportedLanguages, id: \.code) { language in
                        Button(action: {
                            viewModel.selectLanguage(language)
                            dismiss()
                        }) {
                            HStack {
                                Text(language.name)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                if viewModel.selectedLanguage?.code == language.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
                .navigationTitle("language_preferences".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("cancel".localized) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Language Preferences ViewModel

class LanguagePreferencesViewModel: ObservableObject {
    @Published var supportedLanguages: [AppLanguage] = [
        AppLanguage(code: "en-US", name: "English"),
        AppLanguage(code: "zh-CN", name: "简体中文")
    ]
    @Published var selectedLanguage: AppLanguage?

    private let localizationManager = LocalizationManager.shared

    init() {
        selectedLanguage = supportedLanguages.first { $0.code == localizationManager.currentLanguage }
    }

    func selectLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        localizationManager.currentLanguage = language.code
    }
}

struct AppLanguage: Identifiable {
    let id = UUID()
    let code: String
    let name: String
}

// MARK: - Profile ViewModel

class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""

    func loadUserProfile() async {
        // Implementation if needed
    }
}
