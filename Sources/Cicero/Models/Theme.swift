import SwiftUI
import Shared

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
    let definition: ThemeDefinition?

    init(
        background: Color,
        text: Color,
        heading: Color,
        accent: Color,
        codeBackground: Color,
        codeText: Color,
        definition: ThemeDefinition? = nil
    ) {
        self.background = background
        self.text = text
        self.heading = heading
        self.accent = accent
        self.codeBackground = codeBackground
        self.codeText = codeText
        self.definition = definition
    }

    init(definition def: ThemeDefinition) {
        self.definition = def
        self.background = Color(hexString: def.background) ?? .black
        self.text = Color(hexString: def.text) ?? .white
        self.heading = Color(hexString: def.heading) ?? .white
        self.accent = Color(hexString: def.accent) ?? .blue
        self.codeBackground = Color(hexString: def.codeBackground) ?? .black
        self.codeText = Color(hexString: def.codeText) ?? .white
    }

    var isDark: Bool {
        definition?.isDark ?? true
    }

    static let dark = SlideTheme(definition: ThemeRegistry.dark)
    static let light = SlideTheme(definition: ThemeRegistry.light)

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

    init?(hexString: String) {
        guard let rgb = ThemeDefinition.parseHex(hexString) else { return nil }
        self.init(.sRGB, red: rgb.r, green: rgb.g, blue: rgb.b, opacity: 1)
    }
}
