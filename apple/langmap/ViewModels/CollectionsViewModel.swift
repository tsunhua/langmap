import Combine
import Foundation

class CollectionsViewModel: ObservableObject {
    
    @Published var collections: [LMCollection] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showCreateCollection = false
    
    var privateCollections: [LMCollection] {
        collections.filter { $0.isPublic == 0 }
    }
    
    var publicCollections: [LMCollection] {
        collections.filter { $0.isPublic == 1 }
    }
    
    func loadCollections() {
        isLoading = true

        Task {
            do {
                let request = NetworkService.shared.createRequest(endpoint: "/collections")
                let response: [LMCollection] = try await NetworkService.shared.performRequest(
                    request, responseType: [LMCollection].self)

                await MainActor.run {
                    self.collections = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func createCollection(name: String, description: String) async throws {
        var request = NetworkService.shared.createRequest(endpoint: "/collections", method: "POST")

        let collectionData: [String: Any] = [
            "name": name,
            "description": description,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: collectionData)

        let _: LMCollection = try await NetworkService.shared.performRequest(
            request, responseType: LMCollection.self
        )
        loadCollections()
    }

    func deleteCollection(_ collectionId: Int) async throws {
        let request = NetworkService.shared.createRequest(
            endpoint: "/collections/\(collectionId)",
            method: "DELETE"
        )
        let _: EmptyResponse = try await NetworkService.shared.performRequest(
            request, responseType: EmptyResponse.self
        )
        await MainActor.run {
            collections.removeAll { $0.id == collectionId }
        }
    }
}

struct EmptyResponse: Codable {}
