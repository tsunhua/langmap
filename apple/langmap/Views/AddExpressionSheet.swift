import SwiftUI

struct AddExpressionSheet: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = AddExpressionViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Language Selection
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Language")
                                .font(.headline)
                            Spacer()
                            
                            if viewModel.languages.isEmpty {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Picker("", selection: $viewModel.selectedLanguage) {
                                    if viewModel.selectedLanguage == nil {
                                        Text("Select Language").tag(nil as LMLexiconLanguage?)
                                    }
                                    ForEach(viewModel.languages) { language in
                                        Text(
                                            "\(language.nativeName ?? language.name) (\(language.code))"
                                        )
                                        .tag(language as LMLexiconLanguage?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }
                        
                        if viewModel.selectedLanguage != nil {
                            Text("remembered_last_selection".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .glassCardStyle()
                    
                    // Expression Text
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Expression")
                            .font(.headline)
                        
                        TextEditor(text: $viewModel.expressionText)
                            .frame(minHeight: 80, maxHeight: 150)
                            .background(Color.primary.opacity(0.03))
                            .cornerRadius(AppRadius.small)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.small)
                                    .stroke(
                                        viewModel.expressionTextError != nil
                                        ? Color.red : Color.clear, lineWidth: 1)
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
                    .glassCardStyle()
                    
                    // Associated Expression
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Associate with Expression (Optional)")
                            .font(.headline)
                        
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
                                .padding(.top, AppSpacing.sm)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                TextField("search_to_associate".localized, text: $searchQuery)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(AppSpacing.sm)
                                    .background(Color.primary.opacity(0.05))
                                    .cornerRadius(AppRadius.small)
                                    .onChange(of: searchQuery) { _, newValue in
                                        viewModel.searchForAssociations(query: newValue)
                                    }
                                
                                if !searchQuery.isEmpty {
                                    if viewModel.isLoading {
                                        HStack {
                                            ProgressView()
                                                .controlSize(.small)
                                            Text("Searching...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, AppSpacing.xs)
                                    } else if !viewModel.searchAssociations.isEmpty {
                                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                            Text("\(viewModel.searchAssociations.count) results")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.bottom, AppSpacing.xs)
                                            
                                            ScrollView {
                                                VStack(spacing: AppSpacing.xs) {
                                                    ForEach(viewModel.searchAssociations) {
                                                        expression in
                                                        Button(action: {
                                                            viewModel.selectAssociation(expression)
                                                            searchQuery = ""
                                                        }) {
                                                            HStack {
                                                                Text(expression.text)
                                                                    .foregroundColor(.primary)
                                                                    .multilineTextAlignment(
                                                                        .leading)
                                                                Spacer()
                                                                Image(
                                                                    systemName: "plus.circle.fill"
                                                                )
                                                                .foregroundColor(.blue)
                                                            }
                                                            .padding(AppSpacing.sm)
                                                            .background(Color.blue.opacity(0.1))
                                                            .cornerRadius(AppRadius.small)
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                }
                                            }
                                            .frame(maxHeight: 200)
                                        }
                                    } else {
                                        Text("No results found")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, AppSpacing.xs)
                                    }
                                }
                            }
                        }
                    }
                    .glassCardStyle()
                    
                    // Region
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Region")
                            .font(.headline)
                        
                        HStack {
                            TextField("Enter region or use location", text: $viewModel.region)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(AppSpacing.sm)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(AppRadius.small)
                                .disabled(viewModel.isLocating)
                            
                            Button(action: viewModel.requestLocation) {
                                if viewModel.isLocating {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "location.fill")
                                }
                            }
                            .disabled(viewModel.isLocating)
                            
                            if !viewModel.region.isEmpty {
                                Button(action: { viewModel.region = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .glassCardStyle()
                    
                    // Tags
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Tags (Optional)")
                            .font(.headline)
                        
                        HStack {
                            TextField("Add tag", text: $viewModel.currentTagInput)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(AppSpacing.sm)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(AppRadius.small)
                                .onSubmit {
                                    viewModel.addTag()
                                }
                            
                            Button(action: viewModel.addTag) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
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
                    .glassCardStyle()
                }
                .padding()
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
                    // Don't close the sheet, show success message instead
                    alertMessage = "Expression added successfully! You can add another one."
                    showingAlert = true
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
}
