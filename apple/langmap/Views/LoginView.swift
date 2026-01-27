import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showRegister = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("LangMap")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: handleLogin) {
                    if isLoading {
                        ProgressView()
                            .foregroundColor(.white)
                    } else {
                        Text("Sign In")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .disabled(isLoading)

                HStack {
                    Text("Don't have an account?")
                    Button(action: { showRegister = true }) {
                        Text("Sign Up")
                            .fontWeight(.bold)
                    }
                }
            }
            .padding()
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showRegister) {
                RegisterView()
            }
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
