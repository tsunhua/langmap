import SwiftUI

struct ExpressionCardView: View {
    let expression: LMLexiconExpression

    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text(expression.text)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if let meaning = expression.meaningId != 0 ? "\(expression.meaningId)" : nil {
                    Text(meaning)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(expression.languageCode.uppercased())
                .font(.system(.caption2, design: .monospaced))
                .fontWeight(.heavy)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.primaryGradient)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .glassCardStyle()
        .padding(.horizontal)
    }
}
