# Temida loop handoff (2026-10-19, night)

## What the loop is

A `/loop` that moves Temida toward v100 one shippable step at a time. The landing page is the first job. Each step is checked on phone and desktop, in light and dark, with the leak checks at 0. Docs stay at 100 percent, the repo keeps 0 open GitHub issues and 0 stale branches, and PRs merge only when they are safe. Case content never leaves the machine. The roadmap is `roadmap.md`, under "Road to v100".

## Where things stand

- v11.0.0. Search covers the case, the journal and the files on web, iPhone and Mac. Share as PDF and the BC deadline rules run on the device only.
- The landing holds A+ on phone and desktop, light and dark: slate hero, parallax, footer shader, 0 leak terms, no video. The promo video must not come back.
- Every brief list decodes lossy, nested ones too, so one bad row never drops a case.
- The declutter pass is done on every platform. Web: Edit and Remove show on hover or focus. Native: plain section headers, no repeated Money totals, no empty cards, one menu per task, Mac panel titles that match the sidebar.
- iPhone QA: all four tabs checked on the demo file (`-demoFile`). Mac QA: all five panels checked with `-demoJSON`; see `macos/CLAUDE.md` for the launch line. Both use fictional data only.
- Web translations: every editing label, the search box and the BC rule labels translate in all six languages; `node tests/web/i18n.mjs` guards it. The landing kicker says Temida in every language.
- Blocked: every `asc` command hangs on a macOS keychain password dialog for the App Store Connect key. Only Joshua can type that password. Until then skip store work.
- Docs, README, WHITEPAPER and `architecture.svg` are current for v11. The repo has 0 open issues and no stale branches.
- Tests: `node tests/web/save.mjs`, `grounds.mjs`, `deadlines.mjs` and `search.mjs` on the QA account in `.env.qa`. `owner.mjs` prints booleans only. Never screenshot the owner's signed-in page.

## Next, in order

1. The Mac App Store record and the first Mac build.
2. An iOS 1.1 build with the new name and icon. Screenshots use demo data only.
3. App Privacy answers and the privacy URL with the next store version.
4. A VoiceOver walk on a real device.
5. Real files and OCR in Files waits on Joshua's call. Do not start it.
6. Keep simplifying the UI. Roadmap to v100 is in `roadmap.md`.

## Restart prompt

```
/loop QA the Temida landing page (~/Documents/Code/temida/web, live at temida.jaybulb.com; the old litigate. and atticus. hosts 301 there) until A+: a real background (not plain white), parallax on the header, footer shader visible, phone and desktop, light and dark. Then docs to 100% and a refreshed architecture.svg. Also queued from Joshua: hunt bugs like the facts decoder (make every brief array decode lossy, fix case titles from fragments.native), iPhone simulator QA with screenshots (no case content sent off the machine), roadmap to v100, keep simplifying UI. No promo video on the landing; it was removed at Joshua's request and must not come back. Case content never leaves the machine.
```
