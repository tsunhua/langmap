import SwiftUI

struct MainTabView: View {
    @State private var showingAddExpression = false
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("nav_search".localized, systemImage: "magnifyingglass.circle.fill")
                }

            AddExpressionView()
                .tabItem {
                    Label("nav_add".localized, systemImage: "plus.circle.fill")
                }

            CollectionsView()
                .tabItem {
                    Label("nav_collections".localized, systemImage: "folder.fill")
                }

            ProfileView()
                .tabItem {
                    Label("nav_profile".localized, systemImage: "person.fill")
                }
        }
        .sheet(isPresented: $showingAddExpression) {
            AddExpressionSheet(isPresented: $showingAddExpression)
        }
    }
}
