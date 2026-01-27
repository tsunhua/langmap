import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService()
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            VStack {
                if let user = authService.currentUser {
                    ScrollView {
                        VStack(spacing: 25) {
                            // Profile Header
                            VStack(spacing: 15) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.accentColor)

                                Text(user.username)
                                    .font(.title)
                                    .fontWeight(.bold)

                                Text(user.email)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 40)

                            // Stats/Info Section
                            VStack(spacing: 0) {
                                ProfileRow(
                                    icon: "calendar", title: "joined".localized,
                                    value: formatDate(user.createdAt))
                                Divider().padding(.leading, 50)
                                ProfileRow(
                                    icon: "shield.fill", title: "role".localized,
                                    value: user.role.capitalized
                                )
                            }
                            .glassCardStyle()
                            .padding(.horizontal)

                            // Actions
                            VStack(spacing: 12) {
                                Button(action: { showingLogoutAlert = true }) {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("logout".localized)
                                        Spacer()
                                    }
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)

                        Text("not_logged_in".localized)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("login_prompt".localized)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
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
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
