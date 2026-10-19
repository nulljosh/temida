import ImageIO
import PhotosUI
import SwiftUI

/// Profile and settings: who is signed in, which case is open, account actions, and about.
struct ProfileView: View {
    @Environment(Store.self) private var store
    @State private var name = ""
    @FocusState private var editingName: Bool
    @State private var choosingPhoto = false
    @State private var photo: PhotosPickerItem?
    @State private var uploading = false
    @State private var confirmingDelete = false
    @State private var deleting = false
    @State private var resetSent = false

    private var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "" }

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        avatarMenu
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: store.displayName).font(.title3.weight(.semibold)).lineLimit(2)
                            if store.profile["full_name"]?.isEmpty == false, let email = store.email {
                                Text(verbatim: email).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .padding(.vertical, 6)
                }

                Section("Account") {
                    TextField("Name", text: $name, prompt: Text("Add your name"))
                        .focused($editingName)
                        .onSubmit { Task { await store.saveName(name) } }
                    LabeledContent("Email", value: store.email ?? "")
                    Button("Reset Password") { Task { resetSent = await store.resetPassword() } }
                        .disabled(store.email == nil)
                    Button("Sign Out") { Task { await store.signOut() } }
                }

                if CaseID.shown.count > 1 {
                    Section("Case") {
                        Picker("Open case", selection: $store.activeCase) {
                            ForEach(CaseID.shown) { Text($0.title).tag($0) }
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: version)
                    Link("Privacy Policy", destination: URL(string: "https://temida.jaybulb.com/privacy.html")!)
                    Link("Temida on the Web", destination: URL(string: "https://temida.jaybulb.com")!)
                }

                Section {
                    Button("Delete Account", role: .destructive) { confirmingDelete = true }
                        .disabled(deleting)
                } footer: {
                    if let err = store.accountActionError {
                        Text(err).foregroundStyle(.red)
                    } else {
                        Text("Permanently deletes your account and every brief in it.")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Profile")
            .onAppear { name = store.profile["full_name"] ?? "" }
            .onChange(of: store.profile["full_name"]) { _, new in if !editingName { name = new ?? "" } }
            .onChange(of: editingName) { _, editing in if !editing { Task { await store.saveName(name) } } }
            .photosPicker(isPresented: $choosingPhoto, selection: $photo, matching: .images)
            .onChange(of: photo) { _, item in
                guard let item else { return }
                uploading = true
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) { await store.uploadAvatar(data) }
                    uploading = false
                    photo = nil
                }
            }
            .alert("Check your email", isPresented: $resetSent) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("We sent a link to \(store.email ?? String(localized: "your address")) to choose a new password.")
            }
            .confirmationDialog("Delete your account?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) {
                    deleting = true
                    Task { _ = await store.deleteAccount(); deleting = false }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account and all case data. It cannot be undone.")
            }
        }
    }

    private var avatarMenu: some View {
        Menu {
            Button("Choose Photo…", systemImage: "photo") { choosingPhoto = true }
            Button("Generate New", systemImage: "sparkles") { Task { await store.generateAvatar() } }
            if store.profile["avatar_url"]?.isEmpty == false || store.profile["avatar_seed"]?.isEmpty == false {
                Button("Remove", systemImage: "trash", role: .destructive) { Task { await store.removeAvatar() } }
            }
        } label: {
            AvatarView(profile: store.profile, initial: String(store.displayName.first ?? "?"), size: 64)
                .overlay { if uploading { ProgressView().controlSize(.small) } }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.brandSlate, in: Circle())
                        .overlay(Circle().stroke(.background, lineWidth: 2))
                        .accessibilityHidden(true)
                }
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel("Change profile photo")
    }
}

/// An uploaded photo, else a generated pattern, else the first letter of the name.
struct AvatarView: View {
    let profile: [String: String]
    let initial: String
    var size: CGFloat = 64

    var body: some View {
        Group {
            if let url = profile["avatar_url"].flatMap({ $0.isEmpty ? nil : URL(string: $0) }) {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { Color.brandSlate.opacity(0.12) }
            } else if let seed = profile["avatar_seed"].flatMap(UInt64.init) {
                Pattern(seed: seed)
            } else {
                Text(verbatim: initial.uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.brandSlate)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    /// A mirrored 5x5 grid in one ink, picked from the seed. Same seed, same pattern, on every device.
    private struct Pattern: View {
        let seed: UInt64
        private static let inks: [Color] = [
            Color(red: 0.17, green: 0.21, blue: 0.31), // slate
            Color(red: 0.71, green: 0.31, blue: 0.17), // terracotta
            Color(red: 0.18, green: 0.36, blue: 0.27), // forest
            Color(red: 0.66, green: 0.45, blue: 0.10), // ochre
            Color(red: 0.48, green: 0.18, blue: 0.18), // oxblood
            Color(red: 0.12, green: 0.31, blue: 0.47), // ink blue
        ]

        var body: some View {
            Canvas { ctx, size in
                var s = seed
                func next() -> UInt64 { s = s &* 6364136223846793005 &+ 1442695040888963407; return s >> 33 }
                let ink = Self.inks[Int(next() % UInt64(Self.inks.count))]
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(ink.opacity(0.14)))
                let cell = size.width / 8 // 5 cells plus a margin so the circle never clips the grid
                for row in 0..<5 {
                    for col in 0..<3 where next() % 2 == 0 {
                        for c in Set([col, 4 - col]) {
                            let r = CGRect(x: cell * (CGFloat(c) + 1.5), y: cell * (CGFloat(row) + 1.5), width: cell, height: cell)
                            ctx.fill(Path(r), with: .color(ink))
                        }
                    }
                }
            }
        }
    }
}

extension Store {
    /// 512 px JPEG. Drawing from a CGImage drops EXIF, so location data never leaves the device.
    static func avatarJPEG(_ data: Data) -> Data? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let img = CGImageSourceCreateThumbnailAtIndex(src, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceCreateThumbnailWithTransform: true,
                  kCGImageSourceThumbnailMaxPixelSize: 512,
              ] as CFDictionary) else { return nil }
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, "public.jpeg" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, img, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        return CGImageDestinationFinalize(dest) ? out as Data : nil
    }
}
