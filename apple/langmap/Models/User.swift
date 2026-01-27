import Foundation

struct User: Codable {
    let id: Int
    let email: String
    let username: String
    let createdAt: String
    let emailVerified: Int?
    let role: String?

    enum CodingKeys: String, CodingKey {
        case id, email, username, role
        case createdAt = "created_at"
        case emailVerified = "email_verified"
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let data: AuthData
}

struct AuthData: Codable {
    let token: String
    let user: User
}

struct ApiError: Codable {
    let error: String
}
