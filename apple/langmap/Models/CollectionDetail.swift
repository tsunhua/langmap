import Foundation

struct CollectionDetail: Codable {
    let id: Int
    let userId: Int
    let name: String
    let description: String?
    let isPublic: Int?
    let createdAt: String
    let updatedAt: String?
    let items: [CollectionItem]?
    let itemsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, description, items
        case itemsCount = "items_count"
        case userId = "user_id"
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
