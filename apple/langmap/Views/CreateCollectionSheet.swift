import SwiftUI

struct CreateCollectionSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    @Binding var description: String
    let onCreate: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("details".localized)) {
                    TextField("collection_name".localized, text: $name)

                    TextField("collection_description".localized, text: $description)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("new_collection".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("create".localized) {
                        onCreate()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
