import Foundation

struct LMCollection: Codable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let description: String?
    let isPublic: Int?
    let items: [CollectionItem]?
    let itemsCount: Int?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, items
        case userId = "user_id"
        case isPublic = "is_public"
        case itemsCount = "items_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
