import SwiftUI

/// The brief's to-do list: open steps first ("now" before "soon"), each one can go to Reminders or Calendar.
struct NextStepsView: View {
    @Environment(Store.self) private var store
    @State private var planning: PlanRequest?

    private var checklist: [ChecklistItem] {
        switch store.activeCase {
        case .rcmp:   return caseChecklist
        case .family: return familyCaseChecklist
        case .muni:   return muniCaseChecklist
        case .bylaw:  return bylawCaseChecklist
        }
    }
    private var open: [ChecklistItem] {
        checklist.filter { !store.completedItems.contains($0.id) }
            .sorted { ($0.priority == .now ? 0 : 1) < ($1.priority == .now ? 0 : 1) }
    }
    private var done: [ChecklistItem] { checklist.filter { store.completedItems.contains($0.id) } }

    var body: some View {
        NavigationStack {
            List {
                if checklist.isEmpty {
                    ContentUnavailableView("No steps yet", systemImage: "checklist",
                                           description: Text("Steps for this case show up here."))
                } else if open.isEmpty {
                    ContentUnavailableView("All caught up", systemImage: "checkmark.circle",
                                           description: Text("Every step for this case is done."))
                } else {
                    Section {
                        ForEach(open) { row($0) }
                    } header: {
                        Text("\(open.count) open")
                    }
                }
                if !done.isEmpty {
                    Section("Done") {
                        ForEach(done) { row($0) }
                    }
                }
                #if os(iOS) // the Mac sidebar has its own Lawyers item
                Section {
                    NavigationLink {
                        ActionsTabView()
                    } label: {
                        Label("Lawyers and call scripts", systemImage: "person.2")
                    }
                }
                #endif
            }
            .navigationTitle("Tasks")
            .sheet(item: $planning) { PlanSheet(request: $0) }
        }
    }

    private func row(_ item: ChecklistItem) -> some View {
        let isDone = store.completedItems.contains(item.id)
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button {
                Task { await store.toggleItem(item.id) }
            } label: {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isDone ? Color.brandSlate : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isDone ? LocalizedStringKey("Mark not done") : LocalizedStringKey("Mark done"))

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: item.label)
                    .foregroundStyle(isDone ? .secondary : .primary)
                if !isDone && item.priority == .now {
                    Text("Now").font(.footnote.weight(.semibold)).foregroundStyle(.red)
                }
            }
            Spacer(minLength: 0)
            if !isDone {
                Menu {
                    Button { planning = PlanRequest(item: item, kind: .reminder) } label: {
                        Label("Remind Me", systemImage: "bell")
                    }
                    Button { planning = PlanRequest(item: item, kind: .event) } label: {
                        Label("Add to Calendar", systemImage: "calendar.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.title3).foregroundStyle(Color.brandSlate)
                }
                .menuIndicator(.hidden)
                .accessibilityLabel("Plan this step")
            }
        }
        .padding(.vertical, 4)
    }
}

struct PlanRequest: Identifiable {
    enum Kind { case reminder, event }
    let item: ChecklistItem
    let kind: Kind
    var id: String { "\(item.id)-\(kind)" }
}

private struct PlanSheet: View {
    let request: PlanRequest
    @Environment(\.dismiss) private var dismiss
    @State private var when = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0,
                                                    of: Date().addingTimeInterval(86_400)) ?? Date()
    @State private var error: String?
    @State private var saving = false

    private var isReminder: Bool { request.kind == .reminder }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(verbatim: request.item.label)
                }
                Section {
                    DatePicker(isReminder ? LocalizedStringKey("Remind me") : LocalizedStringKey("Starts"), selection: $when, in: Date()...)
                } footer: {
                    Text(isReminder ? LocalizedStringKey("Adds a reminder to your default Reminders list.")
                                    : LocalizedStringKey("Adds a 30 minute event to your default calendar."))
                }
                if let error {
                    Text(verbatim: error).foregroundStyle(.red)
                }
            }
            .navigationTitle(isReminder ? LocalizedStringKey("Remind Me") : LocalizedStringKey("Add to Calendar"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { Task { await save() } }.disabled(saving)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() async {
        saving = true
        defer { saving = false }
        do {
            let notes = String(localized: "From your Temida brief.")
            if isReminder { try await Planner.remind(request.item.label, notes: notes, due: when) }
            else { try await Planner.schedule(request.item.label, notes: notes, start: when) }
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
