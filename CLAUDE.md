# Temida

v6.4.0. Cross-platform litigation tool (ex-Themis, ex-Atticus, ex-Litigate; renamed Temida 2026-10-19 because "Themis" is taken on the App Store). Web + iOS + macOS. Public repo `nulljosh/temida`.

## Cases
Four case slots: CASE-0001 to CASE-0004. What is in them lives only in the owner's `brief_data` rows,
never in this repo, its docs or its history. Source files and scans stay off the repo.

## Structure

```
temida/
  web/        Vanilla JS PWA: temida.jaybulb.com (old litigate., atticus. and docket. hosts 301 here)
  ios/        SwiftUI iOS 17+
  macos/      SwiftUI macOS 14+
```

All case content, structured data AND display prose (party names, cover blurbs, risk
analysis, strategy), lives in the jaybulb-api `brief_data` table, scoped to the owner by per-table rules. Web reads
`key='fragments'` (`hero`/`main`/`titles`) via `auth.js`; native reads the same row's
`native` object via `Store.loadFragments()` into `NativeFragments.swift`. Source holds
types and empty containers only.

**Acceptance test is two-part**, both must pass:
1. Live site: `curl -s https://temida.jaybulb.com/ | grep -ciE "$(paste -sd'|' .leakterms)"` → 0
2. Source scan: `./tools/check-no-case-content.sh` → exit 0 (greps `ios/ macos/ web/`)

The site-only test is what let the native leak go untracked for a month, native source
hardcoded party names and strategy prose the whole time while the curl test passed green.
Never treat a green live-site check as "the repo is clean".

The repo is public since 2026-10-19, from one clean commit. The old history holds case prose and
lives only in the private repo `temida-private`. Never push it here. Run both checks before every push.

See `web/CLAUDE.md` and `ios/CLAUDE.md` for platform-specific details.

## Auth and data

Every platform signs in and syncs through **jaybulb-api** (api.jaybulb.com, Workers + D1), the same
backend as the other web apps. Web: `web/spark-client.js` (a Supabase-shaped client) and `auth.js`.
iOS and macOS: `ios/Sources/Models/API.swift` (session in the Keychain, refresh, email and password,
Sign in with Apple, Google code + PKCE, PostgREST-style rows) behind one shared `Store.swift`.
Supabase is gone from the native apps as of 2026-10-19.

Anyone can sign up; each account sees only its own briefs. New users start empty. Face ID locks
the iPhone app. Reset password goes through `/auth/recover` and finishes on the web app.

Next steps in the apps can be sent to Reminders or Calendar (EventKit, `Planner.swift`).

New accounts see a three-step onboarding (welcome, name, first brief) on their first sign-in, on
every platform. The gate is: no `onboarded` flag in `user_metadata` and no `brief_data` cases row,
so the owner account never sees it. Preview it without writing anything: `?onboarding` on the web,
`-forceOnboarding` in a debug app build. Returning sessions get an animated splash while the
case loads. Profile name and photo live in `user_metadata` (`full_name`, `avatar_url`/`avatar_seed`).

## Testing
The QA account lives in the gitignored `.env.qa` (Resend's test inbox, confirmed by hand in D1). Use it for any test that writes. Never write with the owner login in `.env`.

## Deploy

`web/` deploys to the Cloudflare Pages project `themis` (themis-8pe.pages.dev, served at temida.jaybulb.com).
The old project `litigate` only serves `_redirects`: litigate., atticus. and docket.jaybulb.com 301 to the same path on temida.jaybulb.com. Direct upload, not git-connected: run `web/deploy.sh`.
A push deploys nothing. The brand kit page ships at `/brand/`.

Native: `cd ios && xcodegen generate`, scheme `Temida`; same for `macos/`. The app icon is
`Temida.icon` (Icon Composer). Bundle id stays `com.nulljosh.brief`; URL scheme stays `litigate://`.

## The loop

The live `/loop` state, what shipped, what is next, and the restart prompt are in [docs/LOOP-HANDOFF.md](docs/LOOP-HANDOFF.md). Read it before resuming the loop.

## App Store ship history (condensed 2026-09-11)
App 6787857503, **LIVE and publicly listed** (store listing renamed Temida 2026-10-19 with 1.1.0): 1.0.1, 1.0.2, 1.0.3 all READY_FOR_SALE. 1.0.3 was pulled from sale 2026-08-27 because the live 1.0.2 App Store screenshots leaked real case data (party names, incident narrative, damages figures — see roadmap.md "From Apple Notes (imported 2026-08-27)"); restored to sale once 1.0.3 cleared review, confirmed live again via `asc apps public view --app 6787857503 --country us` 2026-09-11. Renamed Casewright → Litigate 2026-07-18. Sign in with Apple was removed from the UI 2026-07-22 (was the actual 1.0.1 rejection cause, Guideline 1.5/2.1), then re-added app-side 2026-08-28 alongside Google sign-in (see roadmap.md). Email/password auth verified working end-to-end. macOS has no ASC app record yet (bundle `com.nulljosh.brief`, zero builds), see roadmap.md.
