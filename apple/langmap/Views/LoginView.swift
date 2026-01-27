import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showRegister = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            AppTheme.primaryGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 50)

                    VStack(spacing: 12) {
                        Text("app_name".localized)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("login_subtitle".localized)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("email".localized)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)

                            TextField("email".localized, text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(12)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("password".localized)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)

                            SecureField("password".localized, text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(12)
                        }

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: handleLogin) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("sign_in".localized)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        .disabled(isLoading)
                    }
                    .glassCardStyle()
                    .padding(.horizontal)

                    HStack {
                        Text("dont_have_account".localized)
                            .foregroundColor(.white.opacity(0.8))
                        Button(action: { showRegister = true }) {
                            Text("sign_up".localized)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .fullScreenCover(isPresented: $showRegister) {
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
                presentationMode.wrappedValue.dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
