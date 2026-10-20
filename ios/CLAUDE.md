# temida/ios

Native iPhone app for Temida. Same account and data as the web app (temida.jaybulb.com).

## Stack: SwiftUI, iOS 17+, Swift 6, xcodegen

## Key files
- `Sources/Models/CaseData.swift` — type/struct definitions (Ground, Witness, Lawyer, Scenario, etc.), `CaseID` enum, Color extensions, and empty `@MainActor` globals for CASE-0001 (grounds, witnesses, journal seed, lawyers, checklist, call script, email template) — populated at runtime, not hardcoded
- `Sources/Models/FamilyCaseData.swift` — empty `@MainActor` globals for CASE-0002 (CASE-0002 family tort case) — populated at runtime
- `Sources/Models/MuniCaseData.swift` — empty `@MainActor` globals for CASE-0003 (CASE-0003) — populated at runtime
- `Sources/Models/CaseDataMapper.swift` — private Decodable DTOs matching the compact `brief_data` JSON shapes + mapping functions into the native model types; includes opaque-id-keyed visual override tables (accent color, open-by-default) for grounds
- `Sources/Models/Store.swift` — @MainActor @Observable Store shared with macOS; sign-in and sync through `API.swift` (jaybulb-api); `loadCaseData()` fetches `brief_data` (key='cases') on sign-in and populates all case/family/muni globals; Face ID unlock (`biometricLocked`, `authenticateWithBiometrics()`)

Case/lawyer/script content lives in the jaybulb-api `brief_data` table (`key='cases'`), not in
this repo — mirrors the `web/CLAUDE.md` pattern. Nothing in `CaseData.swift`, `FamilyCaseData.swift`,
or `MuniCaseData.swift` is hardcoded case content; only types and empty containers populated by
`Store.loadCaseData()` at runtime.
- `Sources/Models/API.swift` — jaybulb-api client: Keychain session, refresh, email/password, Apple, Google PKCE, `select`/`upsert`/`insert`/`delete` on `/rest/<table>`
- `Sources/Models/Planner.swift` — sends a next step to Reminders or Calendar (EventKit); also `Color.brandSlate`
- `Sources/Views/OnboardingView.swift` — the launch splash and the three-step new-account welcome
- `Sources/Views/NextStepsView.swift` — Tasks tab: open steps first, done below, Remind Me / Add to Calendar
- `Sources/Views/ProfileView.swift` — Profile tab: name, photo (upload or generate), case picker, reset password, sign out, delete account, about
- `Sources/Views/SignInView.swift` — shared sign-in: email, then password; Apple and Google as matching 48pt capsules
- `Sources/Views/BiometricLockView.swift` — Face ID / Touch ID lock screen (auto-prompts on appear, retry button)
- `Sources/Views/CaseTabView.swift` — Case tab (facts, witnesses, grounds accordion, journal) — branches on activeCase
- `Sources/Views/MoneyTabView.swift` — Money tab (scenarios, damage stack, Ward framework) — branches on activeCase
- `Sources/Views/ActionsTabView.swift`: lawyers, timeline, checklist, scripts, risks. There is no Actions tab on iPhone: `NextStepsView` (Tasks) opens it as "Lawyers and call scripts". The Mac sidebar's Lawyers item uses it too
- `Sources/Models/BylawCaseData.swift`: empty `@MainActor` globals for CASE-0004 (the bylaw notice), filled at runtime
- `Sources/Models/ChecklistIndex.swift`: checklist id blocks for `brief_checklist.item_index`; no imports, so `tests/main.swift` can compile it alone
- `Sources/Models/Limitation.swift`: v10 deadline rules (BC Limitation Act s. 6(1) and 21(1), LGA s. 736(1)) and `Day` date helpers; no UIKit, so `tests/main.swift` compiles it. `web/author.js` `addMonths` does the same math
- `Sources/Models/BriefPDF.swift`: v11 Share as PDF; CoreText pages drawn on the device, no UIKit, so `tests/main.swift` checks the paging. Its case-data init sits at the end of `CaseData.swift`
- `Sources/Models/Spacing.swift`: the spacing scale (`Spacing.xs`, `sm`, `md`, ...)
- `Sources/Views/DocumentsTabView.swift`: Files tab: a "Search case law" link (iPhone only) above `DocumentsView`
- `Sources/Views/DocumentsView.swift`: "Case Documents" list and the New Document form; the Files tab search narrows it
- `Sources/Views/CallScriptView.swift`: the call script for the open case
- `Sources/Views/ChecklistView.swift`: evidence checklist with now and soon priorities and done state
- `Sources/Models/Store+Authoring.swift`: v9 adds, edits and removes facts, deadlines, lawyers, grounds and witnesses in the open case. Reads the raw `cases` row, finds the row by content (fact key and value, deadline title and when, lawyer and ground id, witness name, role and statement), changes it, writes the whole value back, so keys the typed models skip survive
- `Sources/Views/AddToCaseSheet.swift`: the + menu on the Case tab, its form (add or edit), and `.caseItemMenu` (Edit and Remove on a long press or right click). Shared with macOS by symlink
- `Sources/Views/JournalView.swift`: case journal entries: add, edit, delete
- `Sources/Views/View+Glass.swift`: one glass modifier for floating controls: Liquid Glass on iOS 26+, material before
- `Sources/WhatsNewSheet.swift`: What's New sheet for `whatsNewVersion`; skipped when a `UITEST_` argument is set
- `Sources/CaseLaw/`: CanLII case-law search and detail, through the `canlii-app` proxy (iPhone only)

## Build
```
cd ios && xcodegen generate && open Temida.xcodeproj   # tabs: Case, Tasks, Money, Files, Profile
```
Screenshots without taps: `simctl launch <udid> com.nulljosh.brief -tab N UITEST_x` (UITEST_ skips What's New).
Bundle: `com.nulljosh.brief` | Team: `QMM486NPYC` | iOS 17+

## Platforms
- Web: `web/` — temida.jaybulb.com
- iOS: `ios/`
- macOS: `macos/`

## Data sync
Case facts, lawyers, and grounds are not edited in source on any platform — they live in the
jaybulb-api `brief_data` table (`key='cases'`). macOS's `CaseData.swift`/`FamilyCaseData.swift`/
`MuniCaseData.swift`/`CaseDataMapper.swift` are symlinks to the `ios/` versions, so iOS and
macOS stay in sync automatically; the web app reads the same table independently.

## Counsel contacts
Lawyer names, firms and direct contact details live in the jaybulb-api `brief_data` row
(`key='cases'`, LAWYERS keys) — never in this repo.

- 2026-10-19: the custom floating tab bar is gone; the system tab bar has labels under every icon. Supabase removed.
