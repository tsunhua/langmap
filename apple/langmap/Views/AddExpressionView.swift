import SwiftUI

struct AddExpressionView: View {
    var body: some View {
        NavigationView {
            AddExpressionSheet(isPresented: .constant(false))
        }
    }
}
