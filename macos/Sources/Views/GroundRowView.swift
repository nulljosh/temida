import SwiftUI

struct GroundRowView: View {
    let ground: Ground
    @Binding var expandedId: String?

    private var isOpen: Bool { expandedId == ground.id }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedId = isOpen ? nil : ground.id
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Text(String(format: "%02d", ground.number))
                        .font(.temidaText(13))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ground.title)
                            .font(.temidaText(14).weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(ground.section)
                            .font(.temidaText(13))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(ground.value)
                        .font(.temidaText(13).weight(.bold))
                        .foregroundStyle(ground.accent)
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.temidaText(13).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isOpen ? Text("Expanded") : Text("Collapsed"))

            if isOpen {
                VStack(alignment: .leading, spacing: 10) {
                    Text(ground.description)
                        .font(.temidaText(13))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                    Text(ground.citation)
                        .font(.temidaText(13))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
