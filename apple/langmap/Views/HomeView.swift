import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !viewModel.languages.isEmpty {
                        Picker("Language", selection: $viewModel.selectedLanguage) {
                            ForEach(viewModel.languages) { language in
                                Text(language.nativeName ?? language.name).tag(language as Language?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                        .onChange(of: viewModel.selectedLanguage) { _, _ in
                            viewModel.loadFeaturedExpressions()
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Featured Expressions")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if viewModel.featuredExpressions.isEmpty {
                            Text("No expressions found")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(viewModel.featuredExpressions) { expression in
                                NavigationLink(destination: ExpressionDetailView(expression: expression)) {
                                    ExpressionCardView(expression: expression)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("LangMap")
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
}
