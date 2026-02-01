import SwiftUI

struct ExpressionDetailView: View {
    let expression: LMLexiconExpression
    @State private var associations: [LMLexiconExpression] = []
    @State private var isLoadingAssociations = false
    @State private var errorMessage = ""
    @State private var showingAssociationSearch = false
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Main Header Card
                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        HStack {
                            Text(expression.text)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .lineLimit(2)

                            Spacer()

                            if isRefreshing {
                                ProgressView()
                                    .frame(width: 20, height: 20)
                            } else {
                                Text(expression.languageCode.uppercased())
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.heavy)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.primaryGradient)
                                    .foregroundColor(.white)
                                    .cornerRadius(AppRadius.small)
                            }
                        }

                        if let region = expression.regionName {
                            Label(region, systemImage: "mappin.and.ellipse")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Content Sections
                Group {
                    if let origin = expression.origin, !origin.isEmpty {
                        DetailSection(
                            title: "origin".localized,
                            content: origin,
                            icon: "text.book.closed"
                        )
                    }

                    if let usage = expression.usage, !usage.isEmpty {
                        DetailSection(
                            title: "usage".localized,
                            content: usage,
                            icon: "quote.bubble"
                        )
                    }
                }

                Divider()

                // Associations Section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(alignment: .top) {
                        Text("associated_expressions".localized)
                            .font(.title3)
                            .fontWeight(.bold)

                        Spacer()

                        Button(action: {
                            showingAssociationSearch = true
                        }) {
                            Text("add_association".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                    }

                    if isLoadingAssociations {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if associations.isEmpty {
                        Text("no_associated".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(spacing: 4) {
                            ForEach(associations) { assoc in
                                if assoc.id != expression.id {
                                    NavigationLink(destination: ExpressionDetailView(expression: assoc)) {
                                        ExpressionCardView(expression: assoc, compact: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("metadata".localized)
                        .font(.headline)

                    HStack {
                        Text("added_on".localized + ":")
                        Spacer()
                        Text(formatDate(expression.createdAt))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if let source = expression.sourceType {
                        HStack {
                            Text("source".localized + ":")
                            Spacer()
                            Text(source)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(AppSpacing.md)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(AppRadius.medium)
            }
            .padding(AppSpacing.lg)
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    hideKeyboard()
                }
        )
        .navigationTitle("details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $showingAssociationSearch) {
            SearchAssociationSheet(
                isPresented: $showingAssociationSearch,
                currentMeaningId: expression.meaningId ?? expression.id,
                selectedExpression: { selectedExpression in
                    handleAssociatedExpression(selectedExpression)
                }
            )
        }
        .onAppear {
            Task { @MainActor in
                ViewHistoryManager.shared.addToHistory(expression)
            }
            loadAssociations()
        }
    }

    private func refreshData() async {
        isRefreshing = true
        await loadAssociations()
        isRefreshing = false
    }

    private func handleAssociatedExpression(_ selectedExpr: LMLexiconExpression) {
        Task {
            do {
                // 场景1：当前词句有 meaning_id，搜索到的词句有/无 meaning_id → 更新搜索到的词句
                // 场景2：当前词句没有 meaning_id，搜索到的词句有 meaning_id → 更新当前词句
                // 场景3：两个都没有 meaning_id → 更新搜索到的词句

                var endpoint: String
                var requestBody: [String: Any] = [:]

                if expression.meaningId != nil {
                    // 场景1：当前词句有 meaning_id，更新搜索到的词句
                    endpoint = "/expressions/\(selectedExpr.id)"
                    requestBody["meaning_id"] = expression.meaningId!
                    print("📝 场景1：更新搜索到的词句，meaning_id=\(expression.meaningId!)")
                } else if selectedExpr.meaningId != nil {
                    // 场景2：搜索到的词句有 meaning_id，更新当前词句
                    endpoint = "/expressions/\(expression.id)"
                    requestBody["meaning_id"] = selectedExpr.meaningId!
                    print("📝 场景2：更新当前词句，meaning_id=\(selectedExpr.meaningId!)")
                } else {
                    // 场景3：两个都没有 meaning_id，更新搜索到的词句
                    endpoint = "/expressions/\(selectedExpr.id)"
                    requestBody["meaning_id"] = expression.id
                    print("📝 场景3：更新搜索到的词句，meaning_id=\(expression.id)")
                }

                print("📝 Patch request: endpoint=\(endpoint), body=\(requestBody)")

                let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

                var request = NetworkService.shared.createRequest(
                    endpoint: endpoint,
                    method: "PATCH"
                )
                request.httpBody = jsonData

                let _: LMLexiconExpression = try await NetworkService.shared.performRequest(
                    request,
                    responseType: LMLexiconExpression.self
                )

                print("✅ Association updated successfully")

                await MainActor.run {
                    loadAssociations()
                }
            } catch {
                print("❌ Failed to update association: \(error)")
                print("Error details: \(error.localizedDescription)")
            }
        }
    }

    private func loadAssociations() {
        guard expression.meaningId != nil else { return }

        isLoadingAssociations = true
        Task {
            do {
                let endpoint = "/expressions/\(expression.id)/translations"
                let request = NetworkService.shared.createRequest(endpoint: endpoint)
                let response: [LMLexiconExpression] = try await NetworkService.shared
                    .performRequest(request, responseType: [LMLexiconExpression].self)

                await MainActor.run {
                    self.associations = response
                    self.isLoadingAssociations = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoadingAssociations = false
                }
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.accentColor)

            Text(content)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(AppRadius.large)
    }
}
