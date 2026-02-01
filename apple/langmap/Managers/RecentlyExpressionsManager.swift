import Foundation
import SwiftUI
import Combine

@MainActor
class RecentlyExpressionsManager: ObservableObject {
    static let shared = RecentlyExpressionsManager()

    private let networkService = NetworkService.shared
    private let maxCount = 10

    @Published var recentExpressions: [LMLexiconExpression] = []
    @Published var isLoading = false

    private init() {}

    func loadRecentExpressions() {
        isLoading = true

        Task {
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
