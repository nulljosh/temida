# Temida roadmap (ex-Atticus, ex-Litigate)

## Store name (2026-10-19)
"Themis" is taken on the App Store, so everything became Temida (Themis in Polish, Czech and Croatian) on 2026-10-19: store listing, brand, site, apps and repo.

## Road to v100 (written 2026-10-19)
Web is v6.4.0, the App Store build is 1.0.3 and still named Litigate. Each line is one shippable step.
Rule for every step: phone and desktop, light and dark, leak check at 0, shots in the PR.

**v7: the name and the store.** Ship iOS 1.1 as Temida (name, subtitle, icon, screenshots with
demo data only, never real case content). Mac app record and first Mac build. Canonical URLs move to
temida.jaybulb.com. App Store link and badge on the landing go live with the renamed listing.
Done 2026-10-19: canonical URLs on temida.jaybulb.com, new column-and-scales icon. Open: the store listing
needs the Mac record.

**v8: native polish.** Web accessibility done 2026-10-19 (0 axe issues on landing, sign-in, privacy and brand kit; app shell labels in sentence case). ~~iPhone simulator QA of every tab with screenshots.~~ ~~Serif headlines in the apps
(bundle Temida Serif).~~ (done 2026-10-19) ~~Case covers from fragments on every case~~ (done; titles, tabs and pickers keep the case number on purpose, so party names never show in a window title or a screen share). ~~Empty states that say
what to do next~~ (done 2026-10-19: Case, Tasks, Money and Files). ~~Haptics~~ (done 2026-10-19: tab switch, task tick, save). VoiceOver: the icon-only controls are labelled; a full VoiceOver walk on a device is still open.

**v9: write your own case.** Case-authoring on web and native: add facts, grounds, witnesses,
lawyers, deadlines without touching the database. ~~Facts, deadlines and lawyers from the + menu in the iPhone and Mac apps~~ (done 2026-10-19). ~~Editing and removing~~ (done 2026-10-19: long press or right click in the apps, Edit and Remove on the web). Still to do: grounds and witnesses, and facts on the web (lawyers and deadlines have a web form; the web does not show `FACTS` yet). ~~New users get a guided first brief.~~ (onboarding shipped 2026-10-19)

**v10: deadlines engine.** ~~Limitation clocks with the rule cited~~ (done 2026-10-19 on web, iPhone and Mac: pick
the 2-year basic or 15-year ultimate period from the BC Limitation Act, or the 2-month notice to a municipality,
enter the start date, and the due date and cite are saved with the deadline). ~~Every deadline can go to Reminders
and Calendar~~ (done in the apps, long press). ~~Keep the Reminders copy in sync when the deadline changes~~ (done 2026-10-19; Calendar has write-only access
and cannot read its event back, so a Calendar copy stays where it was). Open: a discoverability helper that asks when the claim was found.

