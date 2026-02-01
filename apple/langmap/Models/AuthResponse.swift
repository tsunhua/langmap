import Foundation

struct AuthResponse: Codable {
    let success: Bool
    let data: AuthData
}
