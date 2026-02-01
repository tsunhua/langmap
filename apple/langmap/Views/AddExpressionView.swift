import SwiftUI

struct AddExpressionView: View {
    @StateObject private var viewModel = AddExpressionViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSuccess = false
    @State private var showingAssociationSearch = false
    @State private var showingLoginSheet = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case expressionText
        case tags
    }

    private var isAuthenticated: Bool {
        NetworkService.shared.authToken != nil
    }

    private var canSubmit: Bool {
        viewModel.isValid && !viewModel.isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    languageRow
                    expressionSection
                    tagsSection
                    regionSection
                    associationSection
                }
                .padding(AppSpacing.lg)
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        hideKeyboard()
                    }
            )
            .navigationTitle("add_expression".localized)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: submitExpression) {
                        HStack(spacing: AppSpacing.sm) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text("save".localized)
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                    .disabled(!canSubmit || viewModel.isLoading)
                    .opacity(canSubmit && !viewModel.isLoading ? 1 : 0.5)
                }
            }
            .alert("success".localized, isPresented: $showingSuccess) {
                Button("OK") {}
            } message: {
                Text("expression_added".localized)
            }
            .alert("error".localized, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingLoginSheet) {
                LoginView()
            }
            .onAppear {
                viewModel.restorePreferences()
            }
        }
    }

    // MARK: - Language Row

    private var languageRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("language".localized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "globe")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.languages.isEmpty {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Picker("", selection: $viewModel.selectedLanguageId) {
                        Text("select_language".localized).tag(nil as Int?)
                        ForEach(viewModel.languages) { language in
                            Text(language.name).tag(language.id as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                Spacer()
            }
            .padding(AppSpacing.md)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(AppRadius.medium)
        }
    }

    // MARK: - Expression Section

    private var expressionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("expression".localized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ZStack(alignment: .topLeading) {
                if viewModel.expressionText.isEmpty {
                    Text("enter_expression".localized)
                        .foregroundColor(Color(uiColor: .placeholderText))
                        .font(.body)
                        .padding(AppSpacing.md)
                }

                TextEditor(text: $viewModel.expressionText)
                    .focused($focusedField, equals: .expressionText)
                    .frame(height: 100)
                    .font(.body)
                    .lineSpacing(1.5)
                    .scrollContentBackground(.hidden)
                    .padding(AppSpacing.md)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(AppRadius.medium)
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(
                        viewModel.expressionTextError != nil ? Color.red.opacity(0.6) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: viewModel.expressionTextError != nil)

            HStack {
                if viewModel.expressionTextError != nil {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text(viewModel.expressionTextError!)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                Text("\(viewModel.expressionText.count)/500")
                    .font(.caption)
                    .foregroundColor(
                        viewModel.expressionText.count > 450
                            ? viewModel.expressionText.count >= 500 ? .red : .orange
                            : .secondary
                    )
                    .fontWeight(.medium)
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tags_optional".localized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if !viewModel.tags.isEmpty {
                FlowLayout(spacing: AppSpacing.sm) {
                    ForEach(viewModel.tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.removeTag(tag)
                            }
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "tag.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("add_tag".localized, text: $viewModel.currentTagInput)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($focusedField, equals: .tags)
                    .submitLabel(.done)
                    .onSubmit {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.addTag()
                        }
                    }

                if !viewModel.currentTagInput.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.addTag()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(AppSpacing.md)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(AppRadius.medium)

            Text("max_tags_hint".localized)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Region Section

    private var regionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("region".localized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("enter_region_or_location".localized, text: $viewModel.region)
                    .textFieldStyle(.plain)
                    .font(.body)

                Button(action: {
                    viewModel.requestLocation()
                }) {
                    if viewModel.isLocating {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.blue)
                    } else {
                        Image(systemName: "location.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .frame(minWidth: 44, minHeight: 44)
                .disabled(viewModel.isLocating)

                if !viewModel.region.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.region = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(AppSpacing.md)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(AppRadius.medium)
            .animation(.easeInOut(duration: 0.2), value: viewModel.region.isEmpty)
        }
    }

    // MARK: - Association Section

    private var associationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("associate_with_expression_optional".localized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if let associated = viewModel.associatedExpression {
                VStack(spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "link.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(associated.text)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.clearAssociation()
                            }
                        }) {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "trash.fill")
                                    .font(.caption)
                                Text("delete".localized)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(AppRadius.small)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                    .padding(AppSpacing.md)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(AppRadius.medium)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: {
                    showingAssociationSearch = true
                }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("search_expressions".localized)
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(AppRadius.medium)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAssociationSearch) {
            SearchAssociationSheet(isPresented: $showingAssociationSearch) { expression in
                viewModel.associatedExpression = expression
            }
        }
    }


    private func submitExpression() {
        if !isAuthenticated {
            showingLoginSheet = true
            return
        }

        Task {
            do {
                try await viewModel.submit()
                await MainActor.run {
                    alertMessage = "expression_added".localized
                    showingSuccess = true
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

// MARK: - Tag Chip

struct TagChip: View {
    let tag: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)

            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(AppRadius.small)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.small)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .frame(minHeight: 32)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ())
        -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: height > 0 ? height : 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ())
    {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for (_, subview) in row.subviews.enumerated() {
                subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: .unspecified
                )
                x += subview.dimensions(in: .unspecified).width + spacing
            }
            y += row.height + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(subviews: [])
        var currentX: CGFloat = 0
        let maxWidth = proposal.width ?? 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && !currentRow.subviews.isEmpty {
                rows.append(currentRow)
                currentRow = Row(subviews: [])
                currentX = 0
            }

            currentRow.subviews.append(subview)
            currentRow.height = max(currentRow.height, size.height)
            currentX += size.width + spacing
        }

        if !currentRow.subviews.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    struct Row {
        var subviews: [LayoutSubview]
        var height: CGFloat = 0
    }
}