**v11 to v20: the paper.** Documents with real files (PDF, photos), OCR, attach to facts. Evidence
timeline. Export a clean PDF brief for counsel. Share a read-only, expiring link scoped to one case.
~~Promo video on the landing~~ (made 2026-10-19 from tools/demo-brief.json, then taken off the landing at Joshua's request; demo mode stays for store screenshots). Search across everything.

**v21 to v40: counsel and courts.** Lawyer outreach tracker with email templates. CanLII search on
web and Mac. Forms for BC Civil Resolution Tribunal and Small Claims. Court filing checklists.
Cost and damages calculators with sources.

**v41 to v60: trust.** Passkeys and two-factor sign-in. Client-side encryption for case content.
Audit log of every change. Data export and delete in one tap. A security review before any public
push. French for Canada, then the 19 house languages. Web started 2026-10-19: landing, sign-in and onboarding in
English, French, Spanish, Simplified and Traditional Chinese and Punjabi. Next: the signed-in web app and the native apps.

**v61 to v80: everywhere.** Widgets for the limitation clock, Watch complication, Siri and Shortcuts,
Android through kmp/, iPad layout, offline first with sync.

**v81 to v100: help that thinks.** A private assistant that reads only your brief and suggests the
next step, finds gaps, and drafts letters, with every suggestion cited back to your own facts. The
/brief skill becomes an in-app feature. v100 is a brief a lawyer would accept as their intake file.

## ASC state VERIFIED 2026-09-11 (`asc versions list` + `asc apps public view`)

**iOS 1.0.1, 1.0.2, 1.0.3 all LIVE** (`READY_FOR_SALE`) and the app is publicly listed again
(restored from the 1.0.3 sale pull, see below). No macOS record exists.

Freeze lifted 2026-08-18 (Guideline 5.6 suspension expired). Submitted that day and now
WAITING_FOR_REVIEW: Curvely iOS 1.2.0, Wiretext iOS 1.1.0, Wordroot iOS 1.0, Healstack iOS 2.3.4.
**Held pending those four verdicts, never a batch:** Sparkjar iOS+Mac, BCGD iOS+Mac, Wordroot Mac,
Lexly Mac. All six are `asc validate` clean (0 errors, 0 blocking) with a VALID build attached, so
each is one `asc review submit` away. Do not submit until the in-flight verdicts land.

## P0 security leak, RESOLVED 2026-07-28
`litigate.heyitsmejosh.com` served the full case dossier (all 3 cases, party names) pre-auth as static prose in `web/index.html`/`script.js` and hardcoded in `ios/`/`macos/` views, the auth overlay was CSS-only, curl bypassed it entirely (42 hits on real party names). Real fix shipped 2026-07-28: all static case prose moved verbatim into Supabase `brief_data` key='fragments', RLS-scoped to the owner uid; `web/auth.js` fetches + injects it before `script.js` runs. Nothing scrubbed, nothing deleted (see `feedback_never_delete_case_data`). Verified anonymous + cache-busted: 0 leak-term matches across `litigate.heyitsmejosh.com`, `litigate.pages.dev`, `brief.heyitsmejosh.com`. Deploy path confirmed as Cloudflare Pages project `litigate` (direct-upload, not git-connected, `web/deploy.sh` handles it correctly as of 2026-08-04, also fails closed if `web/.env`/config injection is missing). Acceptance test lives in `CLAUDE.md` (two-part: live-site curl + `tools/check-no-case-content.sh` source scan, the source scan is the one that would have caught the native-side leak, the site-only check let it go untracked for a month).

Left open from the fix:
- [ ] Other accounts get a plain page (brief title, Facts, Deadlines, Lawyers) since 2026-10-19, not the full layout: the owner's layout and prose still live together in `fragments`. Splitting structure from content would give every account the grounds, money and clock sections.
- [ ] Rotate `CLOUDFLARE_DNS_TOKEN` (echoed into a session transcript). Needs the dashboard, the wrangler OAuth token only has `user:read`, can't create/revoke API tokens.

## App Store, Sign in with Apple / App Privacy (superseded, kept as plan of record)
> **App is LIVE**, `asc versions list --app 6787857503` shows 1.0.1 and 1.0.2 both READY_FOR_SALE, `asc review doctor` reports COMPLETE. Sign in with Apple was *removed* from the UI 2026-07-22 (was the actual 1.0.1 rejection cause) rather than fixed, the items below are only relevant if/when it's re-added.
- [ ] Re-add Sign in with Apple: needs two manual credentialed steps (Apple Developer portal, enable capability on `com.nulljosh.brief`, generate a Sign-in-with-Apple key with Team ID `QMM486NPYC`; Supabase dashboard → Auth → Providers → Apple, enable + register `com.nulljosh.brief`/`com.nulljosh.brief-macos` client IDs). Confirmed dashboard-only, `asc` has no auth-provider/Apple-portal commands.
- [ ] App Privacy declaration, ASC-web-UI-only, no public API. Needs a browser session via `/asc-web-relogin` to check/fix (should be: data collected = email + user content, linked to user, not tracking).

## Open
- [ ] App Store privacy policy URL: should be https://temida.jaybulb.com/privacy.html, which is already in the local metadata. Frozen until next version ships (app-info only editable during staged versions). (2026-09-02: Apple rejects the PATCH, "privacyPolicyUrl can not be modified in the current state", while the only app-info is READY_FOR_DISTRIBUTION; local metadata is already correct, so it goes through on the next version bump via metadata apply) [2026-10-04: README updated with signed-out web screenshots; Apple sign-in sheet dismiss bug fixed.]
- [ ] UI is pretty cluttered, app is shipped and works properly, but needs a decluttering pass.
- [ ] Ship a macOS version of Temida, no macOS app record exists in ASC yet (`asc apps list` shows only iOS; macOS target uses bundle `com.nulljosh.brief` with zero builds uploaded). Needs a new app record first (`asc-app-create-ui` dashboard flow), bigger scope than a re-ship.
- [ ] Needs app + website screenshots for README and splash screen, needs a simulator/browser session.

## App Store screenshots (queued 2026-08-11)
`ios/screenshots/1-signin.png` and `2-register.png` exist, no capture harness. Build one with the
`appstore-screenshots` skill (UITest target + mock launch arg + Snapfile), then run.
Copy the pattern from `talli/ios`: Snapfile needs
`xcargs("-skipPackagePluginValidation -skipMacroValidation")`, and the mock must cover
every network refresh path, not just `init`, see talli commit 7386f1d.

## From Apple Notes (imported 2026-08-11)

> Resume note, CORRECTED 2026-08-13: the `wip: partial work from /work notes ingest` commit (`b0f23bc`) was reviewed this session and is **complete and correct**, not half-finished. It is also **already pushed**, `origin/main` is at `96f6d6b`, two commits past it; the "unpushed" claim was stale (the same stale-unpushed note appeared in bookrank and talli this week). It fixed a real live bug, see below.

## Live bug fixed by `b0f23bc` (not yet deployed)
The theme bootstrap `document.body.dataset.theme = …` sat inside `<head>`, where `document.body`
is still `null`, so it threw on every page load and `data-theme` was never set. Pre-v38 CSS put
dark at `:root` and light at `body[data-theme="white"]`, meaning **the light-mode support added
2026-08-06 has never worked in production**; litigate.heyitsmejosh.com has been pinned dark since.
`b0f23bc` moves the script to the top of `<body>`. Confirmed every theme write in `script.js`
(`applySystem`, `window.__setTheme`) also targets `document.body`, so the whole path is consistent.
Still live-broken until the deploy above runs.

## Apple sign-in, Supabase side DONE 2026-08-18
`com.nulljosh.brief` and `com.nulljosh.brief-macos` are now registered client IDs on the shared
`spark` Supabase project, and the Apple provider is enabled. **No `.p8` key was needed**, that is
only for the web OAuth redirect flow; native `grant_type=id_token` validates against Apple's public
keys. The roadmap's "needs two manual credentialed steps / dashboard-only" note is superseded.
Remaining is app-side only: re-add the Sign in with Apple capability + button.

## Apple + Google sign-in, app-side DONE 2026-08-28
Added Sign in with Apple to iOS and macOS (commit 3ffc4c4). Added Google sign-in to both platforms via OAuth browser flow (commit 58af9b3), which also fixed a critical entitlements regression where a duplicate `entitlements:` key in project.yml silently dropped `com.apple.security.app-sandbox` and `com.apple.security.network.client` on macOS. Reference implementation tested on Healstack macOS.

**Joshua must physically test Apple/Google sign-in on macOS to verify system sheets work** (cannot be automated; requires Touch ID).

## Case authoring, still open (2026-10-19)
- [ ] Mac save test through the app's own window. Web and iPhone passed 2026-10-19 on the QA account: add, edit and remove on each, and each reads back what the other saved. Owner rows were hashed before and after and are unchanged. Rerun with `node tests/web/save.mjs`. The Mac runs the same save code by symlink and builds clean, but driving its window takes over the screen, so it waits for a moment the Mac is free.

## From Apple Notes (imported 2026-08-25)

- [ ] Background should match the animation style used in Bookrank etc., the animation behind the hero, or even the entire page background.
  Partly done 2026-08-28: the landing now has a page-wide animated background (drifting ruled paper,
  panning column grid, two slow graphite blooms). Still needs a side-by-side against Bookrank , 
  heyitsmejosh.com was unreachable from the session that built this, so the match is unverified.

## From Apple Notes (imported 2026-08-27)
  - [ ] Verify the 1.0.3 App Store screenshots themselves don't still show the same leaked case data — pulling the app closed the exposure window but didn't confirm the replacement screenshots are clean.

## CI cannot run the leak guard yet

`tools/check-no-case-content.sh` is the check worth gating on, but `.leakterms` is
gitignored by design, so a GitHub Actions run has nothing to match against and the script
exits with its "create it" error. Options: put the terms in a repo secret and write the
file in the workflow, or hash the terms and commit the hashes. Until one is chosen,
litigate has no CI, the Swift tests in tests/main.swift would need a macOS runner anyway.

## TODO
- Merge canlii-app (CanLII case-law search: API proxy + iOS + web) into litigate as a case-law search feature, instead of standalone project. canlii-app has its own ASC/api/web/ios — fold in, do not ship separately.
