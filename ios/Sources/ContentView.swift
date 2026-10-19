import SwiftUI

/// Five tabs, the system tab bar, labels under every icon. The brief reads top to bottom:
/// what happened (Case), what to do (Next), what it is worth (Money), the paper (Files), and you (Profile).
struct ContentView: View {
    @Environment(Store.self) private var store
    // A `-tab N` launch argument opens tab N, for screenshots without a tap.
    @State private var selectedTab = UserDefaults.standard.integer(forKey: "tab")

    var body: some View {
        TabView(selection: $selectedTab) {
            CaseTabView()
                .tabItem { Label("Case", systemImage: "doc.text") }
                .tag(0)
            NextStepsView()
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .tag(1)
            MoneyTabView()
                .tabItem { Label("Money", systemImage: "chart.bar") }
                .tag(2)
            DocumentsTabView()
                .tabItem { Label("Files", systemImage: "folder") }
                .tag(3)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(4)
        }
        .tint(.brandSlate)
        .id(store.revision)
        .sensoryFeedback(.selection, trigger: selectedTab)
        // a tap for one task ticked or unticked, not for the whole list arriving on load
        .sensoryFeedback(trigger: store.completedItems) { old, new in abs(old.count - new.count) == 1 ? .selection : nil }
    }
}
