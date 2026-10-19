# kmp

Kotlin Multiplatform module for Temida. It holds a shared Compose UI for Android and desktop, built with Gradle. The Kotlin package is `com.nulljosh.litigate`, the app's old name.

It still signs in against the Supabase project the apps used before jaybulb-api. The iPhone app, the Mac app and the web app do not use this module.

This module is not shipped. `.github/workflows/native-release.yml` can build its desktop packages and a debug Android APK, on a `native-v*` tag or by hand. The builds are uploaded as workflow artifacts. Nothing is published to a store.
