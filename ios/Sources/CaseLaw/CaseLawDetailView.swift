import SwiftUI
import SafariServices

struct CaseLawDetailView: View {
    let result: CanLIICase

    var body: some View {
        SafariView(url: caseURL)
            .navigationTitle(result.title)
    }

    private var caseURL: URL {
        URL(string: "https://www.canlii.org/en/\(result.id)")!
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
