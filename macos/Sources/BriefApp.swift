import SwiftUI

@main
struct BriefApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            Group {
                if store.launching {
                    SplashView()
                } else if store.needsSignIn {
                    SignInView()
                } else if store.needsOnboarding {
                    OnboardingView()
                } else {
                    ContentView()
                }
            }
            .environment(store)
            .task { await store.checkSession() }
            .animation(.easeInOut(duration: 0.35), value: store.launching)
        }
        .defaultSize(width: 1100, height: 750)
    }
}
