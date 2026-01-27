import Foundation

struct Collection: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let createdAt: String
    let userId: Int
}

struct CollectionDetail: Codable {
    let id: Int
    let name: String
    let description: String?
    let createdAt: String
    let expressions: [Expression]
}
