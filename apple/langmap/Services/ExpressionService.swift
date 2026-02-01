import Foundation
import Combine

@MainActor
class ExpressionService: ObservableObject {
    static let shared = ExpressionService()
    private let networkService = NetworkService.shared

    private init() {}

    func searchExpressions(query: String, languageCode: String? = nil) async throws -> [LMLexiconExpression] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        var endpoint = "/search?q=\(encodedQuery)"

        if let languageCode = languageCode {
            endpoint += "&from_lang=\(languageCode)"
        }

        let request = networkService.createRequest(endpoint: endpoint)
        return try await networkService.performRequest(request, responseType: [LMLexiconExpression].self)
    }

    func getExpressions(limit: Int = 10, languageCode: String? = nil) async throws -> [LMLexiconExpression] {
        var endpoint = "/expressions?limit=\(limit)"

        if let languageCode = languageCode {
            endpoint += "&language=\(languageCode)"
        }

        let request = networkService.createRequest(endpoint: endpoint)
        return try await networkService.performRequest(request, responseType: [LMLexiconExpression].self)
    }

    func getLanguages() async throws -> [LMLexiconLanguage] {
        let request = networkService.createRequest(endpoint: "/languages")
        return try await networkService.performRequest(request, responseType: [LMLexiconLanguage].self)
    }

    func createExpression(text: String, languageCode: String) async throws -> LMLexiconExpression {
        var request = networkService.createRequest(endpoint: "/expressions", method: "POST")

        let expressionData: [String: Any] = [
            "text": text,
            "language_code": languageCode,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: expressionData)

        return try await networkService.performRequest(request, responseType: LMLexiconExpression.self)
    }
}
