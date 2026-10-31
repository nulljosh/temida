import EventKit
import SwiftUI

/// Brand slate from brand/BRAND.md; the light top of the icon gradient reads on dark backgrounds.
extension Font {
    /// Headlines in the system sans, semibold, so every screen uses one face. Scales with Dynamic Type.
    static func temidaHeadline(_ size: CGFloat) -> Font { .system(textStyle(for: size), weight: .semibold) }

    /// Body copy written as a design size (13, 15, ...) but drawn as the matching text style, so it follows
    /// Dynamic Type on iOS. macOS text styles run smaller, so the same sizes map one step up there.
    static func temidaText(_ size: CGFloat, design: Font.Design = .default) -> Font {
        .system(textStyle(for: size), design: design)
    }

    private static func textStyle(for size: CGFloat) -> Font.TextStyle {
        #if os(macOS)
        switch size {
        case ..<11.5: return .subheadline
        case ..<12.5: return .callout
        case ..<14.5: return .body
        case ..<16.5: return .title3
        case ..<19: return .title2
        case ..<26: return .title
        default: return .largeTitle
        }
        #else
        switch size {
        case ..<11.5: return .caption2
        case ..<12.5: return .caption
        case ..<13.5: return .footnote
        case ..<15.5: return .subheadline
        case ..<16.5: return .callout
        case ..<18.5: return .body
        case ..<20.5: return .title3
        case ..<23: return .title2
        case ..<30: return .title
        default: return .largeTitle
        }
        #endif
    }
}

extension Color {
    static let brandSlate = Color(light: Color(red: 0.169, green: 0.208, blue: 0.314),
                                  dark: Color(red: 0.624, green: 0.690, blue: 0.839))

    init(light: Color, dark: Color) {
        #if os(iOS)
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
        #else
        self.init(NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .vibrantDark]) != nil ? NSColor(dark) : NSColor(light) })
        #endif
    }
}

/// Puts a next step into the system Reminders or Calendar app. Asks for access the first time.
/// Calendar only needs write-only access; Reminders has no write-only mode, so it asks for full access.
@MainActor
enum Planner {
    private static let store = EKEventStore()

    enum Failure: LocalizedError {
        case denied(String), noList(String)
        var errorDescription: String? {
            switch self {
            case .denied(let app): return String(localized: "Temida needs access to \(app). Turn it on in Settings.")
            case .noList(let app): return String(localized: "\(app) has no default list to add to.")
            }
        }
    }

    /// v10: a reminder made from a deadline is remembered by that deadline's row id, so editing the deadline moves it.
    /// Calendar only has write-only access and cannot read its event back, so only Reminders follow.
    private static let followKey = "plannerReminders"
    private static var followed: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: followKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: followKey) }
    }

    static func follow(_ old: String, to new: String, title: String, notes: String?, due: Date) {
        guard let id = followed[old], EKEventStore.authorizationStatus(for: .reminder) == .fullAccess,
              let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else { return }
        reminder.title = title
        reminder.notes = notes
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        reminder.alarms = [EKAlarm(absoluteDate: due)]
        guard (try? store.save(reminder, commit: true)) != nil else { return }
        followed[old] = nil
        followed[new] = id
    }

    static func remind(_ title: String, notes: String?, due: Date, follow key: String? = nil) async throws {
        guard try await store.requestFullAccessToReminders() else { throw Failure.denied(String(localized: "Reminders")) }
        guard let list = store.defaultCalendarForNewReminders() else { throw Failure.noList(String(localized: "Reminders")) }
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = list
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        reminder.addAlarm(EKAlarm(absoluteDate: due))
        try store.save(reminder, commit: true)
        if let key { followed[key] = reminder.calendarItemIdentifier }
    }

    static func schedule(_ title: String, notes: String?, start: Date, minutes: Int = 30) async throws {
        guard try await store.requestWriteOnlyAccessToEvents() else { throw Failure.denied(String(localized: "Calendar")) }
        guard let calendar = store.defaultCalendarForNewEvents else { throw Failure.noList(String(localized: "Calendar")) }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.notes = notes
        event.startDate = start
        event.endDate = start.addingTimeInterval(TimeInterval(minutes * 60))
        event.calendar = calendar
        try store.save(event, span: .thisEvent)
    }
}
