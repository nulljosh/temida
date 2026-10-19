import SwiftUI

struct LimitationBannerView: View {
    @Environment(Store.self) private var store

    // The clock comes from the case's private fragments row: limitIncident and limitDeadline
    // (yyyy-MM-dd), limitLabel, limitSub, limitStart, limitEnd, limitExpired. No deadline, no banner.
    private func prose(_ k: String) -> String? { frag(store.activeCase).prose[k] }
    private func day(_ k: String) -> Date? {
        prose(k).flatMap { try? Date($0, strategy: .iso8601.year().month().day()) }
    }

    private var deadline: Date? { day("limitDeadline") }
    private var daysLeft: Int {
        guard let deadline else { return 0 }
        return Calendar.current.dateComponents([.day], from: .now, to: deadline).day ?? -1
    }
    private var isExpired: Bool { daysLeft < 0 }
    private var progress: Double {
        guard let deadline, let start = day("limitIncident"), deadline > start else { return 0 }
        return min(1, max(0, Date.now.timeIntervalSince(start) / deadline.timeIntervalSince(start)))
    }
    private var bannerLabel: String { prose("limitLabel") ?? String(localized: "Limitation Deadline") }
    private var daysLabel: String {
        isExpired ? (prose("limitExpired") ?? String(localized: "Expired")) : String(localized: "\(daysLeft) days")
    }

    var body: some View {
        if deadline != nil { banner }
    }

    private var banner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(bannerLabel)
                        .font(.temidaText(13).weight(.medium))
                        .foregroundStyle(.briefDanger)
                    if let sub = prose("limitSub") {
                        Text(sub)
                            .font(.temidaText(13))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(daysLabel)
                    .font(.temidaText(isExpired ? 13 : 28, design: .rounded).weight(.bold))
                    .foregroundStyle(.briefDanger)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.2)).frame(height: 5)
                    RoundedRectangle(cornerRadius: 4).fill(Color.briefDanger.opacity(0.5))
                        .frame(width: geo.size.width * progress, height: 5)
                    Circle().fill(Color.briefDanger).frame(width: 11, height: 11)
                        .offset(x: geo.size.width * progress - 5.5)
                }
            }
            .frame(height: 11)
            .accessibilityHidden(true)
            HStack {
                Text(prose("limitStart") ?? "")
                Spacer()
                Text(prose("limitEnd") ?? "")
            }
            .font(.temidaText(13))
            .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.briefDanger.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.briefDanger, lineWidth: 1))
        )
        .accessibilityElement(children: .combine)
    }
}
