import SwiftUI

struct CollectionDetailView: View {
    let collectionId: Int
    @State private var collection: CollectionDetail?
    @State private var isLoading = true
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let collection = collection {
                List {
                    ForEach(collection.items ?? []) { item in
                        if let expression = item.expression {
                            NavigationLink(
                                destination: ExpressionDetailView(expression: expression)
                            ) {
                                ExpressionCardView(expression: expression)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            } else {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(collection?.name ?? "Collection")
        .onAppear {
            loadCollection()
        }
    }

    private func loadCollection() {
        isLoading = true

        Task {
            do {
                let request = NetworkService.shared.createRequest(
                    endpoint: "/collections/\(collectionId)")
                let response: CollectionDetail = try await NetworkService.shared.performRequest(
                    request, responseType: CollectionDetail.self)

                await MainActor.run {
                    self.collection = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
