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
                let response = try await CollectionService.shared.getCollections()

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
        _ = try await CollectionService.shared.createCollection(name: name, description: description)
        loadCollections()
    }

    func deleteCollection(_ collectionId: Int) async throws {
        try await CollectionService.shared.deleteCollection(id: collectionId)
        await MainActor.run {
            collections.removeAll { $0.id == collectionId }
        }
    }
}
