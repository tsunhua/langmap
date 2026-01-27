import SwiftUI

struct ExpressionCardView: View {
    let expression: Expression

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(expression.text)
                .font(.headline)

            Text("")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "globe")
                    .font(.caption)
                Text(expression.languageCode)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
