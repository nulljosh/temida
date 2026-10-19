import Foundation

// Runnable check for the checklist id-block scheme. Not part of either app
// target — compile and run it directly:
//
//   swiftc -O ios/Sources/Models/ChecklistIndex.swift ios/Sources/Models/Limitation.swift \
//             tests/main.swift -o /tmp/clidx && /tmp/clidx
//
// Lives outside Sources/ so xcodegen never sweeps it into an app target, and is
// named main.swift because top-level statements are only legal there.
//
// The bug this guards: `Int(i) ?? 0` mapped every letter-prefixed id ("f0",
// "m0", "b0") to 0, so all items in CASE-0002/0003/0004 shared one id — ticking
// one ticked them all, and the completed count was wrong. It failed silently.

// CASE-0001 uses bare numeric ids; the other cases use letter-prefixed ids.
let case1 = ["1", "8", "9", "10", "13"]
let case2 = ["f0", "f1", "f2", "f3"]
let case3 = ["m0", "m1", "m2", "m3", "m4", "m5"]
let case4 = ["b0", "b1", "b2", "b3", "b4", "b5"]

// Not `assert`: asserts are stripped under -O, so a reintroduced bug would print
// FAIL and still exit 0. Track failures and exit non-zero.
var failures = 0
func check(_ label: String, _ condition: Bool) {
    if !condition { failures += 1 }
    print(condition ? "ok   \(label)" : "FAIL \(label)")
}

// Numeric ids pass through unchanged, so rows already in brief_checklist keep working.
for id in case1 {
    check("numeric id \(id) passes through", checklistIndex(for: id) == Int(id)!)
}

// The seeded default completedItems contains 201, i.e. CASE-0003 item m1.
check("m1 maps to the seeded 201", checklistIndex(for: "m1") == 201)

// No collisions within a case: N distinct ids must give N distinct indices.
for (name, ids) in [("CASE-0001", case1), ("CASE-0002", case2), ("CASE-0003", case3), ("CASE-0004", case4)] {
    let mapped = ids.map { checklistIndex(for: $0) }
    check("\(name) ids are unique within the case", Set(mapped).count == ids.count)
}

// No collisions across cases — this is the assertion that fails if someone
// reintroduces the `Int(i) ?? 0` fallback or reuses a block.
let all = (case1 + case2 + case3 + case4).map { checklistIndex(for: $0) }
check("no id collides across all four cases", Set(all).count == all.count)

// Unknown prefixes still degrade to 0 rather than trapping, but must be the
// only thing that ever produces 0 besides a literal "0".
check("unknown prefix degrades to 0", checklistIndex(for: "z9") == 0)
check("garbage degrades to 0", checklistIndex(for: "nonsense") == 0)

// v10 deadlines: the rule math, and the two edge cases web/author.js must match.
check("basic: 2 years", Day.adding(months: LimitationRule.basic.months, to: "2026-10-19") == "2028-10-19")
check("ultimate: 15 years", Day.adding(months: LimitationRule.ultimate.months, to: "2021-08-08") == "2036-08-08")
check("notice: 2 months", Day.adding(months: LimitationRule.notice.months, to: "2026-03-15") == "2026-05-15")
check("Feb 29 + 2 years is Feb 28", Day.adding(months: 24, to: "2024-02-29") == "2026-02-28")
check("Dec 31 + 2 months is Feb 28", Day.adding(months: 2, to: "2025-12-31") == "2026-02-28")
check("written date is English", Day.written(Day.date("2026-10-19")!) == "Oct 19, 2026")

if failures > 0 {
    print("\(failures) check(s) FAILED")
    exit(1)
}
print("all checks passed")
