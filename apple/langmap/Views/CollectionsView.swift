import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel = CollectionsViewModel()
    @State private var showingCreateCollection = false
    @State private var newCollectionName = ""
    @State private var newCollectionDescription = ""

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.collections.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No collections yet")
                            .font(.title2)
                            .foregroundColor(.secondary)

                        Text("Create your first collection to save expressions")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.collections) { collection in
                        NavigationLink(destination: CollectionDetailView(collectionId: collection.id)) {
                            CollectionCardView(collection: collection)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateCollection = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateCollection) {
                CreateCollectionSheet(
                    isPresented: $showingCreateCollection,
                    name: $newCollectionName,
                    description: $newCollectionDescription,
                    onCreate: handleCreateCollection
                )
            }
            .onAppear {
                if viewModel.collections.isEmpty {
                    viewModel.loadCollections()
                }
            }
        }
    }

    private func handleCreateCollection() {
        Task {
            do {
                try await viewModel.createCollection(
                    name: newCollectionName,
                    description: newCollectionDescription
                )
                newCollectionName = ""
                newCollectionDescription = ""
                showingCreateCollection = false
            } catch {
                print("Failed to create collection: \(error)")
            }
        }
    }
}

struct CollectionCardView: View {
    let collection: Collection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(collection.name)
                .font(.headline)

            if let description = collection.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
