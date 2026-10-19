import Foundation

/// v10: deadlines worked out from a rule. BC law, checked against bclaws.gov.bc.ca on 2026-10-19.
/// The date is computed once, when the deadline is saved, and stored as an ISO day (`due`) with the
/// rule's cite (`rule`), so web and apps only display it and can never disagree.
/// Feb 29 plus whole years lands on Feb 28, and a month end lands on the last day of the shorter month.
/// web/author.js does the same math in `addMonths`. tests/main.swift checks both edge cases.
enum LimitationRule: String, CaseIterable, Identifiable {
    case basic, ultimate, notice
    var id: String { rawValue }

    var months: Int {
        switch self { case .basic: 24; case .ultimate: 180; case .notice: 2 }
    }

    /// Stored with the deadline as written law, so it stays in English on every device.
    var cite: String {
        switch self {
        case .basic: "Limitation Act (BC) s. 6(1): 2 years after the claim is discovered"
        case .ultimate: "Limitation Act (BC) s. 21(1): 15 years after the act or omission"
        case .notice: "Local Government Act (BC) s. 736(1): written notice within 2 months of the damage"
        }
    }
}

enum Day {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// yyyy-MM-dd in the local time zone.
    static func iso(_ date: Date) -> String { formatter.string(from: date) }

    /// Noon on that day, so a time zone or DST shift never moves it.
    static func date(_ iso: String) -> Date? {
        formatter.date(from: iso).map { $0.addingTimeInterval(12 * 3600) }
    }

    /// A fixed English form ("Oct 19, 2026") for the `when` and `date` keys, so any platform in any language
    /// can parse what another one wrote.
    static func written(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    static func adding(months: Int, to iso: String) -> String? {
        guard let d = date(iso), let out = Calendar(identifier: .gregorian).date(byAdding: .month, value: months, to: d) else { return nil }
        return self.iso(out)
    }
}
