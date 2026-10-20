import SwiftUI

struct JournalView: View {
    @Environment(Store.self) private var store
    @State private var showingForm = false
    @State private var editingEntry: JournalEntry? = nil
    @State private var newDate = Date.now
    @State private var newText = ""
    var query = "" // v11: the Case tab search narrows the journal too
    private var entries: [JournalEntry] { query.isEmpty ? store.journalEntries : store.journalEntries.filter { $0.text.localizedCaseInsensitiveContains(query) } }

    private let seedDates: Set<String> = Set(journalSeed.map(\.date))

    private func fmt(_ iso: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: iso) else { return iso }
        let o = DateFormatter(); o.dateStyle = .medium; o.timeStyle = .none
        return o.string(from: d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Entries")
                    .font(.temidaText(13).weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("+ Entry") { showingForm = true }
                    .font(.temidaText(13).weight(.bold))
                    .foregroundStyle(.briefGreen)
                    .accessibilityLabel("Add entry")
            }
            .padding(.bottom, 14)

            ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(fmt(entry.date))
                        .font(.temidaText(13))
                        .foregroundStyle(.secondary)
                    Text(verbatim: entry.text)
                        .font(.temidaText(13))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if !seedDates.contains(entry.date) {
                        Button(role: .destructive) {
                            Task { await store.deleteJournalEntry(date: entry.date) }
                        } label: { Label("Delete", systemImage: "trash") }

                        Button {
                            editingEntry = entry
                            newDate = {
                                let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                                return f.date(from: entry.date) ?? Date.now
                            }()
                            newText = entry.text
                            showingForm = true
                        } label: { Label("Edit", systemImage: "pencil") }
                            .tint(.briefAccent)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityActions {
                    if !seedDates.contains(entry.date) {
                        Button("Edit") {
                            editingEntry = entry
                            newDate = {
                                let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                                return f.date(from: entry.date) ?? Date.now
                            }()
                            newText = entry.text
                            showingForm = true
                        }
                        Button("Delete") { Task { await store.deleteJournalEntry(date: entry.date) } }
                    }
                }
                if idx < entries.count - 1 { Divider() }
            }
        }
        .padding(Spacing.mdPlus)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingForm, onDismiss: { editingEntry = nil; newText = "" }) {
            NavigationStack {
                Form {
                    Section("Date") {
                        DatePicker("Entry date", selection: $newDate, in: ...Date.now, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    Section("Note") {
                        TextEditor(text: $newText)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle(editingEntry == nil ? LocalizedStringKey("New Entry") : LocalizedStringKey("Edit Entry"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingForm = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            guard !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                            let d = f.string(from: newDate); let t = newText
                            showingForm = false
                            Task { await store.addJournalEntry(date: d, text: t) }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
