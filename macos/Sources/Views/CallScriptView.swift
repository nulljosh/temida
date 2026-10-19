import SwiftUI

struct CallScriptView: View {
    let text: String
    let title: LocalizedStringKey
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.temidaText(13).weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                HStack(spacing: 8) {
                    Button(copied ? LocalizedStringKey("Copied") : LocalizedStringKey("Copy")) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                        copied = true
                        Task { try? await Task.sleep(for: .seconds(2)); copied = false }
                    }
                    .font(.temidaText(13).weight(.semibold))
                    .foregroundStyle(copied ? .briefGreen : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().stroke(copied ? Color.briefGreen : Color.secondary.opacity(0.4))
                    )

                    ShareLink(item: text) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.temidaText(13))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Share")
                }
            }
            ScrollView {
                Text(verbatim: text)
                    .font(.temidaText(14))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 220)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
