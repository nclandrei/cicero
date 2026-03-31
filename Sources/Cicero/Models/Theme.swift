import SwiftUI
import MarkdownUI
import Splash
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
    let background: SwiftUI.Color
    let text: SwiftUI.Color
    let heading: SwiftUI.Color
    let accent: SwiftUI.Color
    let codeBackground: SwiftUI.Color
    let codeText: SwiftUI.Color
    let definition: ThemeDefinition?

    init(
        background: SwiftUI.Color,
        text: SwiftUI.Color,
        heading: SwiftUI.Color,
        accent: SwiftUI.Color,
        codeBackground: SwiftUI.Color,
        codeText: SwiftUI.Color,
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
        self.background = SwiftUI.Color(hexString: def.background) ?? .black
        self.text = SwiftUI.Color(hexString: def.text) ?? .white
        self.heading = SwiftUI.Color(hexString: def.heading) ?? .white
        self.accent = SwiftUI.Color(hexString: def.accent) ?? .blue
        self.codeBackground = SwiftUI.Color(hexString: def.codeBackground) ?? .black
        self.codeText = SwiftUI.Color(hexString: def.codeText) ?? .white
    }

    var isDark: Bool {
        definition?.isDark ?? true
    }

    static let dark = SlideTheme(definition: ThemeRegistry.dark)
    static let light = SlideTheme(definition: ThemeRegistry.light)

    static func forColorScheme(_ scheme: ColorScheme) -> SlideTheme {
        scheme == .dark ? .dark : .light
    }

    var splashTheme: Splash.Theme {
        isDark ? .ciceroDark : .ciceroLight
    }

    /// Standard markdown theme for regular slides
    func markdownTheme(splashTheme: Splash.Theme? = nil) -> MarkdownUI.Theme {
        let st = self
        return .gitHub
            .text {
                ForegroundColor(st.text)
                FontSize(22)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(44)
                        FontWeight(.bold)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 24)
            }
            .heading2 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(34)
                        FontWeight(.semibold)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 16)
            }
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(28)
                        FontWeight(.medium)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 12)
            }
            .codeBlock { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(16)
                        ForegroundColor(st.codeText)
                    }
                    .padding(16)
                    .background(st.codeBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .markdownMargin(top: 16, bottom: 16)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(18)
                ForegroundColor(st.accent)
            }
            .strong {
                FontWeight(.bold)
            }
            .link {
                ForegroundColor(st.accent)
            }
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: 4, bottom: 4)
            }
    }

    /// Larger heading theme for title layout slides
    func titleMarkdownTheme(splashTheme: Splash.Theme? = nil) -> MarkdownUI.Theme {
        let st = self
        return .gitHub
            .text {
                ForegroundColor(st.text)
                FontSize(26)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(56)
                        FontWeight(.bold)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 24)
            }
            .heading2 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(40)
                        FontWeight(.semibold)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 16)
            }
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(32)
                        FontWeight(.medium)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 12)
            }
            .codeBlock { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(16)
                        ForegroundColor(st.codeText)
                    }
                    .padding(16)
                    .background(st.codeBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .markdownMargin(top: 16, bottom: 16)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(18)
                ForegroundColor(st.accent)
            }
            .strong {
                FontWeight(.bold)
            }
            .link {
                ForegroundColor(st.accent)
            }
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: 4, bottom: 4)
            }
    }
}

extension SwiftUI.Color {
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
