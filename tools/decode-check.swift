// Decodes a real brief with the app's own model code, so a data shape the native apps cannot read
// fails here instead of silently emptying a screen. The data never lives in the repo:
//   python3 ~/.claude/skills/brief/pull.py /tmp/x/brief.json
//   cp tools/decode-check.swift /tmp/x/main.swift && swiftc -swift-version 5 -o /tmp/x/check /tmp/x/main.swift ios/Sources/Models/{CaseData,CaseDataMapper,ChecklistIndex,NativeFragments,FamilyCaseData,MuniCaseData,BylawCaseData}.swift && /tmp/x/check /tmp/x/brief.json
import Foundation

let file = URL(fileURLWithPath: CommandLine.arguments[1])
let root = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
let rows = root["brief_data"] as! [[String: Any]]
func value(_ key: String) throws -> Data {
    guard let v = rows.first(where: { $0["key"] as? String == key })?["value"] else { throw CocoaError(.fileReadCorruptFile) }
    return try JSONSerialization.data(withJSONObject: v)
}

var failed = false
do {
    let b = try JSONDecoder().decode(CaseDataDTO.self, from: value("cases")).toBundle()
    print("cases ok: \(b.facts.count) facts, \(b.grounds.count) grounds, \(b.lawyers.count) lawyers, \(b.checklist.count) steps, \(b.timeline.count) timeline")
    if b.facts.isEmpty || b.grounds.isEmpty { print("cases WARN: an empty list the web app shows"); failed = true }
} catch { print("cases FAIL: \(error)"); failed = true }
do {
    let f = try JSONDecoder().decode(FragmentsValue.self, from: value("fragments"))
    let keys = f.native?.keys.sorted() ?? []
    print("fragments ok: \(keys)")
    for c in CaseID.allCases where f.native?[c.fragKey] == nil { print("fragments WARN: no fragment for \(c.rawValue) (\(c.fragKey))"); failed = true }
} catch { print("fragments FAIL: \(error)"); failed = true }
exit(failed ? 1 : 0)
