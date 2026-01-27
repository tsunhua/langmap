import Foundation

struct Language: Codable, Identifiable, Hashable {
    let id: Int
    let code: String
    let name: String
    let direction: String
    let isActive: Int
    let regionCode: String?
    let regionName: String?
    let regionLatitude: Double?
    let regionLongitude: Double?
    let createdBy: String?
    let createdAt: String
    let updatedAt: String?

    var nativeName: String? {
        return name
    }

    enum CodingKeys: String, CodingKey {
        case id, code, name, direction
        case isActive = "is_active"
        case regionCode = "region_code"
        case regionName = "region_name"
        case regionLatitude = "region_latitude"
        case regionLongitude = "region_longitude"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
