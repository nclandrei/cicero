import Testing
import CoreGraphics
@testable import Shared

/// The Settings window mixes account, software-update, MCP installer, and
/// defaults sections. With `.fixedSize(vertical: true)` it grows to fit all
/// content, which on a 16-inch MacBook Pro at default scaling (≈890pt usable
/// height) clips the bottom of the window. `SettingsLayout` documents the
/// width/height budget the view must honor and these tests pin that budget
/// to the smallest officially supported macOS display.
@Suite("SettingsLayout")
struct SettingsLayoutTests {

    // 16-inch MacBook Pro at default scaling: 1456×945 points usable.
    // Subtract menu bar (24) + window title bar (28) = 52pt of chrome.
    private static let sixteenInchAvailableHeight: CGFloat = 945 - 52

    // 13-inch MacBook Air (smallest supported): 1280×832 points at default
    // scaling. Menu bar + title bar same as above.
    private static let thirteenInchAvailableHeight: CGFloat = 832 - 52

    @Test("Window width matches the documented design width")
    func widthIsFixed() {
        #expect(SettingsLayout.width == 480)
    }

    @Test("Max height fits on a 16-inch MacBook Pro at default scaling")
    func fitsOn16InchMBP() {
        #expect(SettingsLayout.maxHeight <= Self.sixteenInchAvailableHeight)
    }

    @Test("Max height fits on a 13-inch MacBook (smallest supported display)")
    func fitsOn13InchMacBook() {
        #expect(SettingsLayout.maxHeight <= Self.thirteenInchAvailableHeight)
    }

    @Test("Max height leaves room for content (>= 500pt)")
    func tallEnoughToBeUseful() {
        // Sanity floor: anything smaller than 500pt would crowd the form.
        #expect(SettingsLayout.maxHeight >= 500)
    }
}
