# Temida loop handoff (2026-10-19, evening)

## What the loop is

A `/loop` that moves Temida toward v100 one shippable step at a time. The landing page is the first job. Each step is checked on phone and desktop, in light and dark, with the leak checks at 0. Docs stay at 100 percent, the repo keeps 0 open GitHub issues and 0 stale branches, and PRs merge only when they are safe. Case content never leaves the machine. The roadmap is `roadmap.md`, under "Road to v100".

## Where things stand

- The landing and the signed-in web app run in six languages: English, French, Spanish, Simplified Chinese, Traditional Chinese and Punjabi. The signed-in shell has zero accessibility problems in an automated check, on light and dark, phone and desktop.
- The landing is now temida.jaybulb.com. The old litigate and atticus hosts redirect there.
- You can add facts, deadlines and lawyers to a case from the app. iPhone and Mac have a + menu on the Case tab, and the web has + Add buttons under the facts, the lawyers and the timeline. Each save reads the case fresh, adds one item and writes it back.
- The demo scenarios showed 0 percent because of a demo data bug. That is fixed.
- Docs for the web and iPhone are synced, and the v9 line in the roadmap is current.
- The promo video was removed from the landing at Joshua's request. It must not come back.
- The save test passed on the web and iPhone with the QA account in `.env.qa` (`node tests/web/save.mjs`). Check the owner's page with `tests/web/owner.mjs`, which prints only booleans. Never screenshot the owner's signed-in page.
- Grounds and witnesses can be added on every platform (`node tests/web/grounds.mjs`).
- v10 deadlines: a deadline can follow a BC rule (2-year basic, 15-year ultimate, 2-month municipal notice). The due date and cite are worked out once on save, on web, iPhone and Mac. `node tests/web/deadlines.mjs` checks the date math and a save on the QA account.
- Still open for case authoring: the Mac save test and the items under "Case authoring, still open" in `roadmap.md`.
- Earlier: the rename to Temida, the new logo on every icon, the onboarding and splash, the Profile with name and avatar, the Tasks tab, and the iPhone launch that dropped from 14 seconds to 4.
- Repo: 0 open issues on GitHub. The four authoring items stay in `roadmap.md` until they are done, so mirroring them to issues was skipped.

## Next, in order

1. The landing at A+ on phone and desktop, light and dark. It needs a real background (not plain white), parallax on the header, and the footer shader visible.
2. Docs to 100 percent, and a refreshed `architecture.svg`.
3. Bug hunt, the way the facts decoder bug was found. Make every brief array decode lossy. Fix case titles so they come from `fragments.native`.
4. iPhone simulator QA with screenshots. No case content goes off the machine.
5. The store name is Temida, locked 2026-10-19. Done.
6. The Mac App Store record and the first Mac build.
7. An iOS 1.1 build with the new name and icon. Screenshots use demo data only.
8. Roadmap v8: empty states that say what to do next, haptics, and VoiceOver labels on every control.
9. Roadmap v9: the four open authoring items above.
10. Roadmap v10, the rest: a discoverability helper. Reminders already follow an edited deadline.
11. Keep simplifying the UI.

## Restart prompt

```
/loop QA the Temida landing page (~/Documents/Code/temida/web, live at temida.jaybulb.com; the old litigate. and atticus. hosts 301 there) until A+: a real background (not plain white), parallax on the header, footer shader visible, phone and desktop, light and dark. Then docs to 100% and a refreshed architecture.svg. Also queued from Joshua: hunt bugs like the facts decoder (make every brief array decode lossy, fix case titles from fragments.native), iPhone simulator QA with screenshots (no case content sent off the machine), roadmap to v100, keep simplifying UI. No promo video on the landing; it was removed at Joshua's request and must not come back. Case content never leaves the machine.
```
