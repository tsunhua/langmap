import SwiftUI
import CoreData

@main
struct langmapApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}
