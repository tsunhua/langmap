import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let role: String
    let emailVerified: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, username, email, role
        case emailVerified = "email_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
