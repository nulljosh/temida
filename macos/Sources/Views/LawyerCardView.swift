import SwiftUI

struct LawyerCardView: View {
    let lawyer: Lawyer
    @Environment(\.openURL) private var openURL
    @Environment(Store.self) private var store

    private var status: String { store.lawyerStatuses[lawyer.id] ?? "none" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.secondary.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.secondary.opacity(0.2)))
                        .frame(width: 46, height: 46)
                    Text(lawyer.initials)
                        .font(.temidaText(15).weight(.bold))
                        .foregroundStyle(.primary)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(verbatim: lawyer.name)
                            .font(.temidaText(15).weight(.semibold))
                        Spacer()
                        Button {
                            Task { await store.cycleLawyerStatus(lawyer.id) }
                        } label: {
                            Text(LocalizedStringKey(store.statusLabel[status] ?? "Not contacted"))
                                .font(.temidaText(13).weight(.semibold))
                                .foregroundStyle(statusColor(status))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(status).opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Changes the contact status")
                    }
                    Text(lawyer.subtitle)
                        .font(.temidaText(13))
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 5) {
                            ForEach(lawyer.tags, id: \.label) { tag in
                                Text(tag.label)
                                    .font(.temidaText(13).weight(.semibold))
                                    .foregroundStyle(tagColor(tag.style))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(tagColor(tag.style).opacity(0.12), in: Capsule())
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 12)

            HStack(spacing: 8) {
                if let phone = lawyer.phone {
                    Button {
                        openURL(URL(string: "tel://\(phone)")!)
                    } label: {
                        HStack(spacing: 6) {
                            Text(formatPhone(phone))
                                .font(.temidaText(13).weight(.bold))
                            if let note = lawyer.phoneNote {
                                Text(note)
                                    .font(.temidaText(13))
                                    .opacity(0.6)
                            }
                            Image(systemName: "phone.fill")
                                .font(.temidaText(13))
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.briefAccent, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityLabel("Call \(formatPhone(phone))")
                    .buttonStyle(.plain)
                }
                if let email = lawyer.email {
                    Button {
                        openURL(URL(string: "mailto:\(email)")!)
                    } label: {
                        HStack(spacing: 6) {
                            Text(email)
                                .font(.temidaText(13).weight(.semibold))
                            Image(systemName: "envelope")
                                .font(.temidaText(13))
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityLabel("Email \(email)")
                    .buttonStyle(.plain)
                }
                if let website = lawyer.website {
                    Button {
                        openURL(URL(string: "https://\(website)")!)
                    } label: {
                        HStack(spacing: 6) {
                            Text(website)
                                .font(.temidaText(13).weight(.semibold))
                            Image(systemName: "safari")
                                .font(.temidaText(13))
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityLabel("Open \(website)")
                    .buttonStyle(.plain)
                }
            }
            .padding([.horizontal, .bottom], 16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func tagColor(_ style: TagStyle) -> Color {
        switch style {
        case .good: return .briefGreen
        case .urgent: return .briefWarn
        case .fail: return .briefDanger
        case .neutral: return .secondary
        }
    }

    private func statusColor(_ s: String) -> Color {
        switch s {
        case "voicemail", "emailed": return .briefWarn
        case "callback": return .briefAccent
        case "retained": return .briefGreen
        default: return .secondary
        }
    }

    private func formatPhone(_ raw: String) -> String {
        guard raw.count == 10 else { return raw }
        let a = raw.prefix(3), b = raw.dropFirst(3).prefix(3), c = raw.suffix(4)
        return "\(a)-\(b)-\(c)"
    }
}
