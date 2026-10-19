import SwiftUI

/// One form for what people add to a case: a fact, a deadline, a lawyer, a ground, a witness.
struct AddToCaseSheet: View {
    let kind: CaseAddition
    var editing: CaseItem? = nil
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var a = ""  // fact label, deadline title, lawyer name, ground title, witness name
    @State private var b = ""  // fact value, deadline note, lawyer firm, ground reason, witness statement
    @State private var c = ""  // ground law or section, witness role
    @State private var phone = ""
    @State private var email = ""
    @State private var due = Date.now
    @State private var saving = false
    @State private var saved = 0
    @State private var dueChanged = false // an unparsed "when" stays as written unless the date is touched
    @State private var rule: LimitationRule? // v10: the due date worked out from the law
    @State private var start = Date.now

    private var title: LocalizedStringKey {
        if editing != nil {
            return switch kind { case .fact: "Edit fact"; case .deadline: "Edit deadline"; case .lawyer: "Edit lawyer"; case .ground: "Edit ground"; case .witness: "Edit witness" }
        }
        return switch kind { case .fact: "New fact"; case .deadline: "New deadline"; case .lawyer: "New lawyer"; case .ground: "New ground"; case .witness: "New witness" }
    }
    private var ready: Bool {
        let t = a.trimmingCharacters(in: .whitespacesAndNewlines)
        return !t.isEmpty && (kind != .fact || !b.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                switch kind {
                case .fact:
                    TextField("Label, like Date of incident", text: $a)
                    TextField("Value", text: $b, axis: .vertical)
                case .deadline:
                    TextField("What is due", text: $a)
                    Picker("Rule", selection: $rule) {
                        Text("Pick the date myself").tag(LimitationRule?.none)
                        ForEach(LimitationRule.allCases) { Text(label($0)).tag(Optional($0)) }
                    }
                    .onChange(of: rule) { if let rule, a.isEmpty { a = String(localized: defaultTitle(rule)) } }
                    if let rule {
                        DatePicker(startLabel(rule), selection: $start, displayedComponents: .date)
                        if rule == .basic { Text("The day you first knew, or reasonably should have known, that you were harmed, who caused it, and that going to court is the right step (s. 8).").font(.footnote).foregroundStyle(.secondary) }
                        LabeledContent("Due", value: Day.date(dueDay)?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        Text(verbatim: rule.cite).font(.footnote).foregroundStyle(.secondary)
                        Text("Worked out from BC law. Check it with a lawyer.").font(.footnote).foregroundStyle(.secondary)
                    } else {
                        DatePicker("Due", selection: $due, displayedComponents: .date)
                            .onChange(of: due) { dueChanged = true }
                    }
                    TextField("Note", text: $b, axis: .vertical)
                case .ground:
                    TextField("Ground, like Negligence", text: $a)
                    TextField("Law or section", text: $c)
                    TextField("Why it applies", text: $b, axis: .vertical)
                case .witness:
                    TextField("Name", text: $a).textContentType(.name)
                    TextField("Role, like Bystander", text: $c)
                    DatePicker("Date", selection: $due, displayedComponents: .date)
                        .onChange(of: due) { dueChanged = true }
                    TextField("What they saw", text: $b, axis: .vertical)
                case .lawyer:
                    TextField("Name", text: $a).textContentType(.name)
                    TextField("Firm or practice", text: $b).textContentType(.organizationName)
                    TextField("Phone", text: $phone).textContentType(.telephoneNumber)
                    #if os(iOS)
                        .keyboardType(.phonePad)
                    #endif
                    TextField("Email", text: $email).textContentType(.emailAddress)
                    #if os(iOS)
                        .keyboardType(.emailAddress).textInputAutocapitalization(.never)
                    #endif
                }
                if let err = store.accountActionError {
                    Text(verbatim: err).foregroundStyle(Color.briefDanger)
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saving = true
                        Task {
                            let ok = if let editing { await store.change(kind, .update(match: editing.match, with: changes)) }
                                     else { await store.add(kind, item) }
                            if ok, let editing, kind == .deadline { follow(editing) }
                            if ok { saved += 1; dismiss() }
                            saving = false
                        }
                    }
                    .disabled(!ready || saving)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sensoryFeedback(.success, trigger: saved)
        .onAppear {
            store.accountActionError = nil // an old profile error is not this form's
            guard let e = editing else { return }
            a = e.a; b = e.b; c = e.c; phone = e.phone; email = e.email
            if let d = e.due { due = d }
            DispatchQueue.main.async { dueChanged = false } // setting `due` above is not a user edit
        }
    }

    private var dueDay: String { rule.flatMap { Day.adding(months: $0.months, to: Day.iso(start)) } ?? Day.iso(due) }

    private func label(_ r: LimitationRule) -> LocalizedStringKey {
        switch r {
        case .basic: "Basic limitation, 2 years (BC)"
        case .ultimate: "Ultimate limitation, 15 years (BC)"
        case .notice: "Notice to a municipality, 2 months (BC)"
        }
    }
    private func startLabel(_ r: LimitationRule) -> LocalizedStringKey {
        switch r { case .basic: "Claim discovered"; case .ultimate: "Act or omission"; case .notice: "Damage sustained" }
    }
    private func defaultTitle(_ r: LimitationRule) -> String.LocalizationValue {
        switch r {
        case .basic: "Basic limitation period ends"
        case .ultimate: "Ultimate limitation period ends"
        case .notice: "Notice to the municipality is due"
        }
    }

    /// The same shapes web/script.js reads, so every platform renders it.
    private var item: [String: Any] {
        let name = a.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = b.trimmingCharacters(in: .whitespacesAndNewlines)
        let third = c.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .fact:
            return ["key": name, "value": note]
        case .deadline:
            var row: [String: Any] = ["when": Day.written(Day.date(dueDay) ?? due), "due": dueDay, "title": name, "desc": note, "state": "warn"]
            if let rule { row["rule"] = rule.cite }
            return row
        case .lawyer:
            var contacts: [[String: Any]] = []
            let p = phone.trimmingCharacters(in: .whitespaces), e = email.trimmingCharacters(in: .whitespaces)
            if !p.isEmpty { contacts.append(["kind": "tel", "href": "tel:" + p, "label": p, "primary": true]) }
            if !e.isEmpty { contacts.append(["kind": "email", "href": "mailto:" + e, "label": e]) }
            let initials = name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
            return ["id": UUID().uuidString.lowercased(), "init": initials, "name": name, "sub": note,
                    "tags": [Any](), "contacts": contacts, "status": "none"]
        case .ground: // every key the decoders require, so the row shows on every platform; n is set on save
            return ["id": UUID().uuidString.lowercased(), "n": "", "title": name, "sec": third, "desc": note,
                    "val": "", "cite": "", "grade": "", "risk": "", "high": 0]
        case .witness:
            let initials = name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
            return ["initials": initials, "name": name, "role": third, "date": Day.written(due),
                    "statement": note, "tags": [Any](), "annotations": [Any]()]
        }
    }

    /// An edit only sends what the form shows; id, status, tags and the dot colour stay.
    private var changes: [String: Any] {
        var c = item
        switch kind {
        case .fact: break
        case .deadline:
            c["state"] = nil
            if rule == nil {
                if !dueChanged && editing?.due == nil { c["when"] = nil; c["due"] = nil }
                else if dueChanged { c["rule"] = NSNull() } // a date picked by hand no longer follows the rule
            }
        case .lawyer:
            c["id"] = nil; c["status"] = nil; c["tags"] = nil
        case .ground: // id, number, value, grade and citation stay
            c = ["title": c["title"]!, "sec": c["sec"]!, "desc": c["desc"]!]
        case .witness:
            c["tags"] = nil; c["annotations"] = nil
            if !dueChanged && editing?.due == nil { c["date"] = nil }
        }
        return c
    }
}

extension AddToCaseSheet {
    /// Moves a reminder made from this deadline to the new title and day. The new id is built the way `CaseItem.id` is.
    private func follow(_ old: CaseItem) {
        guard let title = item["title"] as? String,
              let day = (changes["due"] as? String).flatMap(Day.date) ?? old.due,
              let nine = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: day) else { return }
        let when = changes["when"] as? String ?? old.match["when"] ?? ""
        Planner.follow(old.id, to: CaseAddition.deadline.rawValue + title + "|" + when, title: title, notes: item["desc"] as? String, due: nine)
    }
}

