import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case auto, dark, light

    var colorScheme: ColorScheme? {
        switch self {
        case .auto: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

struct SlideTheme {
    let background: Color
    let text: Color
    let heading: Color
    let accent: Color
    let codeBackground: Color
    let codeText: Color

    static let dark = SlideTheme(
        background: Color(hex: 0x1a1a2e),
        text: .white,
        heading: .white,
        accent: Color(hex: 0x6c63ff),
        codeBackground: Color(hex: 0x16213e),
        codeText: Color(hex: 0xe2e8f0)
    )

    static let light = SlideTheme(
        background: .white,
        text: Color(hex: 0x1a1a2e),
        heading: Color(hex: 0x1a1a2e),
        accent: Color(hex: 0x6c63ff),
        codeBackground: Color(hex: 0xf1f5f9),
        codeText: Color(hex: 0x334155)
    )

    static func forColorScheme(_ scheme: ColorScheme) -> SlideTheme {
        scheme == .dark ? .dark : .light
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
