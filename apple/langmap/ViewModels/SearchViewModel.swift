import Foundation
import Combine

class SearchViewModel: ObservableObject {
    private let networkService = NetworkService.shared

    @Published var searchQuery = ""
    @Published var searchResults: [Expression] = []
    @Published var languages: [Language] = []
    @Published var selectedLanguage: Language?
    @Published var isLoading = false

    private var searchTask: Task<Void, Never>?

    func loadLanguages() {
        Task {
            do {
                let request = networkService.createRequest(endpoint: "/languages")
                let response: [Language] = try await networkService.performRequest(request, responseType: [Language].self)

                await MainActor.run {
                    self.languages = response.filter { $0.isActive == 1 }
                }
            } catch {
                print("Failed to load languages: \(error)")
            }
        }
    }

    func search() {
        searchTask?.cancel()

        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            isLoading = true

            do {
                var endpoint = "/search?q=\(searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

                if let langCode = selectedLanguage?.code {
                    endpoint += "&from_lang=\(langCode)"
                }

                let request = networkService.createRequest(endpoint: endpoint)
                let response: [Expression] = try await networkService.performRequest(request, responseType: [Expression].self)

                if !Task.isCancelled {
                    await MainActor.run {
                        self.searchResults = response
                        self.isLoading = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.searchResults = []
                        self.isLoading = false
                    }
                }
            }
        }
    }
}
