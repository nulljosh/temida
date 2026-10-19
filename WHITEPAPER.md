# Temida Technical Whitepaper

**v6.4.0** | October 2026

Going to court without a lawyer is a lot of paper, spread across timelines,
grounds and documents that a caseworker or lawyer would normally track for
you. Temida keeps it in one place instead, for people running their own
cases.

Web, iOS and macOS. The code is private because it once held real case detail.
Live at [temida.jaybulb.com](https://temida.jaybulb.com).

## Case Data Model

Case content (grounds, timeline events, officers, lawyers, script/notes) lives
in one row of the `brief_data` table, `key='cases'`, not
hardcoded in the repo, because case facts change as ATIP responses and filings
come in and a redeploy shouldn't be required to update them. Web reads this
table directly. iOS/macOS mirror the same source of truth: `Store.loadCaseData()`
fetches on sign-in and `CaseDataMapper.swift` maps the JSON into native
`CaseData` / `FamilyCaseData` / `MuniCaseData` structs, which now hold only
type definitions and empty runtime-populated globals (the old bundled
`CaseData.json` was removed once this migration landed, since a bundled
copy is exactly the kind of drift this design exists to prevent). One
dataset, three clients, no drift between platforms.

A new account starts empty. Its first sign-in shows a three-step welcome (who you
are, then the name of your first brief), which writes the same empty brief shape on
every platform.

## Auth and Isolation

Every platform signs in through jaybulb-api, a Cloudflare Worker on D1 that the other
jaybulb apps share. The web takes email and password. The apps add Sign in with Apple and
Google. Each table only
ever returns the signed-in user's own rows, so one person's case can never show up in
another's account. Name and photo live on the account itself, so every device shows the
same ones. The iPhone app adds a Face ID lock on top of the session, because a phone left
unlocked is a likelier leak than a stolen password.

## Structure

```
temida/
  web/        Vanilla JS PWA
  ios/        SwiftUI, iOS 17+
  macos/      SwiftUI, macOS 14+
  kmp/        Kotlin Multiplatform, Android and desktop (not shipped)
  tools/      Checks and demo data
  tests/      Runnable check for the checklist id scheme
```

## Security / Privacy

Private repo. No case content ships in source or in the public page: the landing is an
empty shell until a signed-in user's own rows fill it, and two checks gate every
deploy (a scan of the live page and a scan of the source). Uploaded photos are
re-encoded on the device first, which drops their location data.

## License

Apache License 2.0. Copyright 2026, Joshua Trommel.
