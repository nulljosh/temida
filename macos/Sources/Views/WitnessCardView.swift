import SwiftUI

struct WitnessCardView: View {
    let witness: Witness

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Text(witness.initials)
                        .font(.temidaText(17).weight(.bold))
                        .foregroundStyle(.briefAccent)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(witness.name)
                        .font(.temidaText(14).weight(.semibold))
                    Text(verbatim: "\(witness.role) · \(witness.date)")
                        .font(.temidaText(13))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(witness.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.temidaText(13).weight(.semibold))
                            .foregroundStyle(.briefGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.briefGreen.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(Color.secondary.opacity(0.2)))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Statement, verbatim")
                    .font(.temidaText(13).weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: witness.statement)
                    .font(.temidaText(13))
                    .foregroundStyle(.primary)
                    .lineSpacing(4)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.15))
                    )
            }

            if !witness.annotations.isEmpty { // added witnesses have none yet
                VStack(alignment: .leading, spacing: 8) {
                    Text("Legal annotations")
                        .font(.temidaText(13).weight(.bold))
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(witness.annotations) { annotation in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: "\"\(annotation.quote)\"")
                                .font(.temidaText(13))
                                .foregroundStyle(.briefWarn)
                            Text(verbatim: annotation.note)
                                .font(.temidaText(13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.briefWarn.opacity(0.4), lineWidth: 1)
                        )
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
