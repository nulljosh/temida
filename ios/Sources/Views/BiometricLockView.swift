import SwiftUI

struct BiometricLockView: View {
    @Environment(Store.self) private var store

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 8) {
                Text("Temida")
                    .font(.temidaText(15).weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                Text("private")
                    .font(.temidaText(13))
                    .foregroundStyle(.tertiary)
            }
            Image(systemName: "faceid")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
            Button {
                Task { await store.authenticateWithBiometrics() }
            } label: {
                Text("Unlock")
                    .font(.temidaText(15).weight(.semibold))
                    .frame(minWidth: 160, minHeight: 44)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task { await store.authenticateWithBiometrics() }
        }
    }
}
