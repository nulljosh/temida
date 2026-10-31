import AuthenticationServices
import SwiftUI

/// One screen, two steps: email, then password. Apple and Google below. Shared by iOS and macOS.
struct SignInView: View {
    @Environment(Store.self) private var store
    @Environment(\.webAuthenticationSession) private var webAuth
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focused: Field?
    @State private var apple = AppleSignIn()

    private enum Field { case email, password }
    private var address: String { email.trimmingCharacters(in: .whitespaces).lowercased() }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 12) {
                header
                if store.authStep == .email { emailStep } else { passwordStep }
                messages
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 380)
            Spacer()
            Text("Planning aid, not legal advice.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .tint(.brandSlate)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image("BrandMark")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.brandSlate)
                .frame(width: 56, height: 56)
                .accessibilityHidden(true)
            Text("Temida")
                .font(.temidaHeadline(34))
                .accessibilityAddTraits(.isHeader)
            Text("Your case, in one brief.")
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 20)
    }

    private var emailStep: some View {
        VStack(spacing: 12) {
            field { TextField("Email", text: $email) }
                .focused($focused, equals: .email)
                #if os(iOS)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .onSubmit(submitEmail)

            Button("Continue", action: submitEmail)
                .buttonStyle(Capsule48(prominent: true))
                .disabled(address.isEmpty)

            HStack(spacing: 12) {
                Rectangle().frame(height: 1).foregroundStyle(.quaternary).accessibilityHidden(true)
                Text("or").font(.footnote).foregroundStyle(.secondary)
                Rectangle().frame(height: 1).foregroundStyle(.quaternary).accessibilityHidden(true)
            }
            .padding(.vertical, 4)

            Button {
                apple.start(store)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo").font(.temidaText(18).weight(.medium)).accessibilityHidden(true)
                    Text("Sign in with Apple")
                }
            }
            .buttonStyle(Capsule48(prominent: true, fill: Color(light: .black, dark: .white), ink: Color(light: .white, dark: .black)))

            Button {
                Task { await google() }
            } label: {
                HStack(spacing: 10) {
                    Image("GoogleG").resizable().frame(width: 18, height: 18).accessibilityHidden(true)
                    Text("Sign in with Google")
                }
            }
            .buttonStyle(Capsule48(prominent: false))
        }
    }

    private var passwordStep: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(address.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.brandSlate, in: Circle())
                    .accessibilityHidden(true)
                Text(verbatim: address).foregroundStyle(.secondary)
                Spacer()
                Button("Change") {
                    store.resetAuthStep()
                    password = ""
                    focused = .email
                }
                .font(.subheadline)
            }

            field { SecureField("Password", text: $password) }
                .focused($focused, equals: .password)
                .onSubmit(submitPassword)

            Button("Sign In", action: submitPassword)
                .buttonStyle(Capsule48(prominent: true))
                .disabled(password.isEmpty)

            Button("Create Account") { Task { await store.signUp(email: address, password: password) } }
                .buttonStyle(Capsule48(prominent: false))
                .disabled(password.count < 8)

            Button("Forgot password?") {
                Task {
                    if await store.resetPassword(for: address) {
                        store.signInNotice = String(localized: "If that email has an account, a reset link is on its way.")
                    }
                }
            }
            .font(.subheadline)
            .padding(.top, 4)
        }
    }

    @ViewBuilder private var messages: some View {
        if let err = store.signInError {
            Text(verbatim: err).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
        }
        if let note = store.signInNotice {
            Text(verbatim: note).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
    }

    private func field<F: View>(@ViewBuilder _ content: () -> F) -> some View {
        content()
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }

    private func submitEmail() {
        store.confirmEmail(email: address)
        if store.authStep == .password { focused = .password }
    }

    private func submitPassword() {
        Task { await store.signIn(email: address, password: password) }
    }

    private func google() async {
        guard let callback = try? await webAuth.authenticate(using: store.googleURL,
                                                             callbackURLScheme: Store.googleScheme) else { return }
        await store.finishGoogle(callback)
    }
}

/// The house control: a 48 point capsule. Prominent is filled with the accent; the other is outlined.
struct Capsule48: ButtonStyle {
    var prominent: Bool
    var fill: Color = .brandSlate
    var ink: Color = .white
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .foregroundStyle(prominent ? ink : Color.primary)
            .background {
                if prominent { Capsule().fill(fill) }
                else { Capsule().strokeBorder(.quaternary, lineWidth: 1) }
            }
            .contentShape(Capsule())
            .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}

/// Sign in with Apple behind our own capsule, so it matches the Google button exactly on every platform.
/// Apple's guidelines allow a custom button with the Apple logo and "Sign in with Apple".
@MainActor
final class AppleSignIn: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var store: Store?

    func start(_ store: Store) {
        self.store = store
        let request = ASAuthorizationAppleIDProvider().createRequest()
        store.prepareAppleRequest(request)
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in await store?.signInWithApple(result: .success(authorization)) }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in await store?.signInWithApple(result: .failure(error)) }
    }

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            #if os(iOS)
            UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
            #else
            NSApplication.shared.keyWindow ?? ASPresentationAnchor()
            #endif
        }
    }
}
