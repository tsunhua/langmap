import Foundation

struct CollectionItem: Codable, Identifiable {
    let id: Int
    let collectionId: Int
    let expressionId: Int
    let note: String?
    let createdAt: String
    let updatedAt: String?
    let expression: LMLexiconExpression?

    enum CodingKeys: String, CodingKey {
        case id, note, expression
        case collectionId = "collection_id"
        case expressionId = "expression_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
