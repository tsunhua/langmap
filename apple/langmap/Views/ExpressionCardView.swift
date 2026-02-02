import SwiftUI

struct ExpressionCardView: View {
    let expression: LMLexiconExpression
    let languages: [LMLexiconLanguage]?
    var compact: Bool = false

    private var languageName: String {
        guard let languages = languages else {
            return expression.languageCode.uppercased()
        }
        if let language = languages.first(where: { $0.code == expression.languageCode }) {
            return language.name
        }
        return expression.languageCode.uppercased()
    }

    var body: some View {
        if compact {
            // Compact style for lists
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(expression.text)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(languageName)
                            .font(.caption2)
                            .foregroundColor(.blue)

                        if let region = expression.regionName {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(region)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
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
        } else {
            // Full style for main cards
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expression.text)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if let meaningId = expression.meaningId, meaningId != 0 {
                        Text("\(meaningId)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(languageName)
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.heavy)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .glassCardStyle()
            .padding(.horizontal)
        }
    }
}
