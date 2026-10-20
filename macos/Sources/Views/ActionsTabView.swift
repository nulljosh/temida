import SwiftUI

struct ActionsTabView: View {
    @Environment(Store.self) private var store
    private var rcmp: Bool  { store.activeCase == .rcmp }
    private var muni: Bool  { store.activeCase == .muni }

    var body: some View {
        ScrollView {
                VStack(spacing: 22) {
                    if muni { NoticeCardView() }
                    if !store.activeCase.lawyers.isEmpty { lawyersSection }
                    strategySection
                    if !store.activeCase.timeline.isEmpty { timelineSection }
                    if !store.activeCase.checklist.isEmpty { SectionCard("Evidence checklist") { ChecklistView() } }
                    if rcmp {
                        if !callScript.isEmpty { CallScriptView(text: callScript, title: "Callback prep") }
                        if !outreachEmail.isEmpty { CallScriptView(text: outreachEmail, title: "Outreach email") }
                        risksSection
                        evidenceGapsSection
                        draftsSection
                        callbackLogSection
                    } else if muni {
                        if !muniCallScript.isEmpty { CallScriptView(text: muniCallScript, title: "Notice draft + lawyer pitch") }
                        muniRisksSection
                    } else {
                        if !familyCallScript.isEmpty { CallScriptView(text: familyCallScript, title: "Outreach script") }
                        familyRisksSection
                        familyEvidenceSection
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 32)
            }
            .navigationTitle("Lawyers")
    }

    private var lawyersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lawyers").font(.temidaText(13).weight(.bold)).foregroundStyle(.secondary).padding(.horizontal,4)
                .accessibilityAddTraits(.isHeader)
            let lawyers: [Lawyer] = {
                switch store.activeCase { case .rcmp: return caseLawyers; case .family: return familyCaseLawyers; case .muni: return muniCaseLawyers; case .bylaw: return bylawCaseLawyers }
            }()
            ForEach(lawyers) { LawyerCardView(lawyer: $0).caseItemMenu(CaseItem($0)) }
        }
    }

    private var muniRisksSection: some View { risksCard(for: .muni) }

    private var strategySection: some View {
        let f = frag(store.activeCase)
        return Group {
            if !f.strategy.isEmpty {
                SectionCard("Strategy") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(f.strategy, id: \.self) { p in
                            switch p.s {
                            case "body":
                                Text(verbatim: p.t).font(.temidaText(13)).foregroundStyle(.primary).lineSpacing(3)
                            case "warn":
                                Text(verbatim: p.t).font(.temidaText(13)).foregroundStyle(.briefWarn).lineSpacing(3).fontWeight(.bold)
                            default:
                                Text(verbatim: p.t).font(.temidaText(13)).foregroundStyle(.secondary).lineSpacing(3)
                            }
                        }
                    }
                }
            }
        }
    }

    private var timelineSection: some View {
        SectionCard("Timeline") {
            VStack(spacing: 0) {
                let timeline: [TimelineStep] = {
                    switch store.activeCase { case .rcmp: return caseTimeline; case .family: return familyCaseTimeline; case .muni: return muniCaseTimeline; case .bylaw: return bylawCaseTimeline }
                }()
                ForEach(timeline) { step in
                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(dotColor(step.dotStyle))
                                .accessibilityHidden(true)
                                .frame(width: 9, height: 9)
                                .padding(.top, 4)
                                .overlay(step.dotStyle == .now ? Circle().stroke(dotColor(step.dotStyle).opacity(0.3), lineWidth: 4) : nil)
                            if step.id != timeline.last?.id {
                                Rectangle().fill(Color.secondary.opacity(0.2)).frame(width:1).frame(minHeight:20)
                                    .accessibilityHidden(true)
                            }
                        }
                        VStack(alignment:.leading,spacing:3) {
                            Text(step.shown).font(.temidaText(13).weight(.medium)).foregroundStyle(.secondary)
                            Text(step.title).font(.temidaText(13).weight(.semibold))
                            if !step.description.isEmpty { Text(step.description).font(.temidaText(13)).foregroundStyle(.secondary).lineSpacing(2) }
                            if let rule = step.rule { Text(verbatim: rule).font(.temidaText(12)).foregroundStyle(.secondary).italic() }
                        }
                        .padding(.bottom, 18)
                    }
                    .accessibilityElement(children: .combine)
                    .caseItemMenu(CaseItem(step))
                }
            }
        }
    }

    private var risksSection: some View { risksCard(for: .rcmp) }

    private var familyRisksSection: some View { risksCard(for: .family) }

    /// Risk analysis is private case content — title and items both come from
    /// the fragments row. Renders nothing at all if it hasn't loaded.
    @ViewBuilder private func risksCard(for id: CaseID) -> some View {
        let f = frag(id)
        if !f.risks.isEmpty {
            SectionCard(verbatim: f.risksTitle) {
                VStack(alignment:.leading,spacing:10) {
                    ForEach(f.risks, id: \.self) { r in risk(r.t, r.d, r.color) }
                }
            }
        }
    }

    private var evidenceGapsSection: some View {
        proseCard("Evidence gaps — not yet on checklist", frag(.rcmp).prose["evidence"])
    }

    private var draftsSection: some View {
        proseCard("Drafts", frag(.rcmp).prose["drafts"])
    }

    private var familyEvidenceSection: some View {
        proseCard("Evidence priorities", frag(.family).prose["evidence"])
    }

    @ViewBuilder private func proseCard(_ title: LocalizedStringKey, _ body: String?) -> some View {
        if let body, !body.isEmpty {
            SectionCard(title) {
                Text(verbatim: body).font(.temidaText(13)).foregroundStyle(.secondary).lineSpacing(4)
            }
        }
    }

    private var callbackLogSection: some View {
        SectionCard("Callback log") {
            Text("After each lawyer call, note:\n• Whether the claim can still be brought\n• Their fees, contingency or hourly\n• Their view on your limitation date\n• The next step they suggest\n• Whether they will take the case\n• Who they would refer you to")
                .font(.temidaText(13)).foregroundStyle(.secondary).lineSpacing(4)
        }
    }

    private func risk(_ bold: String, _ text: String, _ color: Color) -> some View {
        Text(verbatim: "\(bold) \(text)")
            .font(.temidaText(13)).lineSpacing(3)
            .foregroundStyle(color)
    }

    private func dotColor(_ s: TimelineStep.DotStyle) -> Color {
        switch s { case .now: return .briefDanger; case .warn: return .briefWarn; case .good: return .briefGreen; case .danger: return .briefDanger; case .neutral: return .secondary }
    }
}
