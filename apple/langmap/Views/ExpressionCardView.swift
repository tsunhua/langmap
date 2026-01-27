import SwiftUI

struct ExpressionCardView: View {
    let expression: Expression

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(expression.phrase)
                .font(.headline)

            Text(expression.translation)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let language = expression.language {
                HStack {
                    Image(systemName: "globe")
                        .font(.caption)
                    Text(language.nativeName ?? language.name)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
