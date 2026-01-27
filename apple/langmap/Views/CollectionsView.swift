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
                    VStack {
                        ProgressView()
                        Text("Loading collections...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.errorMessage.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)

                        Text(viewModel.errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Retry") {
                            viewModel.loadCollections()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if viewModel.collections.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("no_collections".localized)
                            .font(.title2)
                            .foregroundColor(.secondary)

                        Text("create_first_collection".localized)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.collections) { collection in
                                NavigationLink(
                                    destination: CollectionDetailView(collectionId: collection.id)
                                ) {
                                    CollectionCardView(collection: collection)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("nav_collections".localized)
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
                viewModel.loadCollections()
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
    let collection: LMCollection

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
