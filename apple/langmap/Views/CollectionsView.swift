import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel = CollectionsViewModel()
    @State private var showingCreateCollection = false
    @State private var newCollectionName = ""
    @State private var newCollectionDescription = ""
    @State private var showingDeleteAlert = false
    @State private var collectionToDelete: LMCollection?

    let columns = [
        GridItem(.flexible(), spacing: AppTheme.cardSpacing),
        GridItem(.flexible(), spacing: AppTheme.cardSpacing)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

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
            .alert("Delete Collection", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let collection = collectionToDelete {
                        deleteCollection(collection)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this collection?")
            }
            .onAppear {
                if viewModel.collections.isEmpty {
                    viewModel.loadCollections()
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
            Text("Loading collections...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: AppSpacing.xl) {
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
    }

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("no_collections".localized)
                .font(.title2)
                .foregroundColor(.secondary)

            Text("create_first_collection".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
    }

    private var collectionsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppTheme.cardSpacing) {
                ForEach(viewModel.collections) { collection in
                    NavigationLink(
                        destination: CollectionDetailView(collectionId: collection.id)
                    ) {
                        CollectionCard(collection: collection) {
                            // Navigate to collection detail
                        } onDelete: {
                            collectionToDelete = collection
                            showingDeleteAlert = true
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(AppSpacing.lg)
            .padding(.bottom, 80) // Space for FAB
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
    @State private var showingMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header with gradient
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: gradientColors.randomElement() ?? "6366f1"),
                        Color(hex: gradientColors.randomElement() ?? "a855f7")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 60)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(collection.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack {
                        Spacer()
                        Menu {
                            Button(action: {}) {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: onDelete) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(AppSpacing.md)
            }

            // Body
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                if let description = collection.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text("\(collection.items?.count ?? 0) items")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(AppRadius.small)
            }
            .padding(AppSpacing.md)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(AppRadius.large)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private let gradientColors = ["6366f1", "a855f7", "ec4899", "f59e0b", "10b981", "3b82f6"]
