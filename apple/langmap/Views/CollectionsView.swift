import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel = CollectionsViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingCreateCollection = false
    @State private var newCollectionName = ""
    @State private var newCollectionDescription = ""
    @State private var showingDeleteAlert = false
    @State private var collectionToDelete: LMCollection?

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                loadingView
            } else if !viewModel.errorMessage.isEmpty {
                errorView
            } else if viewModel.collections.isEmpty {
                emptyStateView
            } else {
                collectionsGrid
            }
        }
        .navigationTitle("collections".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateCollection = true }) {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 44, minHeight: 44)
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
        .alert("delete_collection".localized, isPresented: $showingDeleteAlert) {
            Button("delete".localized, role: .destructive) {
                if let collection = collectionToDelete {
                    deleteCollection(collection)
                }
            }
            Button("cancel".localized, role: .cancel) {}
        } message: {
            Text("delete_confirmation".localized)
        }
        .onAppear {
            if viewModel.collections.isEmpty {
                viewModel.loadCollections()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
            Text("loading_collections".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text(viewModel.errorMessage)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("retry".localized) {
                viewModel.loadCollections()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            Spacer()
        }
        .padding(.top, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("no_collections".localized)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            Text("create_first_collection".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("new_collection".localized) {
                showingCreateCollection = true
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            Spacer()
        }
        .padding(.top, 60)
    }

    private var collectionsGrid: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !viewModel.publicCollections.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Public Collections")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.publicCollections) { collection in
                                NavigationLink(
                                    destination: CollectionDetailView(collectionId: collection.id)
                                ) {
                                    CollectionCard(
                                        collection: collection,
                                        onTap: {},
                                        onDelete: {
                                            collectionToDelete = collection
                                            showingDeleteAlert = true
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                if !viewModel.privateCollections.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Private Collections")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.privateCollections) { collection in
                                NavigationLink(
                                    destination: CollectionDetailView(collectionId: collection.id)
                                ) {
                                    CollectionCard(
                                        collection: collection,
                                        onTap: {},
                                        onDelete: {
                                            collectionToDelete = collection
                                            showingDeleteAlert = true
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 80)
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

    private func deleteCollection(_ collection: LMCollection) {
        Task {
            do {
                try await viewModel.deleteCollection(collection.id)
                collectionToDelete = nil
            } catch {
                print("Failed to delete collection: \(error)")
            }
        }
    }
}

struct CollectionCard: View {
    let collection: LMCollection
    let onTap: () -> Void
    let onDelete: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(collection.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let description = collection.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 8) {
                Text("\(collection.items?.count ?? 0) " + "items".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if collection.isPublic == 1 {
                    Image(systemName: "globe")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }

                Spacer()

                Menu {
                    Button(action: onTap) {
                        Label("edit".localized, systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("delete".localized, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .frame(height: 120)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}
