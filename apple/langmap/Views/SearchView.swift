import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.accentColor)

                    TextField("search_placeholder".localized, text: $viewModel.searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: viewModel.searchQuery) { _, _ in
                            viewModel.search()
                        }

                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .glassCardStyle()
                .padding()

                Divider()

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

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("no_results".localized)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("start_typing".localized)
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
            }
            .navigationTitle("nav_search".localized)
            .onAppear {
                if viewModel.languages.isEmpty {
                    viewModel.loadLanguages()
                }
            }
        }
    }
}

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
