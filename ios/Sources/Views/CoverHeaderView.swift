import SwiftUI

private struct Badge {
    let text: String
    let color: Color
    let tilt: Double
}

struct CoverHeaderView: View {
    @Environment(Store.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: eyebrow.isEmpty ? store.activeCase.rawValue : "\(store.activeCase.rawValue) · \(eyebrow)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            titleText
                .font(.temidaSerif(28))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if !sub.isEmpty {
                Text(sub)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                ForEach(Array(badges.prefix(2).enumerated()), id: \.offset) { _, b in
                    Text(b.text)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(b.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(b.color.opacity(0.1), in: Capsule())
                }
            }

            if !metaRows.isEmpty {
                Divider().padding(.vertical, 4)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), alignment: .leading)], alignment: .leading, spacing: 12) {
                    ForEach(metaRows, id: \.0) { k, v in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(k).font(.caption).foregroundStyle(.secondary)
                            Text(v).font(.subheadline)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    private var titleText: Text {
        let c = frag(store.activeCase).cover
        guard let c else { return Text(verbatim: briefTitle.isEmpty ? store.activeCase.rawValue : briefTitle) }
        return Text(c.l) + Text(verbatim: " v. ").italic().foregroundStyle(Color.secondary) + Text(c.r)
    }

    // Eyebrow and badges ("first|second") come from fragment prose, never from source.
    private var eyebrow: String { frag(store.activeCase).prose["eyebrow"] ?? "" }

    private var sub: String { frag(store.activeCase).blurb }

    private var badges: [Badge] {
        (frag(store.activeCase).prose["badges"] ?? "").split(separator: "|").enumerated().map { i, t in
            Badge(text: String(t), color: i == 0 ? .briefDanger : .briefAccent, tilt: 0)
        }
    }

    private var metaRows: [(String, String)] {
        frag(store.activeCase).meta.map { ($0.k, $0.v) }
    }
}
