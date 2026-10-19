import SwiftUI

struct ContentView: View {
    @Environment(Store.self) private var store
    @State private var selection: String? = "case"

    var body: some View {
        @Bindable var store = store
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $selection) {
                Section {
                    Label("Case", systemImage: "doc.text").tag("case")
                    Label("Tasks", systemImage: "checklist").tag("next")
                    Label("Money", systemImage: "chart.bar").tag("money")
                    Label("Lawyers", systemImage: "person.2").tag("actions")
                    Label("Files", systemImage: "folder").tag("documents")
                }
                Section {
                    Label("Profile", systemImage: "person.crop.circle").tag("profile")
                }
            }
            .navigationTitle(store.activeCase.title)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                if CaseID.shown.count > 1 {
                ToolbarItem {
                    Menu {
                        ForEach(CaseID.shown) { c in
                            Button {
                                store.activeCase = c
                            } label: {
                                if store.activeCase == c { Label(c.title, systemImage: "checkmark") }
                                else { Text(c.title) }
                            }
                        }
                    } label: {
                        Label(store.activeCase.rawValue, systemImage: "folder")
                    }
                }
                }
            }
        } detail: {
            switch selection {
            case "next":    NextStepsView()
            case "profile": ProfileView()
            case "money":   MoneyTabView()
            case "actions": ActionsTabView()
            case "documents": DocumentsTabView()
            default:        CaseTabView()
            }
        }
        .tint(.brandSlate)
        .id(store.revision)
    }
}
