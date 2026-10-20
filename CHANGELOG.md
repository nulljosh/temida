# Changelog: Temida

## [v6.4.0] - 2026-10-19

### A clean PDF for counsel
- Print on the web saves the brief as a clean PDF: no search box, no Edit, Remove or Add buttons.
- Share as PDF on the Case tab in the iPhone and Mac apps: facts, deadlines, witnesses and grounds, made on the device.
- Grounds added without a citation no longer show an empty grey box.

### Search
- Search the open case on web, iPhone and Mac. It filters facts, witnesses and grounds (and deadlines and lawyers on the web) on the device; nothing is sent anywhere.

### Deadlines worked out from BC law
- A deadline can follow a rule: the 2-year basic or 15-year ultimate limitation period (Limitation Act, BC) or the 2-month notice to a municipality (Local Government Act, BC). Enter the start date and the due date and the section it comes from are saved with it. Web, iPhone and Mac.
- Deadline dates show in the viewer's language. In the apps a deadline can go to Reminders or Calendar from its long-press menu, and a reminder moves when its deadline is edited.

### Fixed the same day
- The signed-in web app was blank for a few hours after the new landing went up: the landing's own page body took the case markup. Fixed.
- New accounts on the web crashed on sections only the owner's layout has. They now get a page with the brief's title, facts, deadlines and lawyers.
- Facts can be added, edited and removed on the web.
- Grounds and witnesses can be added, edited and removed on the web, iPhone and Mac (next build for the apps).
- Accounts without the owner's layout get one brief on iPhone and Mac: no case picker, no empty sections.
- iPhone and Mac show the brief's own name instead of the case number for accounts without a custom layout (next build).

### Renamed to Temida
- Renamed from Litigate and Atticus to Temida. The bundle id and the `litigate://` URL scheme keep their old names.
- New landing page at temida.jaybulb.com: engraved Temida hero, six languages (English, French, Spanish, Simplified Chinese, Traditional Chinese, Punjabi), and an accessibility pass.
- Onboarding and the animated splash on every platform. New accounts get a three-step welcome.
- Profile has a name and an avatar (uploaded or generated).
- The next-steps list is called Tasks on every platform.

## Earlier (May 2026)
- v6.3.0: one dataset across web, iPhone and Mac, and a limitation overlay.
- v6.2.0: deploy fix for a stale web build, and a safer backend client that degrades to read-only.
- v6.1.0: checklist sorted by leverage, undone items first.
- v6.0.0: a second case type, the cover header and stamp, and a risk note on every ground.
- v5.0.0: case picker on iPhone and Mac, Face ID lock, password sign-in, sync for the checklist, lawyer status and journal.
- v4.0.0: the Mac app.
- v3.0.0: no innerHTML, sign-in and sync, the journal, lawyer status, system theme.
- v2.0.0: the iPhone app.
- v1.0.0: the web app: grounds, damages stack, checklist.
