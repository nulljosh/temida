// No imports: kept dependency-free so ChecklistIndexTests.swift can compile it
// standalone with swiftc. See that file for the runnable check.

// MARK: - Checklist id blocks
//
// `brief_checklist.item_index` is an Int column and CASE-0001's ids are numeric
// strings ("1", "8", …), so those map straight through and existing rows keep
// working. Every other case uses a letter-prefixed id ("f0", "m0", "b0") which
// `Int(_:)` returns nil for — previously collapsing every item in those cases to
// id 0, so ticking one ticked all of them. Each prefix gets its own numeric block.
// The `completedItems` seed already contains 201, i.e. muni item m1.
private let checklistIdBlocks: [Character: Int] = ["f": 100, "m": 200, "b": 300]

func checklistIndex(for rawID: String) -> Int {
    if let n = Int(rawID) { return n }
    guard let prefix = rawID.first, let block = checklistIdBlocks[prefix],
          let offset = Int(rawID.dropFirst()) else { return 0 }
    return block + offset
}
