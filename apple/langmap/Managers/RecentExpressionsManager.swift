//
//  RecentExpressionsManager.swift
//  LangMap
//
//  Manages recently added expressions
//

import Foundation
import Combine

@MainActor
final class RecentExpressionsManager: ObservableObject {
    static let shared = RecentExpressionsManager()

    private let networkService = NetworkService.shared

    @Published var recentExpressions: [LMLexiconExpression] = []
    @Published var selectedLanguage: LMLexiconLanguage?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    private let maxCount = 20

    func loadRecentExpressions() {
        isLoading = true

        Task {
            do {
                var endpoint = "/expressions?limit=\(maxCount)"
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
