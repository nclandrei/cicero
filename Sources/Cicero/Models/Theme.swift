import SwiftUI
import MarkdownUI
import Splash

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

    static let dark = SlideTheme(
        background: SwiftUI.Color(hex: 0x1a1a2e),
        text: .white,
        heading: .white,
        accent: SwiftUI.Color(hex: 0x6c63ff),
        codeBackground: SwiftUI.Color(hex: 0x16213e),
        codeText: SwiftUI.Color(hex: 0xe2e8f0)
    )

    static let light = SlideTheme(
        background: .white,
        text: SwiftUI.Color(hex: 0x1a1a2e),
        heading: SwiftUI.Color(hex: 0x1a1a2e),
        accent: SwiftUI.Color(hex: 0x6c63ff),
        codeBackground: SwiftUI.Color(hex: 0xf1f5f9),
        codeText: SwiftUI.Color(hex: 0x334155)
    )

    static func forColorScheme(_ scheme: ColorScheme) -> SlideTheme {
        scheme == .dark ? .dark : .light
    }

    var splashTheme: Splash.Theme {
        background == SlideTheme.dark.background ? .ciceroDark : .ciceroLight
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
}
