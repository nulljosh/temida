import SwiftUI

struct DocumentsTabView: View {
    @State private var query = ""
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    #if os(iOS)
                    NavigationLink {
                        CaseLawView()
                    } label: {
                        Label("Search case law", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    #endif
                    DocumentsView(query: query)
                }
                .padding(.horizontal, 16).padding(.bottom, 32)
            }
            .navigationTitle("Files")
            .searchable(text: $query, prompt: "Search files")
        }
    }
}
