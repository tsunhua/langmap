import Foundation

struct CollectionItemResponse: Codable {
    let items: [CollectionItem]?
    let total: Int?
}
