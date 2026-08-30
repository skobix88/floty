import Foundation

/// How the time of an entry is worded.
///
/// The classification is separated from the wording so it can be checked
/// without depending on the machine's language or region.
enum ClipboardTimestamp {

    enum Recency: Equatable {
        case justNow
        case today
        case yesterday
        case older
    }

    static func recency(of date: Date,
                        relativeTo now: Date = .now,
                        calendar: Calendar = .current) -> Recency {
        if now.timeIntervalSince(date) < 60 { return .justNow }
        // Gegen den übergebenen Bezugszeitpunkt vergleichen, nicht gegen den
        // echten Kalendertag: `isDateInToday` läge daneben, sobald jemand über
        // Mitternacht hinweg arbeitet oder die Liste stehen lässt.
        if calendar.isDate(date, inSameDayAs: now) { return .today }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return .yesterday
        }
        return .older
    }

    static func caption(for date: Date,
                        relativeTo now: Date = .now,
                        calendar: Calendar = .current) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        switch recency(of: date, relativeTo: now, calendar: calendar) {
        case .justNow:
            return String(localized: "gerade eben")
        case .today:
            return time
        case .yesterday:
            return String(localized: "gestern \(time)")
        case .older:
            return date.formatted(date: .numeric, time: .shortened)
        }
    }
}
