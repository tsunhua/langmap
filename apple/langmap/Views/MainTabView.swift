import SwiftUI

struct MainTabView: View {
    @State private var showingAddExpression = false

    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("nav_explore".localized, systemImage: "magnifyingglass.circle.fill")
                }
                .overlay(alignment: .bottomTrailing) {
                    FloatingActionButton {
                        showingAddExpression = true
                    }
                    .padding(20)
                }

            CollectionsView()
                .tabItem {
                    Label("nav_collections".localized, systemImage: "folder.fill")
                }
                .overlay(alignment: .bottomTrailing) {
                    FloatingActionButton {
                        showingAddExpression = true
                    }
                    .padding(20)
                }

            ProfileView()
                .tabItem {
                    Label("nav_profile".localized, systemImage: "person.fill")
                }
                .overlay(alignment: .bottomTrailing) {
                    FloatingActionButton {
                        showingAddExpression = true
                    }
                    .padding(20)
                }
        }
        .sheet(isPresented: $showingAddExpression) {
            AddExpressionSheet(isPresented: $showingAddExpression)
        }
    }
}