/// One row of the open case as the form sees it. `match` finds the stored row again.
struct CaseItem: Identifiable {
    let kind: CaseAddition
    let match: [String: String]
    var a = "", b = "", c = "", phone = "", email = ""
    var due: Date? = nil
    var id: String { kind.rawValue + match.sorted { $0.key < $1.key }.map(\.value).joined(separator: "|") }

    init(_ f: CaseFact) { kind = .fact; match = ["key": f.key, "value": f.value]; a = f.key; b = f.value }
    init(_ t: TimelineStep) {
        kind = .deadline; match = ["title": t.title, "when": t.when]; a = t.title; b = t.description
        due = t.due.flatMap(Day.date) ?? Self.parse(t.when)
    }
    init(_ g: Ground) { kind = .ground; match = ["id": g.id]; a = g.title; b = g.description; c = g.section }
    init(_ w: Witness) {
        kind = .witness; match = ["name": w.name, "role": w.role, "statement": w.statement]; a = w.name; b = w.statement; c = w.role
        due = Self.parse(w.date)
    }
    /// "Oct 19, 2026" from any platform, or a date written in this device's own language.
    private static func parse(_ s: String) -> Date? {
        let en = DateFormatter(); en.locale = Locale(identifier: "en_US_POSIX"); en.dateFormat = "MMM d, yyyy"
        let local = DateFormatter(); local.dateStyle = .medium
        return en.date(from: s) ?? local.date(from: s)
    }
    init(_ l: Lawyer) {
        kind = .lawyer; match = ["id": l.id]; a = l.name; b = l.subtitle; phone = l.phone ?? ""; email = l.email ?? ""
    }
}

