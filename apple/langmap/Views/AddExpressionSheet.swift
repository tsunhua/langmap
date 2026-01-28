import SwiftUI

struct AddExpressionSheet: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = AddExpressionViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                // Expression Text
                Section {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Expression")
                            .font(.headline)

                        TextEditor(text: $viewModel.expressionText)
                            .frame(minHeight: 60, maxHeight: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.small)
                                    .stroke(viewModel.expressionTextError != nil ? Color.red : Color.clear, lineWidth: 1)
                            )

                        if let error = viewModel.expressionTextError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        HStack {
                            Spacer()
                            Text("\(viewModel.expressionText.count)/500")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Language Selection
                Section {
                    Picker("Language", selection: $viewModel.selectedLanguage) {
                        ForEach(viewModel.languages) { language in
                            Text("\(language.nativeName ?? language.name) (\(language.code))")
                                .tag(language as LMLexiconLanguage?)
                        }
                    }
                    .pickerStyle(.menu)

                    if viewModel.selectedLanguage != nil {
                        Text("remembered_last_selection".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Region
                Section(header: Text("Region").font(.headline)) {
                    if viewModel.isLocating {
                        HStack {
                            ProgressView()
                            Text("locating".localized)
                        }
                    } else if !viewModel.region.isEmpty {
                        HStack {
                            Text(viewModel.region)
                            Spacer()
                            Button(action: viewModel.requestLocation) {
                                Image(systemName: "arrow.clockwise")
                            }
                            Button(action: { viewModel.region = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        Button(action: viewModel.requestLocation) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Use current location")
                            }
                        }
                    }
                }

                // Tags
                Section(header: Text("Tags (Optional)").font(.headline)) {
                    HStack {
                        TextField("Add tag", text: $viewModel.currentTagInput)
                            .onSubmit {
                                viewModel.addTag()
                            }

                        Button(action: viewModel.addTag) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(viewModel.currentTagInput.isEmpty)
                    }

                    if !viewModel.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.tags, id: \.self) { tag in
                                    TagChip(tag: tag) {
                                        viewModel.removeTag(tag)
                                    }
                                }
                            }
                        }
                    }

                    Text("Max 5 tags, 20 characters each")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Associated Expression
                Section(header: Text("Associate with Expression (Optional)").font(.headline)) {
                    if let associated = viewModel.associatedExpression {
                        VStack {
                            OptimizedExpressionCard(expression: associated)
                            Button(action: viewModel.clearAssociation) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                    Text("Remove association")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            TextField("search_to_associate".localized, text: $searchQuery)
                                .onChange(of: searchQuery) { _, newValue in
                                    viewModel.searchForAssociations(query: newValue)
                                }

                            if !viewModel.searchAssociations.isEmpty {
                                VStack(spacing: AppSpacing.xs) {
                                    ForEach(viewModel.searchAssociations) { expression in
                                        Button(action: {
                                            viewModel.selectAssociation(expression)
                                        }) {
                                            HStack {
                                                Text(expression.text)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                            .padding(AppSpacing.sm)
                                            .background(Color.primary.opacity(0.05))
                                            .cornerRadius(AppRadius.small)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("add_new_expression".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save".localized) {
                        submitExpression()
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    @State private var searchQuery: String = ""

    private func submitExpression() {
        Task {
            do {
                try await viewModel.submit()
                await MainActor.run {
                    isPresented = false
                    // Show success toast
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct TagChip: View {
    let tag: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(tag)
                .font(.caption)

            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(Color.primary.opacity(0.1))
        .cornerRadius(AppRadius.small)
    }
}
