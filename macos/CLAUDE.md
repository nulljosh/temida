# temida/macos

Native macOS app for litigation planning. SwiftUI port of temida.jaybulb.com.

## Stack: SwiftUI, macOS 14+, Swift 6, xcodegen

## Key files
- `Sources/Models/CaseData.swift` — symlink to `ios/Sources/Models/CaseData.swift`: type/struct definitions and empty `@MainActor` globals for CASE-0001 — populated at runtime, not hardcoded
- `Sources/Models/FamilyCaseData.swift` — symlink: empty `@MainActor` globals for CASE-0002 — populated at runtime
- `Sources/Models/MuniCaseData.swift` — symlink: empty `@MainActor` globals for CASE-0003 — populated at runtime
- `Sources/Models/CaseDataMapper.swift` — symlink to `ios/Sources/Models/CaseDataMapper.swift`: DTOs + mapping from the `brief_data` JSON into native model types
- `Sources/Models/Store.swift` — symlink to the shared Store: jaybulb-api sign-in and sync, splash and onboarding gates, profile; no Face ID on macOS

Case/lawyer/script content lives in the jaybulb-api `brief_data` table (`key='cases'`), not in
this repo — mirrors `web/CLAUDE.md` and `ios/CLAUDE.md`.
- `Sources/Models/API.swift` — symlink: the jaybulb-api client
- Other symlinks into `ios/Sources/Models`: `BylawCaseData.swift`, `ChecklistIndex.swift`, `NativeFragments.swift`, `Planner.swift`. `Spacing.swift` is a copy, not a link.
- Symlinks into `ios/Sources/Views`: `SignInView`, `OnboardingView`, `ProfileView`, `NextStepsView`, `CoverHeaderView`, `LimitationBannerView`, `NoticeCardView`, `ValueBeltView`. Run `find Sources -type l` to check.
- `Sources/ContentView.swift` — NavigationSplitView (sidebar: Case, Tasks, Money, Lawyers, Files, then Profile)
- `Sources/Views/CaseTabView.swift`: Case panel, branches on activeCase (a plain copy, not a link)
- `Sources/Views/MoneyTabView.swift`: Money panel, branches on activeCase (a plain copy)
- `Sources/Views/ActionsTabView.swift`: the Lawyers sidebar item (sidebar tag `actions`). A plain copy of the iOS view, not a link

## Build
```
cd macos && xcodegen generate && open Temida.xcodeproj
```
Bundle: `com.nulljosh.brief` | Team: `QMM486NPYC` | macOS 14+

## Data sync
Case facts, lawyers, and grounds are not edited in source — update the `brief_data`
row (`key='cases'`) directly. `CaseData.swift`/`FamilyCaseData.swift`/`MuniCaseData.swift`/
`CaseDataMapper.swift` are symlinks to the `ios/` versions, so iOS and macOS always stay in sync
automatically.
