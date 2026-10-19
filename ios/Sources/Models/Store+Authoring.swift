import Foundation

// v9: add facts, deadlines and lawyers to the open case from the app. The cases row is read raw,
// one array grows, and the whole value goes back, so keys the typed models never decode
// (TITLE, SCALE, grades, fit) survive. Never rebuild the row from the mapped globals.

enum CaseAddition: String, Identifiable, CaseIterable {
    case fact, deadline, lawyer, ground, witness
    var id: String { rawValue }
    /// The array this lands in, before the per-case prefix. Deadlines are timeline steps.
    var list: String {
        switch self { case .fact: "FACTS"; case .deadline: "TIMELINE"; case .lawyer: "LAWYERS"; case .ground: "GROUNDS"; case .witness: "WITNESSES" }
    }
}

enum CaseEdit {
    case add([String: Any])
    case update(match: [String: String], with: [String: Any])
    case remove(match: [String: String])
}

enum CaseEditError: LocalizedError {
    case changedElsewhere
    var errorDescription: String? { String(localized: "This changed on another device. Reopen the case and try again.") }
}

#if DEBUG
@MainActor private var demoCases: [String: Any]? // the demo never touches the network
#endif

extension Store {
    private var casePrefix: String {
        switch activeCase { case .rcmp: ""; case .family: "FAMILY_"; case .muni: "MUNI_"; case .bylaw: "BYLAW_" }
    }

    /// Appends one item to the open case. False (with `accountActionError` set) when nothing was saved.
    @MainActor func add(_ kind: CaseAddition, _ item: [String: Any]) async -> Bool { await change(kind, .add(item)) }

    /// Edits or removes the row whose string fields equal `match` (fact key+value, deadline title+when,
    /// lawyer id, ground id, witness name+role+statement). Mapped rows can be dropped by the lossy decoder, so rows are found by content, not index.
    @MainActor func change(_ kind: CaseAddition, _ edit: CaseEdit) async -> Bool {
        accountActionError = nil
        do {
            var value = try await freshCases()
            let key = casePrefix + kind.list
            var list = (value[key] as? [Any]) ?? []
            switch edit {
            case .add(var item):
                if kind == .ground { // numbered after the highest one, same rule as the web
                    let top = list.compactMap { Int(($0 as? [String: Any])?["n"] as? String ?? "") }.max() ?? 0
                    item["n"] = String(top + 1)
                }
                list.append(item)
            case .update(let match, _), .remove(let match):
                guard let i = list.firstIndex(where: { row in
                    guard let d = row as? [String: Any] else { return false }
                    return match.allSatisfy { d[$0.key] as? String == $0.value }
                }) else { throw CaseEditError.changedElsewhere }
                if case .update(_, let fields) = edit {
                    guard let old = list[i] as? [String: Any] else { throw CaseEditError.changedElsewhere }
                    var merged = old.merging(fields) { $1 } // keys the form never shows (fit, tags, state) stay
                    if let new = fields["contacts"] as? [[String: Any]] {
                        // The form edits phone and email only; a website or second number survives.
                        let kept = (old["contacts"] as? [[String: Any]] ?? []).filter { !["tel", "email"].contains($0["kind"] as? String ?? "") }
                        merged["contacts"] = new + kept
                    }
                    list[i] = merged
                } else { list.remove(at: i) }
            }
            value[key] = list
            #if DEBUG
            if userId == nil, demoCases != nil { demoCases = value; try applyRaw(value); return true }
            #endif
            guard let uid = userId else { throw URLError(.userAuthenticationRequired) }
            try await api.upsert("brief_data", json: ["user_id": uid, "key": "cases", "value": value])
            try applyRaw(value)
            return true
        } catch {
            accountActionError = error.localizedDescription
            return false
        }
    }

    /// Read right before the write: the web edits this same row.
    @MainActor private func freshCases() async throws -> [String: Any] {
        #if DEBUG
        if userId == nil, let path = UserDefaults.standard.string(forKey: "demoFile") {
            if let demoCases { return demoCases }
            let file = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as? [String: Any]
            demoCases = file?["cases"] as? [String: Any] ?? [:]
            return demoCases!
        }
        #endif
        let data = try await api.call("GET", "/rest/brief_data?select=value&key=eq.cases")
        guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { throw URLError(.cannotParseResponse) }
        guard let row = rows.first else { return Self.emptyBrief("") } // onboarding skipped the first brief
        // A row that is not an object is never overwritten.
        guard let value = row["value"] as? [String: Any] else { throw URLError(.cannotParseResponse) }
        return value
    }

    @MainActor private func applyRaw(_ value: [String: Any]) throws {
        apply(try JSONDecoder().decode(CaseDataDTO.self, from: JSONSerialization.data(withJSONObject: value)))
    }
}
