import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search expressions...", text: $viewModel.searchQuery)
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
                .background(Color(UIColor.systemBackground))

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
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty {
                    Text("Start typing to search")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.searchResults) { expression in
                        NavigationLink(destination: ExpressionDetailView(expression: expression)) {
                            ExpressionCardView(expression: expression)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Search")
            .onAppear {
                if viewModel.languages.isEmpty {
                    viewModel.loadLanguages()
                }
            }
        }
    }
}

struct LanguageFilterView: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(language.nativeName ?? language.name)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}
