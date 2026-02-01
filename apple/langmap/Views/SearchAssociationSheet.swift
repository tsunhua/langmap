import SwiftUI
import Combine

struct SearchAssociationSheet: View {
    @Binding var isPresented: Bool
    let currentMeaningId: Int?
    let selectedExpression: (LMLexiconExpression) -> Void
    @State private var searchQuery: String = ""
    @StateObject private var viewModel = SearchAssociationViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.accentColor)

                    TextField("search_expressions".localized, text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            viewModel.search(query: searchQuery)
                        }

                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                            viewModel.clearResults()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.03))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                if searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("search_for_expressions".localized)
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("start_typing_to_search".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if viewModel.isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("searching".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if viewModel.results.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("no_results".localized)
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("start_typing".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(viewModel.results) { expression in
                                Button(action: {
                                    selectedExpression(expression)
                                    isPresented = false
                                }) {
                                    ExpressionCardView(expression: expression, compact: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Search")
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
