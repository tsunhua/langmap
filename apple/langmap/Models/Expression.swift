import Foundation

struct Expression: Codable, Identifiable {
    let id: Int
    let phrase: String
    let translation: String
    let languageCode: String
    let origin: String?
    let usage: String?
    let createdAt: String
    let language: Language?
}

struct ExpressionListResponse: Codable {
    let data: [Expression]
    let total: Int
    let page: Int
}
