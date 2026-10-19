import SwiftUI

struct CaseTabView: View {
    @Environment(Store.self) private var store
    @State private var expandedGround: String? = nil

    private var facts:     [CaseFact] {
        switch store.activeCase { case .rcmp: return caseFacts; case .family: return familyCaseFacts; case .muni: return muniCaseFacts; case .bylaw: return bylawCaseFacts }
    }
    private var witnesses: [Witness] {
        switch store.activeCase { case .rcmp: return caseWitnesses; case .family: return familyCaseWitnesses; case .muni: return muniCaseWitnesses; case .bylaw: return bylawCaseWitnesses }
    }
    private var grounds:   [Ground] {
        switch store.activeCase { case .rcmp: return caseGrounds; case .family: return familyCaseGrounds; case .muni: return muniCaseGrounds; case .bylaw: return bylawCaseGrounds }
    }
    private var navTitle: String { caseFragments.isEmpty && !briefTitle.isEmpty ? briefTitle : store.activeCase.title } // the owner keeps the case number

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    CoverHeaderView()

                    // Limitation / notice banner
                    LimitationBannerView()

                    // Value belt
                    ValueBeltView()

                    // Muni notice card
                    if store.activeCase == .muni {
                        NoticeCardView()
                    }

                    if !facts.isEmpty {
                        section("Facts", roman: "§1", hint: "cover sheet") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(facts) { fact in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(verbatim: fact.key)
                                            .font(.temidaText(13).weight(.medium))
                                            .foregroundStyle(.secondary)
                                        Text(verbatim: fact.value)
                                            .font(.temidaText(13).weight(.semibold))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityElement(children: .combine)
                                    .gridCellColumns(fact.fullWidth ? 2 : 1)
                                    .caseItemMenu(CaseItem(fact))
                                }
                            }
                            .padding(Spacing.mdPlus)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    if !witnesses.isEmpty {
                        section("Witnesses", roman: "§2") {
                            ForEach(witnesses) { WitnessCardView(witness: $0).caseItemMenu(CaseItem($0)) }
                        }
                    }

                    if !grounds.isEmpty {
                        section("Legal grounds", roman: "§3", hint: "tap to expand") {
                            VStack(spacing: 6) {
                                ForEach(grounds) { GroundRowView(ground: $0, expandedId: $expandedGround).caseItemMenu(CaseItem($0)) }
                            }
                        }
                    }

                    if store.activeCase == .rcmp {
                        section("Journal", roman: "§4", hint: "supports continuity") {
                            JournalView()
                        }
                    }

                    if facts.isEmpty && witnesses.isEmpty && grounds.isEmpty && store.activeCase.timeline.isEmpty {
                        ContentUnavailableView("Nothing in this brief yet", systemImage: "doc.text",
                            description: Text("Use + to add a fact, a deadline, a witness or a ground."))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle(navTitle)
            .toolbar { ToolbarItem(placement: .primaryAction) { AddToCaseMenu() } }
            .toolbarTitleMenu {
                if CaseID.shown.count > 1 { Picker("Case", selection: Binding(get: { store.activeCase }, set: { store.activeCase = $0 })) { ForEach(CaseID.shown) { Text($0.title).tag($0) } } }
            }
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private func section<C: View>(_ label: LocalizedStringKey, roman: String? = nil, hint: LocalizedStringKey? = nil, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                if let roman { Text(verbatim: roman).font(.temidaText(13).weight(.medium)).foregroundStyle(Color.briefDanger) }
                Text(label).font(.temidaText(13).weight(.bold)).foregroundStyle(.secondary).accessibilityAddTraits(.isHeader)
                if let hint { Spacer(); Text(hint).font(.temidaText(13)).foregroundStyle(.tertiary) }
            }
            .padding(.horizontal, 4)
            content()
        }
    }
}
