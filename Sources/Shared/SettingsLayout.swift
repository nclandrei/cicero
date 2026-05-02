import CoreGraphics

/// Size budget for the Settings window. Centralised so the SwiftUI
/// `SettingsView` and the layout tests share one source of truth.
public enum SettingsLayout {

    /// Fixed window width. Matches the documented design for the form.
    public static let width: CGFloat = 480

    /// Maximum window height. Sized to fit on a 13-inch MacBook (832pt
    /// available height) after subtracting menu bar (24pt) and title
    /// bar (28pt) chrome. The form scrolls beyond this.
    public static let maxHeight: CGFloat = 600
}
