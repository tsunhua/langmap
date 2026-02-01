import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @ObservedObject private var viewHistoryManager = ViewHistoryManager.shared
    @State private var showingClearHistoryAlert = false
    @FocusState private var isSearchFieldFocused: Bool
    @State private var refreshID = UUID()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.accentColor)

                    TextField("search_placeholder".localized, text: $viewModel.searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            isSearchFieldFocused = false
                        }
                        .onChange(of: viewModel.searchQuery) { _, _ in
                            viewModel.search()
                        }

                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { 
                            viewModel.searchQuery = ""
                            isSearchFieldFocused = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .glassCardStyle()
                .padding()

                Divider()

                // Language Filter
                if !viewModel.languages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.languages) { language in
                                LanguageFilterView(
                                    language: language,
                                    isSelected: viewModel.selectedLanguage?.id == language.id
                                ) {
                                    withAnimation {
                                        if viewModel.selectedLanguage?.id == language.id {
                                            viewModel.selectedLanguage = nil
                                        } else {
                                            viewModel.selectedLanguage = language
                                        }
                                        viewModel.search()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }

                // Content
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if isSearchFieldFocused || viewModel.searchQuery.isEmpty {
                        // Show history when search field is focused or query is empty
                        viewHistoryView
                            .id(refreshID)
                    } else if !viewModel.searchQuery.isEmpty {
                        if viewModel.searchResults.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                Text("no_results".localized)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(viewModel.searchResults) { (expression: LMLexiconExpression) in
                                    NavigationLink(
                                        destination: ExpressionDetailView(expression: expression)
                                    ) {
                                        ExpressionCardView(expression: expression)
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    } else {
                        // Fallback - view history
                        viewHistoryView
                            .id(refreshID)
                    }
                }
            }
            .navigationTitle("nav_search".localized)
            .onAppear {
                if viewModel.languages.isEmpty {
                    viewModel.loadLanguages()
                }
            }
            .onReceive(viewHistoryManager.$viewHistory) { newHistory in
                refreshID = UUID()
            }
            .alert("clear_history".localized, isPresented: $showingClearHistoryAlert) {
                Button("cancel".localized, role: .cancel) {}
                Button("clear".localized, role: .destructive) {
                    viewHistoryManager.clearAllHistory()
                }
            } message: {
                Text("clear_history_confirm".localized)
            }
        }
    }

    // MARK: - Helper Methods

    private func createExpressionFromHistory(_ item: ViewHistoryItem) -> LMLexiconExpression {
        return LMLexiconExpression(
            id: item.expressionId,
            text: item.text,
            meaningId: item.meaningId,
            audioUrl: nil,
            languageCode: item.languageCode,
            regionCode: nil,
            regionName: item.regionName,
            regionLatitude: nil,
            regionLongitude: nil,
            tags: nil,
            sourceType: nil,
            sourceRef: nil,
            reviewStatus: nil,
            createdBy: nil,
            createdAt: "",
            updatedAt: "",
            origin: nil,
            usage: nil
        )
    }

    // MARK: - View History

    @ViewBuilder
    private var viewHistoryView: some View {
        VStack(spacing: 16) {
            if viewHistoryManager.hasHistory {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Text("recently_viewed".localized)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: {
                            showingClearHistoryAlert = true
                        }) {
                            Text("clear_all".localized)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)

                    // History Items
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewHistoryManager.getRecentViewed()) { item in
                                ViewHistoryCard(
                                    item: item,
                                    expression: createExpressionFromHistory(item),
                                    onDelete: {
                                        viewHistoryManager.removeFromHistory(item)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            } else {
                // Empty State - No history yet
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("no_view_history".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .id("viewHistoryView")
    }
}

// MARK: - Language Filter View

struct LanguageFilterView: View {
    let language: LMLexiconLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(language.nativeName ?? language.name)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? AnyShapeStyle(AppTheme.primaryGradient)
                        : AnyShapeStyle(Color.primary.opacity(0.05))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(
                    color: isSelected ? Color.accentColor.opacity(0.3) : Color.clear, radius: 5,
                    x: 0, y: 3)
        }
    }
}

// MARK: - View History Card

struct ViewHistoryCard: View {
    let item: ViewHistoryItem
    let expression: LMLexiconExpression
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: ExpressionDetailView(expression: expression)) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.text)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            // Language badge
                            Text(item.languageCode.uppercased())
                                .font(.caption2)
                                .fontWeight(.heavy)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(.capsule)

                            // Region
                            if let region = item.regionName {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.caption2)
                                    Text(region)
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Time
                            Text(item.relativeTime)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .clipShape(.rect(cornerRadius: 12))
    }
}
