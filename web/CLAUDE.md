# temida/web

Vanilla JS PWA for Temida. Live at temida.jaybulb.com (Cloudflare Pages project `themis`; old litigate., atticus. and docket. hosts 301 here).

## Stack: HTML + CSS + vanilla JS, no framework, spark-client.js (same-origin)

## Key files
- `index.html`: the signed-out landing page (its own `<main class="lp-main">`, so app markup goes into `.page > main`), the new-user empty state and the tweaks panel. The web has no tab bar; the tabs are native only.
- `#authOverlay` is the whole signed-out surface, a public landing page:
  - Nav: Features and Download links.
  - Hero: the "Named for Temida" kicker, the engraved Temida figure (`temida.svg#art`), and scroll parallax. The background moves at 40% of scroll and the copy at 15%, then fades. Off under reduced motion. The landing scrolls inside `#authOverlay`.
  - Features: five cards. Case, Tasks, Money and Files match the app tabs. The fifth, Private, is about the account.
  - Download: the App Store badge for iPhone, "Coming soon" for Mac, and a button that opens the web app.
  - Footer: the wordmark band (`footer-shader.js`, WebGL, runs only while the landing is on screen), icon buttons (App Store, create account, log in, privacy, brand kit, portfolio, back to top), and a language picker (`i18n.js`: en, fr, es, zh-Hans, zh-Hant, pa).
  - `#authModal` opens from any `[data-auth="login"|"register"]` button. `auth.js` owns that wiring at the bottom of the file; the ids inside the card are unchanged.
- Colours: white surfaces and slate accent from `brand/BRAND.md`, set at the end of `style.css` on
  `body[data-theme]`. Headlines in Temida Serif (`fonts/`, `tokens.css`). Brand kit page: `brand/index.html`.
- `script.js` — all logic: data fetch/render, DB sync, tweaks
- `auth.js` — sign-in, private markup injection, the splash and new-account onboarding (its markup is a template here, not in index.html, to keep the page under the token limit)
- `style.css` — dark/light themes, mobile-first; the brand overrides sit at the end

## Auth
- Email + password, two-step flow. **Multi-user**: step 2 offers both **Sign in** and **Create
  account** (`_sb.auth.signUp`). The old `ALLOWED_EMAIL` single-user gate is removed.
- New users get their own isolated account, a three-step onboarding on first sign-in, and start with **no briefs** — `fetchCaseData` finds no
  `brief_data:cases` row, `CASES()` falls back to empty arrays (no crash), and `#emptyState` shows.
  An account with no `fragments` row gets the shell page from `auth.js` (`SHELL`): the brief's TITLE and empty
  Facts, Grounds, Witnesses, Deadlines and Lawyers lists, with the case tabs and owner status hidden (`body[data-shell]`).
  The owner's layout keeps its fixed fact sheet and witness cards; `renderFacts()` and `renderWitnesses()` list only
  what those do not already show.
  Every render function returns early when its section is missing, so a layout without one still loads.
  `author.js` adds "+ Add fact", "+ Add ground", "+ Add witness", "+ Add deadline" and "+ Add lawyer" under those lists, and Edit and Remove under each one. It reads the `cases` row fresh, finds the row by content, changes it, and writes the whole value back (v9, same shapes as the apps).
- Backend: jaybulb-api (api.jaybulb.com) through `spark-client.js`. Reset links come back with
  `?recovery_token=` and finish in the same modal.

## Multi-user isolation
jaybulb-api returns only the signed-in user's own rows from every `brief_*` table. The owner's
private config tables from the Supabase days are not carried over.

## Tables
- `brief_data` — `{ user_id, key, value }`, scoped to the owner by jaybulb-api table rules.
  `key='cases'` holds all case/scenario/lawyer/script content (was previously hardcoded in
  `script.js` — moved out so nothing sensitive is committed to git).
- `brief_journal` — `{ user_id, date, text }`
- `brief_documents`: `{ user_id, date, title, text }`
- `brief_checklist` — `{ user_id, item_index, completed }`
- `brief_lawyer_status` — `{ user_id, lawyer_id, status }`
- ~~`get_brief_data_by_token(p_token text)`~~ — **dropped 2026-08-10.** SECURITY DEFINER,
  granted to `anon`, hardcoded the owner uid, returned the whole dossier to any bearer of
  `scrape_token` with no expiry. Its token row was already revoked 2026-07-28 (renamed to
  `scrape_token_revoked_20260728`), so it had been returning NULL since. There is now no
  anon-callable path to the dossier — every read goes through RLS on a real session.

## Deploy
**Cloudflare Pages project `themis`** — direct-upload, NOT git-connected, so `git push`
deploys nothing. Run `./deploy.sh` from this directory; it stages the publish set into a
temp dir, injects `window.APP_CONFIG`, and calls `wrangler pages deploy`.


## Cache busting
Bump the `?v=` on every CSS or JS file you change. Current values:
- `index.html`: `tokens.css?v=4`, `style.css?v=83`, `footer-shader.js?v=2`, `i18n.js?v=13`, `auth.js?v=59`
- `auth.js` appends `script.js?v=54`. Bump it there, not in `index.html`.
- `script.js` appends `webmcp.js?v=2` and `author.js?v=8`; `i18n.js` loads `i18n.json?v=11`.

`sw.js` has `CACHE = 'themis-v1'`. It is network-first, with the cache only as an offline fallback,
so the name rarely needs a bump.

## Screenshot capture
There is no PDF export. `document.body.dataset.ready = '1'` is set after `loadChecklistFromDB()`
resolves (the last step of the auth+data pipeline). Wait for `body[data-ready]` before capturing,
so the live projection is rendered. Works with claude-in-chrome, Puppeteer, or any headless tool.

## Deep links
- `?case=<key>`: selects the active case on load (`script.js`). Any key in the `CASES` registry works, CASE-0004 included.
- `?token=<opaque token>` is **gone** (2026-08-10), as is the older `?pin=7743`. Sharing a
  brief without a session is not supported — if it comes back it needs expiry and a scoped
  payload, not a whole-dossier RPC.

## Resilience
The backend client is a dependency. `script.js` guards client creation in a try/catch and the DB
loaders early-return when `_sb` is null, so a CDN failure degrades to a read-only render
instead of a blank page.

## Platforms
- Web: `web/` → temida.jaybulb.com
- iOS: `ios/`
- macOS: `macos/`

Lawyer contact info lives in the `brief_data` table (`key='cases'`) on jaybulb-api, not in this repo.
**SECURITY NOTE, RESOLVED 2026-07-28** (re-verified 2026-09-11, 0 leak-term matches on the
live site): the live site used to serve case files to unauthenticated users — `#authOverlay`
was CSS-only, so view-source/curl bypassed it and pulled 42 matches on real party names. Fixed
by moving all static case prose (hero titles, `.facts` cover sheets, `.next-action`, clock
captions, risk paragraphs) into `brief_data` key='fragments', RLS-scoped to the owner; `auth.js`
fetches and injects it before `script.js` runs. See root `CLAUDE.md` for the two-part acceptance
test (`curl` + `tools/check-no-case-content.sh`) that gates this going forward — the source scan
is required because the native side (iOS/macOS) hardcoded the same content separately and the
site-only check missed it for a month. iOS/macOS mirror this pattern as of 2026-06-21 — see
`ios/CLAUDE.md`.
