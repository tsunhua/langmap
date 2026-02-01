import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showRegister = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("login_title".localized)
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, AppSpacing.xl)

                VStack(spacing: AppSpacing.lg) {
                    InputField(
                        title: "email".localized,
                        placeholder: "email".localized,
                        text: $email
                    )

                    InputField(
                        title: "password".localized,
                        placeholder: "password".localized,
                        text: $password,
                        isSecure: true
                    )

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, AppSpacing.md)
                    }

                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Text("sign_in".localized)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(AppRadius.medium)
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
                .padding(.horizontal, AppSpacing.xl)

                Spacer()

                Button(action: { showRegister = true }) {
                    Text("create_account".localized)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.bottom, AppSpacing.xl)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
    }

    private func handleLogin() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                try await authService.login(email: email, password: password)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
