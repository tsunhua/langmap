import Foundation

struct Collection: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let createdAt: String
    let userId: Int
    let isPublic: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case createdAt = "created_at"
        case userId = "user_id"
        case isPublic = "is_public"
    }
}

struct CollectionDetail: Codable {
    let id: Int
    let name: String
    let description: String?
    let createdAt: String
    let expressions: [Expression]

    enum CodingKeys: String, CodingKey {
        case id, name, description, expressions
        case createdAt = "created_at"
    }
}
