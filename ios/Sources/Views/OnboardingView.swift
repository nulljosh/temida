import SwiftUI

/// Shown while the session check runs. The mark matches the launch screen, then settles as the
/// wordmark rises in. Reduce Motion skips the movement.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settled = false

    var body: some View {
        VStack(spacing: 14) {
            Image("BrandMark")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.brandSlate)
                .frame(width: 88, height: 88)
                .scaleEffect(settled ? 1 : 1.12)
                .accessibilityHidden(true)
            Text("Temida")
                .font(.temidaSerif(34))
                .opacity(settled ? 1 : 0)
                .offset(y: settled ? 0 : 10)
        }
        .accessibilityElement(children: .combine)
        .offset(y: settled ? 0 : 24) // starts centred on the mark, like the launch screen
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(light: .white, dark: .black))
        .onAppear {
            if reduceMotion { settled = true } else {
                withAnimation(.spring(duration: 0.8, bounce: 0.2).delay(0.1)) { settled = true }
            }
        }
    }
}

/// First sign-in on a new account: welcome, your name, your first brief. Shared by iOS and macOS.
struct OnboardingView: View {
    @Environment(Store.self) private var store
    @State private var step = 0
    @State private var name = ""
    @State private var brief = ""
    @State private var saving = false
    @FocusState private var typing: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(i <= step ? Color.brandSlate : Color.secondary.opacity(0.25))
                        .frame(width: i == step ? 24 : 8, height: 8)
                }
            }
            .padding(.top, 24)
            .animation(.spring(duration: 0.4), value: step)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(step + 1) of 3")

            Spacer()
            Group {
                switch step {
                case 0: welcome
                case 1: nameStep
                default: briefStep
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 420)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))
            .id(step)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(.brandSlate)
        .onAppear { name = store.profile["full_name"] ?? "" }
    }

    private var welcome: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Image("BrandMark").resizable().renderingMode(.template)
                    .foregroundStyle(Color.brandSlate).frame(width: 64, height: 64)
                    .accessibilityHidden(true)
                Text("Welcome to Temida").font(.temidaSerif(30)).accessibilityAddTraits(.isHeader)
                Text("Your case, in one brief.").foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 18) {
                promise("lock", "Private to you", "Only your account can read your briefs.")
                promise("doc.text", "Everything in one place", "Facts, people, dates and money, in order.")
                promise("checklist", "Always know the next step", "Send any step to Reminders or Calendar.")
            }
            Button("Get Started") { advance() }.buttonStyle(Capsule48(prominent: true))
            Text("Planning aid, not legal advice.").font(.footnote).foregroundStyle(.tertiary)
        }
    }

    private var nameStep: some View {
        VStack(spacing: 20) {
            heading("What should we call you?", "Your name shows on your profile. You can change it later.")
            field(TextField("Your name", text: $name))
                .onSubmit(advance)
                #if os(iOS)
                .textContentType(.name)
                #endif
            Button("Continue") { advance() }.buttonStyle(Capsule48(prominent: true))
            Button("Skip") { name = store.profile["full_name"] ?? ""; advance() }.buttonStyle(.borderless).foregroundStyle(.secondary)
        }
    }

    private var briefStep: some View {
        VStack(spacing: 20) {
            heading("Name your first brief", "Usually the parties, like Smith v. Acme. One brief per matter.")
            field(TextField("Smith v. Acme", text: $brief)).onSubmit { finish(brief) }
            Button { finish(brief) } label: {
                if saving { ProgressView().controlSize(.small).accessibilityLabel("Saving") } else { Text("Start My Brief") }
            }
            .buttonStyle(Capsule48(prominent: true))
            .disabled(saving || brief.trimmingCharacters(in: .whitespaces).isEmpty)
            Button("Later") { finish("") }.buttonStyle(.borderless).foregroundStyle(.secondary).disabled(saving)
        }
    }

    private func advance() {
        typing = false
        withAnimation(.spring(duration: 0.45)) { step += 1 }
        Task { try? await Task.sleep(for: .seconds(0.5)); typing = true } // once the new field exists
    }

    private func finish(_ title: String) {
        saving = true
        Task { await store.finishOnboarding(name: name, briefTitle: title) }
    }

    private func heading(_ title: LocalizedStringKey, _ sub: LocalizedStringKey) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.temidaSerif(26)).multilineTextAlignment(.center).accessibilityAddTraits(.isHeader)
            Text(sub).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
    }

    private func promise(_ icon: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(Color.brandSlate).frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func field(_ f: TextField<Text>) -> some View {
        f.focused($typing)
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }
}

extension Store {
    /// The same empty workspace the web app writes (auth.js emptyCasesValue).
    static func emptyBrief(_ title: String) -> [String: Any] {
        var v: [String: Any] = ["TITLE": title, "SCALE": [String: Any](), "CALL_SCRIPT": "", "FAMILY_CALL_SCRIPT": "", "MUNI_CALL_SCRIPT": ""]
        for k in ["GROUNDS", "SCENARIOS", "STACK_HEADS", "LAWYERS", "TIMELINE", "CHECKLIST", "JOURNAL_SEED",
                  "FAMILY_GROUNDS", "FAMILY_SCENARIOS", "FAMILY_STACK_HEADS", "FAMILY_LAWYERS", "FAMILY_CHECKLIST", "FAMILY_TIMELINE",
                  "MUNI_GROUNDS", "MUNI_SCENARIOS", "MUNI_STACK_HEADS", "MUNI_LAWYERS", "MUNI_CHECKLIST", "MUNI_TIMELINE"] { v[k] = [Any]() }
        return v
    }
}
