import SwiftUI

struct DocumentsView: View {
    @Environment(Store.self) private var store
    @State private var showingForm = false
    @State private var newDate = Date.now
    @State private var newTitle = ""
    @State private var newText = ""

    private func fmt(_ iso: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: iso) else { return iso }
        let o = DateFormatter(); o.dateStyle = .medium; o.timeStyle = .none
        return o.string(from: d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Case Documents")
                    .font(.temidaText(13).weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("+ Document") { showingForm = true }
                    .font(.temidaText(13).weight(.bold))
                    .foregroundStyle(.briefGreen)
                    .accessibilityLabel("Add document")
            }
            .padding(.bottom, 14)

            if store.documentEntries.isEmpty {
                Text("No documents yet. Source files (photos/PDFs) stay off-platform — log what each document is and where it lives.")
                    .font(.temidaText(13))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }

            ForEach(Array(store.documentEntries.enumerated()), id: \.element.id) { idx, entry in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fmt(entry.date))
                            .font(.temidaText(13))
                            .foregroundStyle(.secondary)
                        Text(verbatim: entry.title)
                            .font(.temidaText(13).weight(.bold))
                        Text(verbatim: entry.text)
                            .font(.temidaText(13))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    Spacer()
                    Button {
                        Task { await store.deleteDocumentEntry(date: entry.date, title: entry.title) }
                    } label: { Image(systemName: "trash").font(.temidaText(13)) }
                        .buttonStyle(.plain).foregroundStyle(.briefDanger)
                        .padding(.top, 2)
                        .accessibilityLabel("Delete")
                }
                .padding(.vertical, 14)
                .accessibilityElement(children: .contain)
                if idx < store.documentEntries.count - 1 { Divider() }
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingForm, onDismiss: { newTitle = ""; newText = "" }) {
            NavigationStack {
                Form {
                    Section("Date") {
                        DatePicker("Document date", selection: $newDate, in: ...Date.now, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    Section("Title") {
                        TextField("e.g. Letter from the clinic", text: $newTitle)
                    }
                    Section("Summary") {
                        TextEditor(text: $newText)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle("New Document")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingForm = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                  !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                            let d = f.string(from: newDate); let t = newTitle; let x = newText
                            showingForm = false
                            Task { await store.addDocumentEntry(date: d, title: t, text: x) }
                        }
                    }
                }
            }
            .frame(minWidth: 420, minHeight: 380)
        }
    }
}
