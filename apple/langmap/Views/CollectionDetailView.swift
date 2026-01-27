import SwiftUI

struct CollectionDetailView: View {
    let collectionId: Int
    @State private var collection: CollectionDetail?
    @State private var isLoading = true
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let collection = collection {
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Collection Header
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
                                    "\((collection.items?.count ?? 0)) " + "items".localized,
                                    systemImage: "list.bullet")
                                Spacer()
                                Text("added_on".localized + " \(formatDate(collection.createdAt))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                        }
                        .glassCardStyle()
                        .padding(.horizontal)

                        // Items List
                        VStack(alignment: .leading, spacing: 15) {
                            Text("featured_expressions".localized)  // Or use a generic "Expressions" key if added
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            if let items = collection.items, !items.isEmpty {
                                LazyVStack(spacing: 12) {
                                    ForEach(items) { item in
                                        if let expression = item.expression {
                                            NavigationLink(
                                                destination: ExpressionDetailView(
                                                    expression: expression)
                                            ) {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    ExpressionCardView(expression: expression)

                                                    if let note = item.note, !note.isEmpty {
                                                        Text(note)
                                                            .font(.caption)
                                                            .italic()
                                                            .foregroundColor(.secondary)
                                                            .padding(.horizontal, 25)
                                                            .padding(.bottom, 5)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 20) {
                                    Image(systemName: "folder.badge.minus")
                                        .font(.system(size: 50))
                                        .foregroundColor(.secondary.opacity(0.5))

                                    Text("no_results".localized)  // Or "collection_empty"
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                            }
                        }
                    }
                    .padding(.vertical)
                }
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
        .navigationTitle("nav_collections".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCollection()
        }
    }

    private func loadCollection() {
        isLoading = true

        Task {
            do {
                let request = NetworkService.shared.createRequest(
                    endpoint: "/collections/\(collectionId)")
                let response: CollectionDetail = try await NetworkService.shared.performRequest(
                    request, responseType: CollectionDetail.self)

                await MainActor.run {
                    self.collection = response
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
