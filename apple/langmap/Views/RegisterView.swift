import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("Enter email", text: $email)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("Enter username", text: $username)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            SecureField("Create password", text: $password)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            SecureField("Confirm password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                        }

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 16)
                        }

                        Button(action: handleRegister) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    HStack(spacing: 8) {
                        Text("Already have an account?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button("Sign In") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !username.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
            && password == confirmPassword
            && password.count >= 6
    }

    private func handleRegister() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                try await authService.register(email: email, username: username, password: password)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
