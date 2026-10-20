import SwiftUI

struct DocumentsTabView: View {
    @State private var query = ""
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                DocumentsView(query: query)
            }
            .padding(24)
        }
        .navigationTitle("Documents")
        .searchable(text: $query, prompt: "Search files")
    }
}
