import Foundation
import Combine

@MainActor
class CollectionService: ObservableObject {
    static let shared = CollectionService()
    private let networkService = NetworkService.shared

    private init() {}

    func getCollectionItems(id: Int, skip: Int = 0, limit: Int = 50) async throws -> CollectionItemResponse {
        let request = networkService.createRequest(
            endpoint: "/collections/\(id)/items?skip=\(skip)&limit=\(limit)")
        return try await networkService.performRequest(request, responseType: CollectionItemResponse.self)
    }

    func getCollectionById(id: Int) async throws -> CollectionDetail {
        let request = networkService.createRequest(endpoint: "/collections/\(id)")
        return try await networkService.performRequest(request, responseType: CollectionDetail.self)
    }

    func getCollections() async throws -> [LMCollection] {
        let request = networkService.createRequest(endpoint: "/collections")
        return try await networkService.performRequest(request, responseType: [LMCollection].self)
    }

    func createCollection(name: String, description: String) async throws -> LMCollection {
        var request = networkService.createRequest(endpoint: "/collections", method: "POST")

        let collectionData: [String: Any] = [
            "name": name,
            "description": description,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: collectionData)

        return try await networkService.performRequest(request, responseType: LMCollection.self)
    }

    func deleteCollection(id: Int) async throws {
        let request = networkService.createRequest(
            endpoint: "/collections/\(id)",
            method: "DELETE"
        )
        let _: EmptyResponse = try await networkService.performRequest(request, responseType: EmptyResponse.self)
    }
}
