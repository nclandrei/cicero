import Foundation

public enum TimeFormatting {
    /// Formats elapsed seconds as M:SS (e.g. 0:00, 1:30, 10:05)
    public static func elapsedTime(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    /// Formats a Date as HH:MM wall clock time (e.g. 14:05)
    public static func wallClock(from date: Date = Date()) -> String {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        return "\(h):\(String(format: "%02d", m))"
    }
}
