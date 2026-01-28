import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("nav_explore".localized, systemImage: "magnifyingglass.circle.fill")
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
    }
}
