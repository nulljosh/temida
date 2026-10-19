import SwiftUI

struct NoticeCardView: View {
    // The statute, incident date and notice period come from the private fragments row
    // (prose noticeLaw, noticeDate as yyyy-MM-dd, noticeDays). Without a date the card hides.
    private var prose: [String: String] { frag(.muni).prose }
    private var incidentDate: Date? {
        prose["noticeDate"].flatMap { try? Date($0, strategy: .iso8601.year().month().day()) }
    }
    private var daysLeft: Int {
        guard let incidentDate,
              let deadline = Calendar.current.date(byAdding: .day, value: Int(prose["noticeDays"] ?? "") ?? 60, to: incidentDate)
        else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: .now, to: deadline).day ?? 0)
    }

    var body: some View {
        if incidentDate != nil { card }
    }

    private var card: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: prose["noticeLaw"] ?? "")
                    .font(.temidaText(13).weight(.bold))
                    .foregroundStyle(Color.briefDanger)
                Text(verbatim: frag(.muni).prose["noticeHead"] ?? "")
                    .font(.temidaText(15).weight(.semibold))
                Text(verbatim: frag(.muni).prose["notice"] ?? "")
                    .font(.temidaText(13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 2) {
                Text(verbatim: "\(daysLeft)")
                    .font(.temidaText(36).weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.briefDanger)
                Text("days left")
                    .font(.temidaText(13))
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 70)
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
