import Combine
import Foundation

class CollectionsViewModel: ObservableObject {
    private let networkService = NetworkService.shared

    @Published var collections: [LMCollection] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showCreateCollection = false

    func loadCollections() {
        isLoading = true

        Task {
            do {
                let request = networkService.createRequest(endpoint: "/collections")
                let response: [LMCollection] = try await networkService.performRequest(
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
        var request = networkService.createRequest(endpoint: "/collections", method: "POST")

        let collectionData: [String: Any] = [
            "name": name,
            "description": description,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: collectionData)

        let _: LMCollection = try await networkService.performRequest(
            request, responseType: LMCollection.self)
        loadCollections()
    }
}
