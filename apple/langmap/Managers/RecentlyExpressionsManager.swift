import Foundation
import SwiftUI
import Combine

class RecentlyExpressionsManager: ObservableObject {
    static let shared = RecentlyExpressionsManager()

    private let networkService = NetworkService.shared
    private let maxCount = 10

    @Published var recentExpressions: [LMLexiconExpression] = []
    @Published var isLoading = false

    private init() {}

    func loadRecentExpressions() {
        // 避免重复加载
        guard !isLoading else { return }

        isLoading = true

        Task { @MainActor in
            do {
                let endpoint = "/expressions?limit=\(maxCount)"
                let request = networkService.createRequest(endpoint: endpoint)
                let response: [LMLexiconExpression] = try await networkService.performRequest(
                    request, responseType: [LMLexiconExpression].self)

                self.recentExpressions = response
                self.isLoading = false
            } catch {
                self.recentExpressions = []
                self.isLoading = false
            }
        }
    }
}
