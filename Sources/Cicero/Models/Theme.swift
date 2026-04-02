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
    var fontScale: CGFloat = 1.0

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

    func scaled(_ scale: CGFloat) -> SlideTheme {
        var copy = self
        copy.fontScale = scale
        return copy
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
    func markdownTheme(fontFamily: String? = nil) -> MarkdownUI.Theme {
        let st = self
        let s = fontScale
        return .gitHub
            .text {
                if let fontFamily {
                    FontFamily(.custom(fontFamily))
                }
                ForegroundColor(st.text)
                FontSize(22 * s)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownTextStyle {
                        if let fontFamily {
                            FontFamily(.custom(fontFamily))
                        }
                        FontSize(44 * s)
                        FontWeight(.bold)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 24 * s)
            }
            .heading2 { configuration in
                configuration.label
                    .markdownTextStyle {
                        if let fontFamily {
                            FontFamily(.custom(fontFamily))
                        }
                        FontSize(34 * s)
                        FontWeight(.semibold)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 16 * s)
            }
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        if let fontFamily {
                            FontFamily(.custom(fontFamily))
                        }
                        FontSize(28 * s)
                        FontWeight(.medium)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 12 * s)
            }
            .codeBlock { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(16 * s)
                        ForegroundColor(st.codeText)
                    }
                    .padding(16 * s)
                    .background(st.codeBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .markdownMargin(top: 16 * s, bottom: 16 * s)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(18 * s)
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
                    .markdownMargin(top: 4 * s, bottom: 4 * s)
            }
    }

    /// Larger heading theme for title layout slides
    func titleMarkdownTheme(fontFamily: String? = nil) -> MarkdownUI.Theme {
        let st = self
        let s = fontScale
        return .gitHub
            .text {
                if let fontFamily {
                    FontFamily(.custom(fontFamily))
                }
                ForegroundColor(st.text)
                FontSize(26 * s)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownTextStyle {
                        if let fontFamily {
                            FontFamily(.custom(fontFamily))
                        }
                        FontSize(56 * s)
                        FontWeight(.bold)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 24 * s)
            }
            .heading2 { configuration in
                configuration.label
                    .markdownTextStyle {
                        if let fontFamily {
                            FontFamily(.custom(fontFamily))
                        }
                        FontSize(40 * s)
                        FontWeight(.semibold)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 16 * s)
            }
            .heading3 { configuration in
                configuration.label
                    .markdownTextStyle {
                        if let fontFamily {
                            FontFamily(.custom(fontFamily))
                        }
                        FontSize(32 * s)
                        FontWeight(.medium)
                        ForegroundColor(st.heading)
                    }
                    .markdownMargin(top: 0, bottom: 12 * s)
            }
            .codeBlock { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(16 * s)
                        ForegroundColor(st.codeText)
                    }
                    .padding(16 * s)
                    .background(st.codeBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .markdownMargin(top: 16 * s, bottom: 16 * s)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(18 * s)
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
                    .markdownMargin(top: 4 * s, bottom: 4 * s)
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
