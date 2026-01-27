import Foundation

struct Collection: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let description: String?
    let isPublic: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case userId = "user_id"
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CollectionItem: Codable, Identifiable {
    let id: Int
    let collectionId: Int
    let expressionId: Int
    let note: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, note
        case collectionId = "collection_id"
        case expressionId = "expression_id"
        case createdAt = "created_at"
    }
}

struct CollectionDetail: Codable {
    let id: Int
    let userId: Int
    let name: String
    let description: String?
    let isPublic: Int
    let createdAt: String
    let updatedAt: String
    let items: [CollectionItem]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, items
        case userId = "user_id"
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
