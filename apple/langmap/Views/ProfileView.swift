import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = authService.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading) {
                                Text(user.username)
                                    .font(.headline)

                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "person.circle")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)

                            Text("Guest")
                                .font(.headline)
                        }
                    }
                }

                Section("Settings") {
                    HStack {
                        Image(systemName: "globe")
                        Text("Language")
                        Spacer()
                        Text("English")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "bell")
                        Text("Notifications")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("About LangMap")
                    }

                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Help & Support")
                    }

                    HStack {
                        Image(systemName: "star")
                        Text("Rate App")
                    }
                }

                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            Text("Log Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    authService.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}
