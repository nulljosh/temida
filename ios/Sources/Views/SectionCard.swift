import SwiftUI

struct SectionCard<Content: View>: View {
    let label: Text
    let roman: String?
    let hint: Text?
    let content: Content

    /// A fixed heading from the app: looked up in the string catalog.
    init(_ label: LocalizedStringKey, roman: String? = nil, hint: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content) {
        self.label = Text(label)
        self.roman = roman
        self.hint = hint.map { Text($0) }
        self.content = content()
    }

    /// A heading that comes from the user's own data: shown exactly as written.
    init(verbatim label: String, roman: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = Text(verbatim: label)
        self.roman = roman
        self.hint = nil
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                if let roman {
                    Text(verbatim: roman)
                        .font(.temidaText(13).weight(.medium))
                        .foregroundStyle(Color.briefDanger)
                }
                label
                    .font(.temidaText(13).weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                if let hint {
                    Spacer()
                    hint
                        .font(.temidaText(13))
                        .foregroundStyle(.tertiary)
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading) // every card full width, not only ones with a hint
        .padding(Spacing.mdPlus)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
