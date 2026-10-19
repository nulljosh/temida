import SwiftUI

struct DocumentsTabView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                DocumentsView()
            }
            .padding(24)
        }
        .navigationTitle("Documents")
    }
}
