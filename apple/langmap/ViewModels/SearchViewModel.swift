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
                var endpoint = "/expressions?query=\(searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

                if let langCode = selectedLanguage?.code {
                    endpoint += "&language_code=\(langCode)"
                }

                let request = networkService.createRequest(endpoint: endpoint)
                let response: ExpressionListResponse = try await networkService.performRequest(request, responseType: ExpressionListResponse.self)

                if !Task.isCancelled {
                    await MainActor.run {
                        self.searchResults = response.data
                        self.isLoading = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        }
    }
}
