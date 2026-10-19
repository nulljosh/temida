import SwiftUI

struct ChecklistView: View {
    @Environment(Store.self) private var store

    private var checklist: [ChecklistItem] {
        switch store.activeCase {
        case .rcmp:   return caseChecklist
        case .family: return familyCaseChecklist
        case .muni:   return muniCaseChecklist
        case .bylaw:  return bylawCaseChecklist
        }
    }
    private var completedCount: Int { store.completedItems.filter { id in checklist.contains(where: { $0.id == id }) }.count }
    private var total: Int { checklist.count }
    private var progress: Double { total > 0 ? Double(completedCount) / Double(total) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Before the appointment.")
                    .font(.temidaText(13))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: "\(completedCount)/\(total)")
                    .font(.temidaText(13))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(completedCount) of \(total) done")
            }
            .padding(.bottom, 10)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.2)).frame(height: 3)
                    RoundedRectangle(cornerRadius: 2).fill(Color.briefGreen).frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)
            .accessibilityHidden(true)
            .padding(.bottom, 10)

            ForEach(checklist) { item in
                let done = store.completedItems.contains(item.id)
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(done ? Color.briefGreen : Color.clear)
                            .frame(width: 18, height: 18)
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(done ? Color.briefGreen : Color.secondary.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                        if done {
                            Image(systemName: "checkmark")
                                .font(.temidaText(13).weight(.bold))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                        }
                    }
                    Text(verbatim: item.label)
                        .font(.temidaText(13))
                        .foregroundStyle(done ? .secondary : .primary)
                        .strikethrough(done, color: .secondary)
                        .lineLimit(nil)
                    Spacer()
                    if !done {
                        switch item.priority {
                        case .now:
                            Text("now")
                                .font(.temidaText(13).weight(.medium))
                                .foregroundStyle(.briefDanger)
                        case .soon:
                            Text("soon")
                                .font(.temidaText(13).weight(.medium))
                                .foregroundStyle(.briefWarn)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Task { await store.toggleItem(item.id) }
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(done ? [.isButton, .isSelected] : .isButton)
                .accessibilityValue(done ? Text("Done") : Text("Not done"))
                .padding(.vertical, 10)
                if item.id != checklist.last?.id {
                    Divider()
                }
            }
        }
        .padding(Spacing.mdPlus)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
