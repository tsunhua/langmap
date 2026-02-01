import Combine
import Foundation

class SearchViewModel: ObservableObject {
    private let networkService = NetworkService.shared
    private let historyManager = SearchHistoryManager.shared

    @Published var searchQuery = ""
    @Published var searchResults: [LMLexiconExpression] = []
    @Published var languages: [LMLexiconLanguage] = []
    @Published var selectedLanguage: LMLexiconLanguage?
    @Published var isLoading = false

    private var searchTask: Task<Void, Never>?

    // MARK: - Public Methods

    func loadLanguages() {
        // 避免重复加载
        guard !isLoading else { return }

        isLoading = true

        Task { @MainActor in
            let request = networkService.createRequest(endpoint: "/languages")

            do {
                let response: [LMLexiconLanguage] = try await networkService.performRequest(
                    request, responseType: [LMLexiconLanguage].self)

                self.languages = response.filter { $0.isActive == 1 }
                self.isLoading = false
            } catch {
                print("Failed to load languages: \(error)")
                self.isLoading = false
            }
        }
    }

    func search() {
        searchTask?.cancel()

        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        let searchQuery = self.searchQuery
        let selectedLanguage = self.selectedLanguage

        searchTask = Task { @MainActor in
            self.isLoading = true

            do {
                var endpoint =
                    "/search?q=\(searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

                let langCode: String?
                if let selectedLang = selectedLanguage {
                    langCode = selectedLang.code
                    endpoint += "&from_lang=\(selectedLang.code)"
                } else {
                    langCode = nil
                }

                print("Search endpoint: \(endpoint)")

                let request = networkService.createRequest(endpoint: endpoint)
                let response: [LMLexiconExpression] = try await networkService.performRequest(
                    request, responseType: [LMLexiconExpression].self)

                print("Search results count: \(response.count)")

                if !Task.isCancelled {
                    self.searchResults = response
                    self.isLoading = false

                    // Save to search history
                    historyManager.addToHistory(
                        query: searchQuery,
                        languageCode: langCode,
                        resultCount: response.count
                    )
                }
            } catch {
                print("Search failed: \(error)")
                if !Task.isCancelled {
                    self.searchResults = []
                    self.isLoading = false
                }
            }
        }
    }

    func searchHistoryItem(_ item: SearchHistoryItem) {
        searchQuery = item.query
        if let langCode = item.languageCode,
           let language = languages.first(where: { $0.code == langCode }) {
            selectedLanguage = language
        } else {
            selectedLanguage = nil
        }
        search()
    }

    func removeFromHistory(_ item: SearchHistoryItem) {
        historyManager.removeFromHistory(item)
    }

    func clearHistory() {
        historyManager.clearAllHistory()
    }

    var recentSearches: [SearchHistoryItem] {
        historyManager.getRecentSearches()
    }

    var hasSearchHistory: Bool {
        !historyManager.searchHistory.isEmpty
    }
}
