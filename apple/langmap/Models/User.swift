import Foundation

struct User: Codable {
    let id: Int
    let email: String
    let username: String
    let createdAt: String
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
