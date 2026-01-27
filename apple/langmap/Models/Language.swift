import Foundation

struct Language: Codable, Identifiable, Hashable {
    let id: Int
    let code: String
    let name: String
    let nativeName: String?
    let isActive: Int
}
