import AuthenticationServices
import CryptoKit
#if os(iOS)
import LocalAuthentication
#endif
import Observation
import SwiftUI

// One Store for iOS and macOS, on jaybulb-api (API.swift) like the web app: edit anywhere, see it everywhere.

// MARK: - DB row types

private struct CaseDataValueRow: Decodable {
    let value: CaseDataDTO
}

struct BriefJournalRow: Decodable {
    let date: String
    let text: String
}

struct BriefDocumentRow: Decodable {
    let date: String
    let title: String
    let text: String
}

struct BriefChecklistRow: Decodable {
    let item_index: Int
    let completed: Bool
}

struct BriefLawyerRow: Decodable {
    let lawyer_id: String
    let status: String
}

// MARK: - Write payloads

private struct JournalUpsert: Encodable {
    let user_id: String; let date: String; let text: String
}
private struct DocumentUpsert: Encodable {
    let user_id: String; let date: String; let title: String; let text: String
}
private struct ChecklistUpsert: Encodable {
    let user_id: String; let item_index: Int; let completed: Bool
}
private struct LawyerUpsert: Encodable {
    let user_id: String; let lawyer_id: String; let status: String
}

enum AuthStep { case email, password }

// MARK: - Store

@MainActor
@Observable
final class Store {
    var needsSignIn = true
    #if os(iOS)
    var biometricLocked = true
    #else
    var biometricLocked = false
    #endif
    var authStep: AuthStep = .email
    var signInError: String?
    var signInNotice: String?
    var activeCase: CaseID = .rcmp
    private(set) var journalEntries: [JournalEntry] = []
    private(set) var documentEntries: [DocumentEntry] = []
    private(set) var completedItems: Set<Int> = []
    private(set) var lawyerStatuses: [String: String] = [:]
    var accountActionError: String?
    /// Case content lives in plain globals SwiftUI cannot observe; bumping this after a load
    /// rebuilds the views that read them (ContentView keys on it).
    private(set) var revision = 0

    let api = API.shared
    var email: String? { api.email }
    var userId: String? { api.userId }

    /// user_metadata: full_name, avatar_url (an uploaded photo) or avatar_seed (a generated one).
    private(set) var profile: [String: String] = [:]
    var displayName: String { profile["full_name"].flatMap { $0.isEmpty ? nil : $0 } ?? email ?? "Signed in" }

    let statusCycle = ["none", "voicemail", "emailed", "callback", "retained"]
    let statusLabel: [String: String] = [
        "none": "Not contacted", "voicemail": "Voicemail left",
        "emailed": "Email sent", "callback": "Callback received", "retained": "Retained"
    ]

    init() {}

    // MARK: Session

    /// The splash stays up until we know where to land, so sign-in and onboarding never flash.
    @MainActor func checkSession() async {
        let started = Date()
        #if DEBUG
        if loadDemo() {
            try? await Task.sleep(for: .seconds(0.9))
            launching = false
            return
        }
        #endif
        if await api.refresh() {
            needsSignIn = false
            async let load: Void = loadAll()
            await authenticateWithBiometrics()
            await load
        } else {
            needsSignIn = true
            biometricLocked = false
        }
        let rest = 0.9 - Date().timeIntervalSince(started) // let the splash animation finish
        if rest > 0 { try? await Task.sleep(for: .seconds(rest)) }
        launching = false
    }

    /// Every successful sign-in path ends here.
    @MainActor private func signedIn() async {
        launching = true
        needsSignIn = false
        biometricLocked = false
        await loadAll()
        launching = false
    }

    // MARK: Onboarding: welcome, name, first brief. Shown once, to accounts with no brief yet.

    var launching = true
    private(set) var hasBrief = false
    private var profileLoaded = false
    private var casesChecked = false
    private var onboardingDone = false
    #if DEBUG
    /// `-forceOnboarding` shows the flow on any account and writes nothing.
    static let forceOnboarding = CommandLine.arguments.contains("-forceOnboarding")
    #else
    static let forceOnboarding = false
    #endif

    var needsOnboarding: Bool {
        guard !onboardingDone else { return false }
        if Self.forceOnboarding { return true }
        return profileLoaded && casesChecked && profile["onboarded"] == nil && !hasBrief
    }

