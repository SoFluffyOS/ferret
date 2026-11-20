import Foundation

/// The Mac's own spring-loading setting, from System Settings →
/// Accessibility → Pointer Control: whether a drag resting on something
/// opens it, and after how long. Read each time, so a change there counts
/// at once.
enum SpringLoading {
    /// What the Mac uses when the slider was never touched.
    static let defaultDelay: TimeInterval = 0.5

    static var isEnabled: Bool {
        guard let value = UserDefaults.standard.object(forKey: "com.apple.springing.enabled")
        else { return true }

        return number(value).map { $0 != 0 } ?? true
    }

    static var delay: TimeInterval {
        guard let value = UserDefaults.standard.object(forKey: "com.apple.springing.delay"),
              let delay = number(value), delay >= 0
        else { return defaultDelay }

        return min(delay, 2)
    }

    private static func number(_ value: Any) -> Double? {
        switch value {
        case let number as NSNumber: number.doubleValue
        case let text as String: Double(text)
        default: nil
        }
    }
}
