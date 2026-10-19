import SwiftUI

@main
struct BriefApp: App {
    @State private var store = Store()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if store.launching {
                    SplashView()
                } else if store.needsSignIn {
                    SignInView()
                } else if store.biometricLocked {
                    BiometricLockView()
                } else if store.needsOnboarding {
                    OnboardingView()
                } else {
                    ContentView()
                }
            }
            .environment(store)
            .task { await store.checkSession() }
            .onChange(of: scenePhase) { _, new in
                if new == .background { store.biometricLocked = true }
            }
            .animation(.easeInOut(duration: 0.35), value: store.launching)
            .overlay { if !store.launching && !store.needsSignIn && !store.needsOnboarding { WhatsNewSheet() } }
        }
    }
}
