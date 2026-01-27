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
    let meaningId: Int?
    let regionCode: String?
    let regionName: String?
    let regionLatitude: Double?
    let regionLongitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, phrase, translation, origin, usage, language
        case languageCode = "language_code"
        case createdAt = "created_at"
        case meaningId = "meaning_id"
        case regionCode = "region_code"
        case regionName = "region_name"
        case regionLatitude = "region_latitude"
        case regionLongitude = "region_longitude"
    }
}

struct ExpressionListResponse: Codable {
    let data: [Expression]
    let total: Int
    let page: Int
}
