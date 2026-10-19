# Architecture

Temida keeps one person's case in one brief: facts, grounds, people, dates, money and the next
step. It ships on the web and iPhone, and builds for Mac (no App Store record yet). A Kotlin
Multiplatform module (`kmp/`) covers Android and desktop. It is not shipped.

## How it runs

**Web.** `web/index.html` is a public landing page with empty shells where the case goes.
`web/auth.js` signs in through `web/spark-client.js`, fetches the user's private markup
(`brief_data` key `fragments`), checks whether a new account needs onboarding, then appends
`web/script.js`, which loads the case (`key='cases'`) and renders it. A returning session sees a
splash instead of the landing while this happens.

**iPhone and Mac.** `BriefApp.swift` holds one `Store`. On launch the splash stays up while
`Store.checkSession()` restores the session and loads the profile and the case in parallel. Then
it routes to sign-in, the Face ID lock (iPhone), onboarding (new accounts) or the tabs.

**Android and desktop.** `kmp/` has a shared Compose UI. It still signs in against the old
Supabase project and has not moved to jaybulb-api yet.

## Backend

jaybulb-api (api.jaybulb.com), a Cloudflare Worker on D1 shared with the other jaybulb apps.
It handles sign-in (email, Apple, Google), returns only the signed-in user's own rows from the
`brief_*` tables, and stores profile photos. See [API.md](API.md).

| Table | Holds |
|---|---|
| `brief_data` | `key='cases'` structured case data, `key='fragments'` private display prose |
| `brief_journal`, `brief_documents` | Entries the user adds |
| `brief_checklist`, `brief_lawyer_status` | Step and outreach state |

The account's `user_metadata` holds `full_name`, `avatar_url` or `avatar_seed`, and `onboarded`.

## Native files

`macos/Sources` symlinks 10 models and 8 views from `ios/Sources`, so a fix lands on both. Run
`find macos/Sources -type l` for the list. The Mac keeps its own `ContentView` (sidebar). Its
`CaseTabView`, `MoneyTabView`, `ActionsTabView`, `DocumentsView` and `ChecklistView` are plain
copies, like the other Mac files. `find macos/Sources -type f` lists them.

| File | Owns |
|---|---|
| `Models/API.swift` | jaybulb-api client: session in the Keychain, refresh, sign-in, rows, profile, photo upload |
| `Models/Store.swift` | App state: session, launch and onboarding gates, profile, case loading, writes |
| `Models/CaseData.swift` and the other `*CaseData.swift` | Types and empty globals, filled at runtime |
| `Models/CaseDataMapper.swift` | Decodes the `cases` row. Every list decodes lossily, so one bad row never empties a screen |
| `Models/NativeFragments.swift` | Private cover-sheet prose from `fragments.native` |
| `Models/Planner.swift` | Sends a step to Reminders or Calendar; `Color.brandSlate` |
| `Views/OnboardingView.swift` | The splash and the three-step welcome |
| `Views/SignInView.swift` | Email then password; Apple and Google as matching 48 point capsules |
| `Views/NextStepsView.swift` | Tasks tab |
| `Views/ActionsTabView.swift` | Lawyers and call scripts. iPhone opens it from Tasks. On Mac it is the Lawyers sidebar item |
| `Views/ProfileView.swift` | Profile tab: name, photo, account, case, about |
| `Views/CoverHeaderView.swift` | The case cover sheet |
| `CaseLaw/` | CanLII search (iPhone), through the `canlii-app` proxy |

## Checks

- `tools/check-no-case-content.sh` scans the source for case terms. The live page is checked
  with curl against `.leakterms`. Both must pass before a deploy.
- `tools/decode-check.swift` decodes a pulled brief with the app's own models, to catch rows the
  apps would silently drop.
- `tests/main.swift` is a runnable check for the checklist id scheme in `ChecklistIndex.swift`. CI
  runs it from `.github/workflows/test.yml`.
- `tools/test-leverage.mjs` checks the leverage math in `web/script.js` under Node. CI does not run it.
- `.github/workflows/native-release.yml` builds the desktop packages and a debug Android APK from
  `kmp/`, on a `native-v*` tag or by hand.

## Gotchas

- Case content must never appear in source or the public page. A clean live page does not mean
  a clean repo, which is why there are two checks.
- Cases are a fixed set (`CaseID` natively, the `CASES` registry on the web). A new account's
  brief uses the first slot until case editing lands.
- Old names stay on purpose: bundle id `com.nulljosh.brief`, URL scheme `litigate://`. The old Pages
  project `litigate` stays up only to 301 old hosts to temida.jaybulb.com.
