import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("welcome_title".localized)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("welcome_subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    if !viewModel.languages.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("learning_lang".localized)
                                .font(.headline)
                                .padding(.horizontal)

                            Picker("language".localized, selection: $viewModel.selectedLanguage) {
                                ForEach(viewModel.languages) { language in
                                    Text(language.nativeName ?? language.name).tag(
                                        language as LMLexiconLanguage?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .onChange(of: viewModel.selectedLanguage) { _, _ in
                                viewModel.loadFeaturedExpressions()
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        Text("featured_expressions".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if viewModel.featuredExpressions.isEmpty {
                            Text("no_results".localized)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            VStack(spacing: 15) {
                                ForEach(viewModel.featuredExpressions) { expression in
                                    NavigationLink(
                                        destination: ExpressionDetailView(expression: expression)
                                    ) {
                                        ExpressionCardView(expression: expression)
                                    }
                                }
                            }
                            .padding(.horizontal)
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
