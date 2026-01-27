import SwiftUI

struct CreateCollectionSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    @Binding var description: String
    let onCreate: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Collection Info")) {
                    TextField("Name", text: $name)

                    TextField("Description (optional)", text: $description)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onCreate()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
