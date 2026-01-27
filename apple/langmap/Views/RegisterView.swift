import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            AppTheme.primaryGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 50)

                    VStack(spacing: 12) {
                        Text("create_account".localized)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
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
                            Text("username".localized)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)

                            TextField("username".localized, text: $username)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(12)
                                .autocapitalization(.none)
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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("confirm_password".localized)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)

                            SecureField("confirm_password".localized, text: $confirmPassword)
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

                        Button(action: handleRegister) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("sign_up".localized)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        .disabled(isLoading || !isFormValid)
                    }
                    .glassCardStyle()
                    .padding(.horizontal)

                    Button("cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()

                    Spacer()
                }
                .padding()
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !username.isEmpty && !password.isEmpty && password == confirmPassword
            && password.count >= 6
    }

    private func handleRegister() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                try await authService.register(email: email, username: username, password: password)
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
