import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar

                if viewModel.isLoading && viewModel.searchResults.isEmpty {
                    loadingView
                } else if !viewModel.searchResults.isEmpty {
                    searchResultsList
                } else if !viewModel.searchQuery.isEmpty {
                    noResultsView
                } else {
                    featuredContent
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if viewModel.languages.isEmpty {
                    viewModel.loadLanguages()
                }
                if viewModel.featuredExpressions.isEmpty {
                    viewModel.loadFeaturedExpressions()
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(.secondary)

            TextField("Search", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.body)

            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.searchQuery = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.08))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var featuredContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Featured Expressions")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ForEach(0..<5) { _ in
                            SkeletonCard()
                        }
                    }
                    .padding(.horizontal, 16)
                } else if viewModel.featuredExpressions.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.featuredExpressions) { expression in
                            NavigationLink(
                                destination: ExpressionDetailView(expression: expression)
                            ) {
                                ExpressionCard(expression: expression)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.searchResults) { expression in
                    NavigationLink(
                        destination: ExpressionDetailView(expression: expression)
                    ) {
                        ExpressionCard(expression: expression)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Results")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
        .padding(.top, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Start Exploring")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            Text("Search for expressions or add your own")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
        .padding(.top, 60)
    }
}

struct ExpressionCard: View {
    let expression: LMLexiconExpression

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(expression.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if let region = expression.regionName {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(region)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Text(expression.languageCode.uppercased())
                .font(.caption2)
                .fontWeight(.heavy)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding(16)
        .frame(minHeight: 80)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

struct SkeletonCard: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 14)
                    .frame(width: 80)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(0.1))
                .frame(width: 40)
        }
        .padding(16)
        .frame(height: 80)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
    }
}