    @MainActor func finishOnboarding(name: String, briefTitle: String) async {
        #if os(iOS)
        UserDefaults.standard.set(whatsNewVersion, forKey: "whats_new_seen_version") // new accounts skip What's New
        #endif
        guard !Self.forceOnboarding else { onboardingDone = true; return }
        await saveName(name)
        let title = briefTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty, let uid = userId {
            do {
                try await api.upsert("brief_data", json: ["user_id": uid, "key": "cases", "value": Self.emptyBrief(title)])
                await loadCaseData()
            } catch { accountActionError = error.localizedDescription }
        }
        await saveProfile(["onboarded": "1"])
        onboardingDone = true // even if the flag failed to save, never trap anyone in the flow
    }

    @MainActor private func attempt(_ work: () async throws -> Void) async {
        signInError = nil
        signInNotice = nil
        do { try await work() } catch { signInError = error.localizedDescription }
    }

    // MARK: Face ID (iPhone only)

    private let biometricCooldown: Double = 4 * 3600

    @MainActor func authenticateWithBiometrics() async {
        #if os(iOS)
        let last = UserDefaults.standard.double(forKey: "brief.lastBiometricAuth")
        if Date().timeIntervalSince1970 - last < biometricCooldown {
            biometricLocked = false
            return
        }
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricLocked = false
            return
        }
        let success = (try? await ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: String(localized: "Unlock Temida")
        )) ?? false
        if success {
            biometricLocked = false
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "brief.lastBiometricAuth")
        }
        #else
        biometricLocked = false
        #endif
    }

    // MARK: Email and password

    @MainActor func confirmEmail(email: String) {
        guard !email.isEmpty else { return }
        authStep = .password
        signInError = nil
    }

    @MainActor func resetAuthStep() {
        authStep = .email
        signInError = nil
    }

    @MainActor func signIn(email: String, password: String) async {
        await attempt {
            try await api.signIn(email: email, password: password)
            await signedIn()
        }
    }

    @MainActor func signUp(email: String, password: String) async {
        await attempt {
            try await api.signUp(email: email, password: password)
            signInNotice = String(localized: "Check your email to confirm your account, then sign in.")
        }
    }

    /// Sends a reset link; the link opens the web app, where the new password is chosen.
    /// Answers the same whether or not the address has an account.
    @MainActor func resetPassword(for address: String? = nil) async -> Bool {
        guard let target = address ?? email, !target.isEmpty else { return false }
        return (try? await api.recover(email: target)) != nil
    }

    // MARK: Sign in with Apple

    private var issuedNonces: [String] = []

    @MainActor func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        issuedNonces = Array((issuedNonces + [nonce]).suffix(5))
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.hashed(nonce)
    }

    @MainActor func signInWithApple(result: Result<ASAuthorization, Error>) async {
        if case .failure(let e) = result, (e as? ASAuthorizationError)?.code == .canceled { return } // closing Apple's sheet is a choice
        await attempt {
            guard let cred = try result.get().credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken,
                  let token = String(data: tokenData, encoding: .utf8),
                  let nonce = Self.rawNonce(for: token, among: issuedNonces) else { throw URLError(.userAuthenticationRequired) }
            try await api.signIn(provider: "apple", idToken: token, nonce: nonce)
            issuedNonces = []
            // Apple shares the name only on the first sign-in; keep it as the profile name.
            let name = PersonNameComponentsFormatter().string(from: cred.fullName ?? .init())
            if !name.isEmpty { try? await api.updateProfile(["full_name": name]) }
            await signedIn()
        }
    }

    // MARK: Google (the view runs the web sheet; see SignInView)

    var googleURL: URL { api.googleURL() }
    static var googleScheme: String { API.googleScheme }

    @MainActor func finishGoogle(_ callback: URL) async {
        await attempt {
            try await api.finishGoogle(callback)
            await signedIn()
        }
    }

    static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        // ponytail: if SecRandomCopyBytes fails, plain random is fine for a per-request nonce
        if SecRandomCopyBytes(kSecRandomDefault, length, &bytes) != errSecSuccess {
            bytes = (0..<length).map { _ in UInt8.random(in: 0...255) }
        }
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    // MARK: Account

    @MainActor func signOut() async {
        await api.signOut()
        profile = [:]
        profileLoaded = false; casesChecked = false; hasBrief = false; onboardingDone = false
        needsSignIn = true
        #if os(iOS)
        biometricLocked = true
        #endif
        authStep = .email
    }

    @MainActor func deleteAccount() async -> Bool {
        accountActionError = nil
        do {
            try await api.deleteAccount()
            await signOut()
            return true
        } catch {
            accountActionError = error.localizedDescription
            return false
        }
    }

    // MARK: Profile

    @MainActor private func loadProfile() async {
        if let p = try? await api.profile() { profile = p; profileLoaded = true }
    }

    @MainActor private func saveProfile(_ change: [String: String]) async {
        accountActionError = nil
        do {
            try await api.updateProfile(change)
            profile.merge(change) { $1 }
        } catch { accountActionError = error.localizedDescription }
    }

    @MainActor func saveName(_ name: String) async {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if n != (profile["full_name"] ?? "") { await saveProfile(["full_name": n]) }
    }

    /// A new pattern; clears any uploaded photo.
    @MainActor func generateAvatar() async {
        await saveProfile(["avatar_url": "", "avatar_seed": String(UInt32.random(in: 1...UInt32.max))])
    }

    @MainActor func removeAvatar() async { await saveProfile(["avatar_url": "", "avatar_seed": ""]) }

    @MainActor func uploadAvatar(_ image: Data) async {
        guard let jpeg = Self.avatarJPEG(image) else { accountActionError = String(localized: "That image could not be read."); return }
        do { await saveProfile(["avatar_url": try await api.uploadAvatar(jpeg)]) }
        catch { accountActionError = error.localizedDescription }
    }

    // MARK: Data

    /// Two rounds of parallel reads: profile and cases first (onboarding depends on them), then the rest.
    @MainActor func loadAll() async {
        async let profile: Void = loadProfile()
        async let cases: Void = loadCaseData()
        _ = await (profile, cases)
        async let journal: Void = loadJournal()
        async let documents: Void = loadDocuments()
        async let checklist: Void = loadChecklist()
        async let lawyers: Void = loadLawyerStatuses()
        _ = await (journal, documents, checklist, lawyers)
    }

    /// Private display content (party names, blurbs, risk/strategy prose) lives in
    /// the fragments row, separate from the structured case data. Failure here is
    /// non-fatal: the UI falls back to neutral placeholders.
    @MainActor private func loadFragments() async {
        guard let rows: [FragmentsValueRow] = try? await api.select("brief_data", "select=value&key=eq.fragments"),
              let row = rows.first else { return }
        caseFragments = row.value.native ?? [:]
    }

    @MainActor private func loadCaseData() async {
        await loadFragments()
        let rows: [CaseDataValueRow]
        do { rows = try await api.select("brief_data", "select=value&key=eq.cases") }
        catch { NSLog("[Temida] cases did not load: %@", String(describing: error)); return }
        casesChecked = true
        hasBrief = !rows.isEmpty
        guard let row = rows.first else { return }
        apply(row.value)
    }

    @MainActor func apply(_ dto: CaseDataDTO) {
        let b = dto.toBundle()

        briefTitle = b.title
        caseFacts = b.facts
        caseGrounds = b.grounds
        caseWitnesses = b.witnesses
        familyCaseWitnesses = b.familyWitnesses
        muniCaseWitnesses = b.muniWitnesses
        bylawCaseWitnesses = b.bylawWitnesses
        journalSeed = b.journalSeed
        caseChecklist = b.checklist
        caseLawyers = b.lawyers
        caseScenarios = b.scenarios
        damageHeads = b.damageHeads
        caseComparables = b.comparables
        caseTimeline = b.timeline
        callScript = b.callScript
        outreachEmail = b.outreachEmail

        familyCaseFacts = b.familyFacts
        familyCaseGrounds = b.familyGrounds
        familyCaseLawyers = b.familyLawyers
        familyCaseTimeline = b.familyTimeline
        familyCaseChecklist = b.familyChecklist
        familyCaseScenarios = b.familyScenarios
        familyDamageHeads = b.familyDamageHeads
        familyCallScript = b.familyCallScript
        familyOutreachEmail = b.familyOutreachEmail

        muniCaseFacts = b.muniFacts
        muniCaseGrounds = b.muniGrounds
        muniCaseLawyers = b.muniLawyers
        muniCaseTimeline = b.muniTimeline
        muniCaseChecklist = b.muniChecklist
        muniCaseScenarios = b.muniScenarios
        muniDamageHeads = b.muniDamageHeads
        muniCallScript = b.muniCallScript

        bylawCaseFacts = b.bylawFacts
        bylawCaseGrounds = b.bylawGrounds
        bylawCaseLawyers = b.bylawLawyers
        bylawCaseTimeline = b.bylawTimeline
        bylawCaseChecklist = b.bylawChecklist
        bylawCaseScenarios = b.bylawScenarios
        bylawDamageHeads = b.bylawDamageHeads
        bylawCallScript = b.bylawCallScript
        revision += 1
    }

    // MARK: Demo: `-demoFile <path>` or `-demoJSON <json>` (sandboxed Mac) loads a fictional brief, no network.

    #if DEBUG
    private struct DemoFile: Decodable {
        let profile: [String: String]
        let cases: CaseDataDTO
        let fragments: FragmentsValue
        let done: [Int]
    }

    @MainActor func loadDemo() -> Bool {
        let a = ProcessInfo.processInfo.arguments, i = a.firstIndex(of: "-demoJSON").map { $0 + 1 } // raw: UserDefaults reads `{` as a plist
        let inline = i.flatMap { a.indices.contains($0) ? a[$0] : nil }
        guard let path = inline ?? UserDefaults.standard.string(forKey: "demoFile") else { return false }
        do {
            let d = try JSONDecoder().decode(DemoFile.self, from: inline.map { Data($0.utf8) } ?? Data(contentsOf: URL(fileURLWithPath: path)))
            profile = d.profile
            caseFragments = d.fragments.native ?? [:]
            apply(d.cases)
            completedItems = Set(d.done)
            journalEntries = journalSeed.sorted { $0.date > $1.date }
            profileLoaded = true; casesChecked = true; hasBrief = true
            needsSignIn = false; biometricLocked = false
        } catch { NSLog("[Temida] demo file did not load: %@", String(describing: error)) }
        return true // a bad file still never falls through to the real account
    }
    #endif

    @MainActor private func loadJournal() async {
        let rows: [BriefJournalRow]? = try? await api.select("brief_journal", "order=date.desc")
        var map: [String: JournalEntry] = [:]
        journalSeed.forEach { map[$0.date] = $0 }
        (rows ?? []).forEach { map[$0.date] = JournalEntry(date: $0.date, text: $0.text) }
        journalEntries = map.values.sorted { $0.date > $1.date }
    }

    @MainActor func addJournalEntry(date: String, text: String) async {
        guard let uid = userId else { return }
        try? await api.upsert("brief_journal", JournalUpsert(user_id: uid, date: date, text: text))
        await loadJournal()
    }

    @MainActor func deleteJournalEntry(date: String) async {
        guard let uid = userId else { return }
        try? await api.delete("brief_journal", "user_id=\(API.eq(uid))&date=\(API.eq(date))")
        await loadJournal()
    }

    @MainActor private func loadDocuments() async {
        let rows: [BriefDocumentRow]? = try? await api.select("brief_documents", "order=date.desc")
        documentEntries = (rows ?? []).map { DocumentEntry(date: $0.date, title: $0.title, text: $0.text) }
    }

    @MainActor func addDocumentEntry(date: String, title: String, text: String) async {
        guard let uid = userId else { return }
        try? await api.insert("brief_documents", DocumentUpsert(user_id: uid, date: date, title: title, text: text))
        await loadDocuments()
    }

    @MainActor func deleteDocumentEntry(date: String, title: String) async {
        guard let uid = userId else { return }
        try? await api.delete("brief_documents", "user_id=\(API.eq(uid))&date=\(API.eq(date))&title=\(API.eq(title))")
        await loadDocuments()
    }

    @MainActor private func loadChecklist() async {
        let rows: [BriefChecklistRow]? = try? await api.select("brief_checklist")
        var done: Set<Int> = hasBrief ? [1, 8, 9, 10, 13, 201] : [] // seeded steps belong to the original brief only
        (rows ?? []).forEach { if $0.completed { done.insert($0.item_index) } else { done.remove($0.item_index) } }
        completedItems = done
    }

    @MainActor func toggleItem(_ index: Int) async {
        let nowDone = !completedItems.contains(index)
        if nowDone { completedItems.insert(index) } else { completedItems.remove(index) }
        guard let uid = userId else { return } // the demo has no account: the tick stays local
        try? await api.upsert("brief_checklist", ChecklistUpsert(user_id: uid, item_index: index, completed: nowDone))
    }

    @MainActor private func loadLawyerStatuses() async {
        let rows: [BriefLawyerRow]? = try? await api.select("brief_lawyer_status")
        var map: [String: String] = [:]
        (rows ?? []).forEach { map[$0.lawyer_id] = $0.status }
        lawyerStatuses = map
    }

    @MainActor func cycleLawyerStatus(_ lawyerId: String) async {
        guard let uid = userId else { return }
        let cur = lawyerStatuses[lawyerId] ?? "none"
        let idx = statusCycle.firstIndex(of: cur) ?? 0
        let next = statusCycle[(idx + 1) % statusCycle.count]
        lawyerStatuses[lawyerId] = next
        try? await api.upsert("brief_lawyer_status", LawyerUpsert(user_id: uid, lawyer_id: lawyerId, status: next))
    }
}
