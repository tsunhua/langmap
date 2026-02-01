import SwiftUI

struct ExpressionDetailView: View {
    let expression: LMLexiconExpression
    @State private var associations: [LMLexiconExpression] = []
    @State private var isLoadingAssociations = false
    @State private var errorMessage = ""

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

                            Text(expression.languageCode.uppercased())
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.heavy)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppTheme.primaryGradient)
                                .foregroundColor(.white)
                                .cornerRadius(AppRadius.small)
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
                    Text("associated_expressions".localized)
                        .font(.title3)
                        .fontWeight(.bold)

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
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
        .navigationTitle("details".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { @MainActor in
                ViewHistoryManager.shared.addToHistory(expression)
            }
            loadAssociations()
        }
    }

    private func loadAssociations() {
        guard expression.meaningId != 0 else { return }

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
