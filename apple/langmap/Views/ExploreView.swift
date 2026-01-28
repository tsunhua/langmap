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

                    if !viewModel.searchResults.isEmpty {
                        searchResultsList
                    } else if !viewModel.searchQuery.isEmpty {
                        noResultsView
                    } else {
                        featuredContent
                    }

                    Spacer()

                    // FAB will be overlayed from TabView
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
                // Language Filter
                if !viewModel.languages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            LanguageFilterChip(
                                language: LMLexiconLanguage(
                                    id: 0, code: "all", name: "all_languages".localized,
                                    direction: "ltr", family: nil,
                                    notes: nil, isActive: 1, regionCode: nil,
                                    regionName: nil, regionLatitude: nil,
                                    regionLongitude: nil, createdBy: nil,
                                    createdAt: "", updatedAt: nil
                                ),
                                isSelected: viewModel.selectedLanguage == nil
                            ) {
                                viewModel.selectedLanguage = nil
                                viewModel.loadFeaturedExpressions()
                            }

                            ForEach(viewModel.languages) { language in
                                LanguageFilterChip(
                                    language: language,
                                    isSelected: viewModel.selectedLanguage?.id == language.id
                                ) {
                                    viewModel.toggleLanguage(language)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    .padding(.bottom, AppSpacing.sm)
                }

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
            .padding(.bottom, 80) // Space for FAB
        }
    }

    private var searchResultsList: some View {
        List {
            ForEach(viewModel.searchResults) { expression in
                NavigationLink(
                    destination: ExpressionDetailView(expression: expression)
                ) {
                    OptimizedExpressionCard(expression: expression)
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
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
    @State private var isPressed = false

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
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppTheme.easeInOut, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }, perform: {
            HapticFeedback.light()
        })
    }
}
