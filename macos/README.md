<img src="../web/icon.svg" width="80">

The Mac app for Temida. Same account and data as [temida.jaybulb.com](https://temida.jaybulb.com).

A sidebar with Case, Tasks, Money, Lawyers, Files and Profile. The models and some shared views
(sign-in, onboarding, profile, Tasks) are symlinks into `ios/Sources`, so both apps change together.
The case tabs (Case, Money, Lawyers, Files) are Mac copies.

```bash
cd macos && xcodegen generate && open Temida.xcodeproj
```

Bundle `com.nulljosh.brief` · Team `QMM486NPYC` · macOS 14+. No App Store record yet.
