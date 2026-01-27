import Foundation

struct Language: Codable, Identifiable, Hashable {
    let id: Int
    let code: String
    let name: String
    let nativeName: String?
    let isActive: Int
    let regionCode: String?
    let regionName: String?

    enum CodingKeys: String, CodingKey {
        case id, code, name
        case nativeName = "native_name"
        case isActive = "is_active"
        case regionCode = "region_code"
        case regionName = "region_name"
    }
}
