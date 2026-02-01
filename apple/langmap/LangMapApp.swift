import SwiftUI

@main
struct LangMapApp: App {
    @StateObject var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    MainTabView()
                } else {
                    MainTabView()
                }
            }
            .environmentObject(authService)
            .environmentObject(LocalizationManager.shared)
        }
    }
}
