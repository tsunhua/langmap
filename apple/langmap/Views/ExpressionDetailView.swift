import SwiftUI

struct ExpressionDetailView: View {
    let expression: Expression

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(expression.phrase)
                    .font(.title)
                    .fontWeight(.bold)

                 VStack(alignment: .leading) {
                    Text("Translation")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(expression.translation)
                        .font(.title2)
                }

                Divider()

                if let origin = expression.origin, !origin.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Origin")
                            .font(.headline)

                        Text(origin)
                            .font(.body)
                    }
                }

                if let usage = expression.usage, !usage.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Usage")
                            .font(.headline)

                        Text(usage)
                            .font(.body)
                    }
                }

                Divider()

                HStack {
                    Text("Added on")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatDate(expression.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Expression")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return dateString
    }
}
