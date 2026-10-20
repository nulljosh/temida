import SwiftUI

struct SectionCard<Content: View>: View {
    let label: Text
    let content: Content

    /// A fixed heading from the app: looked up in the string catalog.
    init(_ label: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.label = Text(label)
        self.content = content()
    }

    /// A heading that comes from the user's own data: shown exactly as written.
    init(verbatim label: String, @ViewBuilder content: () -> Content) {
        self.label = Text(verbatim: label)
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            label
                .font(.temidaText(13).weight(.bold))
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.mdPlus)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
