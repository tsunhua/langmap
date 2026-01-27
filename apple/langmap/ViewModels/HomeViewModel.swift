import Foundation
import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    private let networkService = NetworkService.shared

    @Published var featuredExpressions: [Expression] = []
    @Published var languages: [Language] = []
    @Published var selectedLanguage: Language?
    @Published var isLoading = false
    @Published var errorMessage = ""

    func loadLanguages() {
        isLoading = true

        Task {
            do {
                let request = networkService.createRequest(endpoint: "/languages")
                let response: [Language] = try await networkService.performRequest(request, responseType: [Language].self)

                await MainActor.run {
                    self.languages = response.filter { $0.isActive == 1 }
                    if self.selectedLanguage == nil && !self.languages.isEmpty {
                        self.selectedLanguage = self.languages.first
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.languages = []
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func loadFeaturedExpressions() {
        isLoading = true

        Task {
            do {
                var endpoint = "/expressions?limit=10"
                if let langCode = selectedLanguage?.code {
                    endpoint += "&language=\(langCode)"
                }

                 let request = networkService.createRequest(endpoint: endpoint)
                let response: [Expression] = try await networkService.performRequest(request, responseType: [Expression].self)

                await MainActor.run {
                    self.featuredExpressions = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.featuredExpressions = []
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
