import Combine
import Foundation
import SwiftUI

class HomeViewModel: ObservableObject {
    private let networkService = NetworkService.shared

    @Published var recentExpressions: [LMLexiconExpression] = []
    @Published var languages: [LMLexiconLanguage] = []
    @Published var selectedLanguage: LMLexiconLanguage?
    @Published var isLoading = false
    @Published var errorMessage = ""

    func loadLanguages() {
        isLoading = true

        Task {
            do {
                let request = networkService.createRequest(endpoint: "/languages")
                let response: [LMLexiconLanguage] = try await networkService.performRequest(
                    request, responseType: [LMLexiconLanguage].self)

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

    func loadRecentExpressions() {
        isLoading = true

        Task {
            do {
                var endpoint = "/expressions?limit=10"
                if let langCode = selectedLanguage?.code {
                    endpoint += "&language=\(langCode)"
                }

                let request = networkService.createRequest(endpoint: endpoint)
                let response: [LMLexiconExpression] = try await networkService.performRequest(
                    request, responseType: [LMLexiconExpression].self)

                await MainActor.run {
                    self.recentExpressions = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.recentExpressions = []
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
