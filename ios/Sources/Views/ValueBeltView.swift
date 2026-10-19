import SwiftUI

struct ValueBeltView: View {
    @Environment(Store.self) private var store

    private struct Col {
        let label: String; let value: String; let sub: String; let highlight: Bool
    }

    /// Columns come from prose["belt"]: "label|value|sub" triples joined by "|"; the middle one is highlighted. No belt, no card.
    private var cols: [Col] {
        guard let raw = frag(store.activeCase).prose["belt"] else { return [] }
        let p = raw.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        return stride(from: 0, to: p.count - 2, by: 3).map { Col(label: p[$0], value: p[$0 + 1], sub: p[$0 + 2], highlight: $0 == 3) }
    }

    var body: some View {
        if cols.isEmpty { EmptyView() } else {
        HStack(spacing: 0) {
            ForEach(Array(cols.enumerated()), id: \.offset) { i, col in
                if i > 0 { Divider() }
                VStack(alignment: .leading, spacing: 4) {
                    Text(col.label)
                        .font(.temidaText(13).weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(col.value)
                        .font(.temidaText(20).weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(col.highlight ? Color.primary : Color.secondary)
                    Text(col.sub)
                        .font(.temidaText(13))
                        .foregroundStyle(.tertiary)
                        .lineSpacing(1.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .accessibilityElement(children: .combine)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
