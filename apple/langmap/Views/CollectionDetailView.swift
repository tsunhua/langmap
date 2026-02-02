import SwiftUI

struct CollectionDetailView: View {
    let collectionId: Int
    @State private var collection: CollectionDetail?
    @State private var items: [CollectionItem] = []
    @State private var languages: [LMLexiconLanguage] = []
    @State private var isLoading = true
    @State private var isLoadingItems = true
    @State private var errorMessage = ""
    @State private var currentPage = 1
    @State private var itemsPerPage = 20
    @State private var totalPages = 0
    @State private var totalItems = 0

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let collection = collection {
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(collection.name)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))

                                Spacer()

                                Image(systemName: collection.isPublic == 1 ? "globe" : "lock.fill")
                                    .foregroundColor(.secondary)
                            }

                            if let description = collection.description, !description.isEmpty {
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }

                            HStack {
                                Label(
                                    "\(totalItems)" + "items".localized,
                                    systemImage: "list.bullet")
                                Spacer()
                                Text("added_on".localized + " \(formatDate(collection.createdAt))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                        }
                        .padding()
                        .glassCardStyle()
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 15) {
                            if isLoadingItems {
                                VStack(spacing: 20) {
                                    ProgressView()
                                    Text("loading".localized)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                            } else if items.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "folder.badge.minus")
                                        .font(.system(size: 50))
                                        .foregroundColor(.secondary.opacity(0.5))

                                    Text("no_results".localized)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                            } else {
                                VStack(spacing: 4) {
                                    ForEach(items) { item in
                                        if let expression = item.expression {
                                            NavigationLink(
                                                destination: ExpressionDetailView(
                                                    expression: expression)
                                            ) {
                                                VStack(alignment: .leading, spacing: 0) {
                                                    ExpressionCardView(expression: expression, languages: languages, compact: true)

                                                    if let note = item.note, !note.isEmpty {
                                                        Text(note)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                            .padding(.horizontal, 12)
                                                            .padding(.vertical, 8)
                                                            .background(Color.yellow.opacity(0.1))
                                                    }
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            if totalPages > 1 {
                                paginationControls
                            }
                        }
                        .task(id: currentPage) {
                            await fetchItems()
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .navigationTitle("nav_collections".localized)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red.opacity(0.7))

                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadCollection()
        }
    }

    private var paginationControls: some View {
        HStack(spacing: 8) {
            Button(action: {
                if currentPage > 1 {
                    currentPage -= 1
                }
            }) {
                Text("prev".localized)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .disabled(currentPage == 1)

            Text("\(currentPage) / \(totalPages)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(minWidth: 40)

            Button(action: {
                if currentPage < totalPages {
                    currentPage += 1
                }
            }) {
                Text("next".localized)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .disabled(currentPage == totalPages)
        }
        .padding()
    }

    private func loadCollection() {
        isLoading = true

        Task {
            do {
                let response = try await CollectionService.shared.getCollectionById(id: collectionId)

                await MainActor.run {
                    self.collection = response
                    self.totalItems = response.itemsCount ?? 0
                    self.totalPages = max(1, Int(ceil(Double(self.totalItems) / Double(itemsPerPage))))
                    self.isLoading = false
                }

                await loadLanguages()
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func loadLanguages() async {
        do {
            self.languages = try await ExpressionService.shared.getLanguages()
        } catch {
            print("Failed to load languages: \(error)")
        }
    }

    private func fetchItems() async {
        isLoadingItems = true

        do {
            let skip = (currentPage - 1) * itemsPerPage
            let items = try await CollectionService.shared.getCollectionItems(
                id: collectionId,
                skip: skip,
                limit: itemsPerPage
            )

            await MainActor.run {
                self.items = items
                self.isLoadingItems = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingItems = false
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    } 
}