/// Edit and Remove on any fact, deadline, lawyer, ground or witness: long press on iPhone, right click on Mac.
struct CaseItemMenu: ViewModifier {
    let item: CaseItem
    @Environment(Store.self) private var store
    @State private var editing: CaseItem?
    @State private var confirmRemove = false
    @State private var planError: String?

    func body(content: Content) -> some View {
        content
            .contextMenu {
                if item.kind == .deadline, let day = item.due,
                   let nine = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: day) {
                    Button("Remind Me", systemImage: "bell") { plan { try await Planner.remind(item.a, notes: item.b, due: nine, follow: item.id) } }
                    Button("Add to Calendar", systemImage: "calendar.badge.plus") { plan { try await Planner.schedule(item.a, notes: item.b, start: nine) } }
                }
                Button("Edit", systemImage: "pencil") { editing = item }
                Button("Remove", systemImage: "trash", role: .destructive) { confirmRemove = true }
            }
            .accessibilityAction(named: "Edit") { editing = item }
            .accessibilityAction(named: "Remove") { confirmRemove = true }
            .sheet(item: $editing) { AddToCaseSheet(kind: $0.kind, editing: $0) }
            .alert("Could not add it", isPresented: Binding(get: { planError != nil }, set: { if !$0 { planError = nil } })) {
                Button("OK") {}
            } message: { Text(verbatim: planError ?? "") }
            .confirmationDialog("Remove this from the case?", isPresented: $confirmRemove, titleVisibility: .visible) {
                Button("Remove", role: .destructive) { Task { await store.change(item.kind, .remove(match: item.match)) } }
            }
    }
}

extension CaseItemMenu {
    private func plan(_ work: @escaping () async throws -> Void) {
        Task { do { try await work() } catch { planError = error.localizedDescription } }
    }
}

extension View {
    func caseItemMenu(_ item: CaseItem) -> some View { modifier(CaseItemMenu(item: item)) }
}

/// The + menu that opens it. Same on iPhone and Mac.
struct AddToCaseMenu: View {
    @State private var adding: CaseAddition?

    var body: some View {
        Menu {
            Button("Fact", systemImage: "text.badge.plus") { adding = .fact }
            Button("Deadline", systemImage: "calendar.badge.plus") { adding = .deadline }
            Button("Lawyer", systemImage: "person.badge.plus") { adding = .lawyer }
            Button("Ground", systemImage: "building.columns") { adding = .ground }
            Button("Witness", systemImage: "person.wave.2") { adding = .witness }
        } label: {
            Label("Add to case", systemImage: "plus")
        }
        .sheet(item: $adding) { AddToCaseSheet(kind: $0) }
    }
}
