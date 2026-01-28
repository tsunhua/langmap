import Foundation
import Combine

class ExploreViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [LMLexiconExpression] = []
    @Published var selectedLanguage: LMLexiconLanguage?
    @Published var languages: [LMLexiconLanguage] = []
    @Published var isLoading: Bool = false
    @Published var featuredExpressions: [LMLexiconExpression] = []

    private var cancellables = Set<AnyCancellable>()
    private var searchWorkItem: DispatchWorkItem?

    init() {
        setupSearchDebounce()
    }

    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
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
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    func loadFeaturedExpressions() {
        isLoading = true
        Task {
            do {
                var endpoint = "/expressions/featured"
                if let languageId = selectedLanguage?.id {
                    endpoint += "?language_id=\(languageId)"
                }
                let request = NetworkService.shared.createRequest(endpoint: endpoint)
                let response: [LMLexiconExpression] = try await NetworkService.shared.performRequest(
                    request, responseType: [LMLexiconExpression].self
                )
                await MainActor.run {
                    self.featuredExpressions = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    private func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        searchWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            Task {
                var components = URLComponents(string: "/expressions/search")
                var queryItems = [URLQueryItem(name: "q", value: self.searchQuery)]

                if let languageId = self.selectedLanguage?.id {
                    queryItems.append(URLQueryItem(name: "language_id", value: "\(languageId)"))
                }

                components?.queryItems = queryItems
                let endpoint = components?.url?.absoluteString ?? "/expressions/search"

                do {
                    let request = NetworkService.shared.createRequest(endpoint: endpoint)
                    let response: [LMLexiconExpression] = try await NetworkService.shared.performRequest(
                        request, responseType: [LMLexiconExpression].self
                    )
                    await MainActor.run {
                        self.searchResults = response
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            }
        }

        searchWorkItem = workItem
        workItem.perform()
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
