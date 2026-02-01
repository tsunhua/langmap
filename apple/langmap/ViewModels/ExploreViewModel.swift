import Combine
import Foundation

class ExploreViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [LMLexiconExpression] = []
    @Published var selectedLanguage: LMLexiconLanguage?
    @Published var languages: [LMLexiconLanguage] = []
    @Published var isLoading: Bool = false
    @Published var recentExpressions: [LMLexiconExpression] = []

    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    init() {
        print("🚀 ExploreViewModel initialized")
        setupSearchDebounce()
    }

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                print("🔍 Search trigger (query: '\(query)')")
                self?.performSearch()
            }
            .store(in: &cancellables)
    }

    func loadLanguages() {
        isLoading = true
        Task {
            do {
                let request = NetworkService.shared.createRequest(endpoint: "/languages")
                let response: [LMLexiconLanguage] = try await NetworkService.shared.performRequest(
                    request, responseType: [LMLexiconLanguage].self
                )
                await MainActor.run {
                    self.languages = response
                    self.isLoading = false
                }
            } catch {
                print("Failed to load languages: \(error)")
                await MainActor.run {
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
                let request = NetworkService.shared.createRequest(endpoint: endpoint)
                let response: [LMLexiconExpression] = try await NetworkService.shared
                    .performRequest(
                        request, responseType: [LMLexiconExpression].self
                    )
                await MainActor.run {
                    self.recentExpressions = response
                    self.isLoading = false
                }
            } catch {
                print("Failed to load recent expressions: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    private func performSearch() {
        searchTask?.cancel()

        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true

        searchTask = Task {
            let encodedQuery =
                searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            var endpoint = "/search?q=\(encodedQuery)"

            if let languageCode = self.selectedLanguage?.code {
                endpoint += "&from_lang=\(languageCode)"
            }

            print("🔎 Exploring search endpoint: \(endpoint)")

            do {
                let request = NetworkService.shared.createRequest(endpoint: endpoint)
                let response: [LMLexiconExpression] = try await NetworkService.shared
                    .performRequest(
                        request, responseType: [LMLexiconExpression].self
                    )

                print("✅ Search results received count: \(response.count)")

                if !Task.isCancelled {
                    await MainActor.run {
                        self.searchResults = response
                        self.isLoading = false
                    }
                }
            } catch {
                print("❌ Search error: \(error)")
                if !Task.isCancelled {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        }
    }

    func toggleLanguage(_ language: LMLexiconLanguage) {
        if selectedLanguage?.id == language.id {
            selectedLanguage = nil
        } else {
            selectedLanguage = language
        }
        performSearch()
    }
}
