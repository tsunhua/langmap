import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    searchBar

                    if viewModel.isLoading && viewModel.searchResults.isEmpty {
                        VStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("searching".localized)
                                .foregroundColor(.secondary)
                                .padding(.top, AppSpacing.md)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !viewModel.searchResults.isEmpty {
                        searchResultsList
                    } else if !viewModel.searchQuery.isEmpty && !viewModel.isLoading {
                        noResultsView
                    } else {
                        featuredContent
                    }

                    Spacer()
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
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.accentColor)

            TextField("search_placeholder".localized, text: $viewModel.searchQuery)
                .textFieldStyle(PlainTextFieldStyle())

            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    withAnimation {
                        viewModel.searchQuery = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(AppRadius.extraLarge)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }
    private var featuredContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Featured Expressions
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("featured_expressions".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, AppSpacing.lg)

                    if viewModel.isLoading {
                        VStack(spacing: AppTheme.cardSpacing) {
                            ForEach(0..<5) { _ in
                                SkeletonView()
                                    .frame(height: 80)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    } else if viewModel.featuredExpressions.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: AppTheme.cardSpacing) {
                            ForEach(viewModel.featuredExpressions) { expression in
                                NavigationLink(
                                    destination: ExpressionDetailView(expression: expression)
                                ) {
                                    OptimizedExpressionCard(expression: expression)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                }
            }
        }
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(viewModel.searchResults) { expression in
                    NavigationLink(
                        destination: ExpressionDetailView(expression: expression)
                    ) {
                        OptimizedExpressionCard(expression: expression)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, 100)
        }
    }

    private var noResultsView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("no_results".localized)
                .font(.title2)
                .foregroundColor(.secondary)

            Text("no_results_hint".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("start_exploring".localized)
                .font(.title2)
                .foregroundColor(.secondary)

            Text("search_or_add_hint".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
    }
}

struct OptimizedExpressionCard: View {
    let expression: LMLexiconExpression

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(expression.text)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if let region = expression.regionName {
                    Text(region)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(expression.languageCode.uppercased())
                .font(.system(.caption2, design: .monospaced))
                .fontWeight(.heavy)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppTheme.primaryGradient)
                .foregroundColor(.white)
                .cornerRadius(AppRadius.small)
        }
        .padding(AppSpacing.lg)
        .frame(minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(AppTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.large)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}
