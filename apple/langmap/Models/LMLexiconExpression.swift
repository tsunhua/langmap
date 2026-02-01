import Foundation

struct LMLexiconExpression: Codable, Identifiable {
    let id: Int
    let text: String
    let meaningId: Int?
    let audioUrl: String?
    let languageCode: String
    let regionCode: String?
    let regionName: String?
    let regionLatitude: Double?
    let regionLongitude: Double?
    let tags: String?
    let sourceType: String?
    let sourceRef: String?
    let reviewStatus: String?
    let createdBy: String?
    let createdAt: String
    let updatedAt: String
    let origin: String?
    let usage: String?

    var phrase: String {
        return text
    }

    var translation: String {
        return ""
    }

    enum CodingKeys: String, CodingKey {
        case id, text, tags, origin, usage
        case meaningId = "meaning_id"
        case audioUrl = "audio_url"
        case languageCode = "language_code"
        case regionCode = "region_code"
        case regionName = "region_name"
        case regionLatitude = "region_latitude"
        case regionLongitude = "region_longitude"
        case sourceType = "source_type"
        case sourceRef = "source_ref"
        case reviewStatus = "review_status"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
