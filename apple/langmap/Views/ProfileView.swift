//
//  ProfileView.swift
//  LangMap
//
//  Profile page with modern UI and interactions
//

import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingLanguagePreferences = false
    @State private var showingLogoutAlert = false
    @State private var showingLogin = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if authService.isAuthenticated {
                        authenticatedContent
                    } else {
                        unauthenticatedContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationTitle("nav_profile".localized)
            .navigationBarTitleDisplayMode(.large)
            .alert("logout".localized, isPresented: $showingLogoutAlert) {
                Button("cancel".localized, role: .cancel) {}
                Button("logout".localized, role: .destructive) {
                    authService.logout()
                }
            } message: {
                Text("logout_confirm".localized)
            }
            .sheet(isPresented: $showingLogin) {
                LoginView()
            }
            .sheet(isPresented: $showingLanguagePreferences) {
                LanguagePreferencesSheet()
            }
        }
    }
    
    // MARK: - Authenticated Content
    
    private var authenticatedContent: some View {
        VStack(spacing: 20) {
            userInfoCard
            settingsSection
        }
    }
    
    // MARK: - User Info Card
    
    private var userInfoCard: some View {
        HStack(alignment: .center, spacing: 16) {
            // User info on the left
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    if let username = authService.currentUser?.username {
                        Text(username)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                    }

                    // Admin badge
                    if let role = authService.currentUser?.role,
                       role.lowercased() == "admin" {
                        Label("admin", systemImage: "checkmark.shield.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.gradient)
                            .clipShape(.capsule)
                    }
                }

                if let email = authService.currentUser?.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Subtle logout button
            Button(action: {
                showingLogoutAlert = true
            }) {
                Image(systemName: "arrow.right.square.fill")
                    .font(.body)
                    .foregroundStyle(.red)
                    .clipShape(.circle)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.03))
        .clipShape(.rect(cornerRadius: 20))
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(spacing: 0) {
            SettingsRow(icon: "globe", title: "language_preferences".localized) {
                showingLanguagePreferences = true
            }
            
            SettingsRow(icon: "info.circle", title: "about".localized) {
                // Navigate to about
            }
            
            SettingsRow(icon: "hand.raised", title: "privacy_policy".localized) {
                // Navigate to privacy policy
            }
        }
        .background(Color.primary.opacity(0.03))
        .clipShape(.rect(cornerRadius: 20))
    }
    
    // MARK: - Unauthenticated Content
    
    private var unauthenticatedContent: some View {
        VStack(spacing: 24) {
            // Login card
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 72))
                    .foregroundStyle(.secondary.opacity(0.4))
                
                VStack(spacing: 8) {
                    Text("not_logged_in".localized)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("login_prompt".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    showingLogin = true
                }) {
                    HStack(spacing: 8) {
                        Text("login_to_continue".localized)
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue.gradient)
                    .clipShape(.rect(cornerRadius: 14))
                }
            }
            .padding(24)
            .background(Color.primary.opacity(0.03))
            .clipShape(.rect(cornerRadius: 20))
            
            // Settings accessible without login
            VStack(spacing: 0) {
                SettingsRow(icon: "globe", title: "language_preferences".localized) {
                    showingLanguagePreferences = true
                }
                
                SettingsRow(icon: "info.circle", title: "about".localized) {
                    // Navigate to about
                }
                
                SettingsRow(icon: "hand.raised", title: "privacy_policy".localized) {
                    // Navigate to privacy policy
                }
            }
            .background(Color.primary.opacity(0.03))
            .clipShape(.rect(cornerRadius: 20))
        }
    }
    
    // MARK: - Settings Row
    
    struct SettingsRow: View {
        let icon: String
        let title: String
        let action: () -> Void
        var isLast: Bool = false
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 32, height: 32)
                    
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(!isLast ? Color.primary.opacity(0.04) : Color.clear)
        }
    }
    
    // MARK: - Language Preferences Sheet
    
    struct LanguagePreferencesSheet: View {
        @Environment(\.dismiss) private var dismiss
        @StateObject private var viewModel = LanguagePreferencesViewModel()
        
        var body: some View {
            NavigationStack {
                List {
                    ForEach(viewModel.supportedLanguages) { language in
                        Button(action: {
                            viewModel.selectLanguage(language)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Text(language.name)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if viewModel.selectedLanguage?.code == language.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.insetGrouped)
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
    
    // MARK: - App Language Model
    
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
            isLoading = true
            defer { isLoading = false }
            
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
}
