import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @ObservedObject private var viewHistoryManager = ViewHistoryManager.shared
    @StateObject private var recentExpressionsManager = RecentlyExpressionsManager.shared
    @State private var showingClearHistoryAlert = false
    @State private var showingHomeSheet = false
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

                // Content
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.searchQuery.isEmpty {
                    // Search Results
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
                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(viewModel.searchResults) { (expression: LMLexiconExpression) in
                                    NavigationLink(destination: ExpressionDetailView(expression: expression)) {
                                        ExpressionCardView(expression: expression, languages: viewModel.languages, compact: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { _ in
                                    hideKeyboard()
                                }
                        )
                    }
                  } else {
                      // History
                      ScrollView {
                          VStack(spacing: 20) {
                              // Recently Viewed
                              if viewHistoryManager.hasHistory {
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
                                  VStack(spacing: 4) {
                                      ForEach(viewHistoryManager.getRecentViewed()) { item in
                                          ViewHistoryCard(
                                              item: item,
                                              expression: createExpressionFromHistory(item),
                                              languages: viewModel.languages,
                                              onDelete: {
                                                  viewHistoryManager.removeFromHistory(item)
                                              }
                                          )
                                      }
                                  }
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
                                  }
                                  .frame(maxWidth: .infinity, maxHeight: .infinity)
                              }

                              // Recently Added
                              HStack {
                                  Text("recently_added".localized)
                                      .font(.headline)
                                      .foregroundColor(.primary)
                                  Spacer()
                              }
                              .padding(.horizontal)

                                  if recentExpressionsManager.isLoading {
                                      ProgressView()
                                          .frame(maxWidth: .infinity, maxHeight: 150)
                                  } else if !recentExpressionsManager.recentExpressions.isEmpty {
                                       VStack(spacing: 4) {
                                           ForEach(recentExpressionsManager.recentExpressions.prefix(5)) { expression in
                                               NavigationLink(destination: ExpressionDetailView(expression: expression)) {
                                                   ExpressionCardView(expression: expression, languages: viewModel.languages, compact: true)
                                               }
                                               .buttonStyle(.plain)
                                           }
                                       }
                                    }
                            }
                            .padding()
                        }
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { _ in
                                    hideKeyboard()
                                }
                        )
                    }
              }
             .navigationTitle("nav_search".localized)
             .onAppear {
                 if viewModel.languages.isEmpty {
                     viewModel.loadLanguages()
                 }
                 if recentExpressionsManager.recentExpressions.isEmpty {
                     recentExpressionsManager.loadRecentExpressions()
                 }
             }
            .onReceive(viewHistoryManager.$viewHistory) { _ in
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
                        ? AnyShapeStyle(AppTheme.primaryColor)
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
    let languages: [LMLexiconLanguage]
    let onDelete: () -> Void

    private var languageName: String {
        if let language = languages.first(where: { $0.code == item.languageCode }) {
            return language.name
        }
        return item.languageCode.uppercased()
    }

    var body: some View {
        HStack(spacing: 10) {
            NavigationLink(destination: ExpressionDetailView(expression: expression)) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.text)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(languageName)
                                .font(.caption2)
                                .foregroundColor(.blue)

                            if let region = item.regionName {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(region)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(item.relativeTime)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.02))
        .overlay(
            Rectangle()
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}
