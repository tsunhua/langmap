import SwiftUI
import Combine

struct SearchAssociationSheet: View {
    @Binding var isPresented: Bool
    let selectedExpression: (LMLexiconExpression) -> Void
    @State private var searchQuery: String = ""
    @StateObject private var viewModel = SearchAssociationViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.lg) {
                TextField("Search expressions...", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.lg)
                    .onSubmit {
                        viewModel.search(query: searchQuery)
                    }

                if searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("Search for expressions")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Start typing to search")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.results.isEmpty {
                    Spacer()
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Try a different search term")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.results) { expression in
                            Button(action: {
                                selectedExpression(expression)
                                isPresented = false
                            }) {
                                HStack(spacing: AppSpacing.md) {
                                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                        Text(expression.text)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)

                                        if let region = expression.regionName {
                                            HStack(spacing: AppSpacing.xs) {
                                                Image(systemName: "location.fill")
                                                    .font(.caption2)
                                                Text(region)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "checkmark.circle")
                                        .font(.title2)
//                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, AppSpacing.sm)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search Expressions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            if !searchQuery.isEmpty {
                viewModel.search(query: searchQuery)
            }
        }
        .onChange(of: searchQuery) { _, newValue in
            if newValue.isEmpty {
                viewModel.clearResults()
            }
        }
    }
}

class SearchAssociationViewModel: NSObject, ObservableObject {
    @Published var results: [LMLexiconExpression] = []
    @Published var isLoading: Bool = false

    func search(query: String) {
        guard !query.isEmpty else { return }

        isLoading = true

        Task {
            do {
                let endpoint = "/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                let request = NetworkService.shared.createRequest(endpoint: endpoint, method: "GET")
                let response: [LMLexiconExpression] = try await NetworkService.shared.performRequest(request, responseType: [LMLexiconExpression].self)

                await MainActor.run {
                    self.results = response
                    self.isLoading = false
                }
            } catch {
                print("Search failed: \(error)")
                await MainActor.run {
                    self.results = []
                    self.isLoading = false
                }
            }
        }
    }

    func clearResults() {
        results = []
    }
}
