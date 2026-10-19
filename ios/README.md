<img src="../web/icon.svg" width="80">

The iPhone app for Temida. Same account and data as [temida.jaybulb.com](https://temida.jaybulb.com).

Five tabs: Case, Tasks, Money, Files, Profile. Case content loads at runtime from your own
account through jaybulb-api; none of it lives in this repo. Face ID locks the app when it goes
to the background.

```bash
cd ios && xcodegen generate && open Temida.xcodeproj
```

Bundle `com.nulljosh.brief` · Team `QMM486NPYC` · iOS 17+. Launch arguments for screenshots:
`-tab N` opens a tab. `-forceOnboarding` (debug builds) shows the welcome without saving anything.
`-demoFile <path>` (debug builds) loads a demo brief from that JSON file, such as
`tools/demo-brief.json`, and makes no network calls.
