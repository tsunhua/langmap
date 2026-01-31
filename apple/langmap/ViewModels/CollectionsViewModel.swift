import Combine
import Foundation

class CollectionsViewModel: ObservableObject {
    private let networkService = NetworkService.shared

    @Published var collections: [LMCollection] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showCreateCollection = false
    @Published var contributionCount: Int = 0

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
                let request = networkService.createRequest(endpoint: "/collections")
                let response: [LMCollection] = try await networkService.performRequest(
                    request, responseType: [LMCollection].self)

                await MainActor.run {
                    self.collections = response
                    self.isLoading = false
                }

                // Load contribution count
                loadContributionCount()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func loadContributionCount() {
        Task {
            do {
                let request = NetworkService.shared.createRequest(endpoint: "/user/contributions/count")
                let response: [String: Int] = try await NetworkService.shared.performRequest(
                    request, responseType: [String: Int].self
                )
                await MainActor.run {
                    self.contributionCount = response["count"] ?? 0
                }
            } catch {
                // Handle error silently
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
