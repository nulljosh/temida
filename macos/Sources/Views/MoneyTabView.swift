import SwiftUI

struct MoneyTabView: View {
    @Environment(Store.self) private var store
    @State private var barsVisible = false
    // Column widths grow with the text size so the table wraps instead of clipping.
    @ScaledMetric(relativeTo: .footnote) private var rangeWidth: CGFloat = 90
    @ScaledMetric(relativeTo: .footnote) private var noteWidth: CGFloat = 110

    var scenarios: [Scenario] {
        switch store.activeCase { case .rcmp: return caseScenarios; case .family: return familyCaseScenarios; case .muni: return muniCaseScenarios; case .bylaw: return bylawCaseScenarios }
    }
    var activeDamageHeads: [DamageHead] {
        switch store.activeCase { case .rcmp: return damageHeads; case .family: return familyDamageHeads; case .muni: return muniDamageHeads; case .bylaw: return bylawDamageHeads }
    }

    // Totals come from the heads, as on the web; nothing typed in per case.
    private var stackLow: Double { activeDamageHeads.reduce(0) { $0 + $1.low } }
    private var stackHigh: Double { activeDamageHeads.reduce(0) { $0 + $1.high } }

    private var rcmp: Bool { store.activeCase == .rcmp }
    private var muni: Bool { store.activeCase == .muni }

    private var moneyEmpty: Bool { scenarios.isEmpty && activeDamageHeads.isEmpty }
    private var emptyMoney: some View {
        ContentUnavailableView("No money figures yet", systemImage: "chart.bar",
            description: Text("Damages and settlement ranges show here once the brief has them."))
    }

    var body: some View {
        Group { if moneyEmpty { emptyMoney } else { ScrollView {
                VStack(spacing: 22) {

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(scenarios.enumerated()), id: \.element.id) { idx, s in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(s.name).font(.temidaText(13).weight(.semibold))
                                        Text(s.description).font(.temidaText(13)).foregroundStyle(.secondary).lineSpacing(2)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(s.amount).font(.temidaText(14).weight(.bold)).foregroundStyle(s.accentColor)
                                        Text(verbatim: "\(Int(s.probability * 100))%").font(.temidaText(13)).foregroundStyle(.secondary)
                                    }
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.15)).frame(height: 4)
                                        RoundedRectangle(cornerRadius: 2).fill(s.accentColor)
                                            .frame(width: barsVisible ? geo.size.width * s.probability : 0, height: 4)
                                            .animation(.easeOut(duration: 0.9).delay(Double(idx) * 0.12), value: barsVisible)
                                    }
                                }.frame(height: 4)
                                .accessibilityHidden(true)
                            }
                            .accessibilityElement(children: .combine)
                            .padding(.vertical, 14)
                            if idx < scenarios.count - 1 { Divider() }
                        }
                        if !frag(store.activeCase).belt.isEmpty { Text(verbatim: frag(store.activeCase).belt)
                            .font(.temidaText(13))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .padding(.top, 14) }
                    }
                    .padding(18)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .onAppear { barsVisible = true }

                    SectionCard("Per-head damages stack") {
                        VStack(spacing: 0) {
                            HStack { Text("Head").frame(maxWidth:.infinity,alignment:.leading); Text("Range"); Text("Note").frame(width:noteWidth,alignment:.leading) }
                                .font(.temidaText(13)).foregroundStyle(.secondary).padding(.bottom,8)
                            ForEach(activeDamageHeads) { h in
                                HStack(alignment:.top) {
                                    Text(h.head).font(.temidaText(13)).frame(maxWidth:.infinity,alignment:.leading).lineSpacing(2)
                                    Text(h.range).font(.temidaText(13).weight(.semibold)).foregroundStyle(.briefWarn).frame(width:rangeWidth,alignment:.trailing)
                                    Text(verbatim: h.note).font(.temidaText(13)).foregroundStyle(.secondary).frame(width:noteWidth,alignment:.leading)
                                }
                                .padding(.vertical,6)
                                .accessibilityElement(children: .combine)
                                Divider()
                            }
                            if !activeDamageHeads.isEmpty {
                                HStack {
                                    Text(muni ? LocalizedStringKey("Floor") : "Conservative").font(.temidaText(13).weight(.bold))
                                    Spacer()
                                    Text(verbatim: formatRange(low: stackLow, high: stackLow)).font(.temidaText(13).weight(.bold)).foregroundStyle(.briefWarn)
                                }.padding(.top,8)
                                HStack {
                                    Text(muni ? LocalizedStringKey("Ceiling") : "Strong").font(.temidaText(13).weight(.bold))
                                    Spacer()
                                    Text(verbatim: formatRange(low: stackHigh, high: stackHigh)).font(.temidaText(13).weight(.bold)).foregroundStyle(.briefGreen)
                                }
                            }
                        }
                    }

                    if muni {
                        proseCard(frag(.muni).prose["settlesTitle"] ?? "", frag(.muni).prose["settles"])
                    } else if rcmp {
                        if !caseComparables.isEmpty { SectionCard("Comparable cases · Canada") {
                            VStack(spacing: 0) {
                                ForEach(caseComparables) { c in
                                    HStack(alignment: .top, spacing: 10) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(c.label).font(.temidaText(13)).foregroundStyle(c.highlight ? Color.primary : Color.secondary)
                                            if let note = c.note {
                                                Text(note).font(.temidaText(13)).foregroundStyle(.secondary).lineSpacing(2)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(c.award).font(.temidaText(13).weight(.bold))
                                            .foregroundStyle(c.highlight ? Color.briefWarn : Color.secondary).multilineTextAlignment(.trailing)
                                    }
                                    .padding(.vertical, 8)
                                    Divider()
                                }
                            }
                        }}

                        proseCard("Ward framework", frag(.rcmp).prose["ward"])

                        proseCard("Silence premium", frag(.rcmp).prose["silence"])
                    } else {
                        proseCard("Asset enforcement", frag(.family).prose["assets"])

                        proseCard("Limitation strategy", frag(.family).prose["limitation"])
                    }

                    // Rows come from the private fragments row, never from source.
                    if !muni && !frag(store.activeCase).claimed.isEmpty {
                        SectionCard("Damages claimed") {
                            VStack(spacing: 0) {
                                ForEach(frag(store.activeCase).claimed, id: \.self) { row in
                                    HStack(alignment:.top,spacing:12) {
                                        Text(verbatim: row.k).font(.temidaText(13).weight(.semibold)).frame(maxWidth:.infinity,alignment:.leading)
                                        Text(verbatim: row.v).font(.temidaText(13)).foregroundStyle(.secondary).lineSpacing(2)
                                    }.padding(.vertical,11)
                                    .accessibilityElement(children: .combine)
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal,16).padding(.bottom,32)
            }}}
            .navigationTitle("Money")
    }

    @ViewBuilder private func proseCard(_ title: String, _ body: String?) -> some View {
        if let body, !body.isEmpty, !title.isEmpty {
            SectionCard(verbatim: title) {
                Text(verbatim: body).font(.temidaText(13)).foregroundStyle(.secondary).lineSpacing(4)
            }
        }
    }
}
