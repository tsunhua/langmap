import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("nav_home".localized, systemImage: "house.fill")
                }

            SearchView()
                .tabItem {
                    Label("nav_search".localized, systemImage: "magnifyingglass")
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
