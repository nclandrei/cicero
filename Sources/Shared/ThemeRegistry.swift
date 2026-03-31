import Foundation

public enum ThemeRegistry {
    public static let builtIn: [ThemeDefinition] = [
        dark, light, ocean, forest, sunset, minimal, solarizedDark, solarizedLight, nord, dracula,
    ]

    public static func find(_ name: String) -> ThemeDefinition? {
        builtIn.first { $0.name == name }
    }

    public static let dark = ThemeDefinition(
        name: "dark",
        background: "#1a1a2e",
        text: "#ffffff",
        heading: "#ffffff",
        accent: "#6c63ff",
        codeBackground: "#16213e",
        codeText: "#e2e8f0"
    )

    public static let light = ThemeDefinition(
        name: "light",
        background: "#ffffff",
        text: "#1a1a2e",
        heading: "#1a1a2e",
        accent: "#6c63ff",
        codeBackground: "#f1f5f9",
        codeText: "#334155"
    )

    public static let ocean = ThemeDefinition(
        name: "ocean",
        background: "#0a192f",
        text: "#ccd6f6",
        heading: "#64ffda",
        accent: "#64ffda",
        codeBackground: "#112240",
        codeText: "#a8b2d1"
    )

    public static let forest = ThemeDefinition(
        name: "forest",
        background: "#1b2d1b",
        text: "#d4e4d4",
        heading: "#8fbc8f",
        accent: "#98d98e",
        codeBackground: "#162416",
        codeText: "#b5ccb5"
    )

    public static let sunset = ThemeDefinition(
        name: "sunset",
        background: "#2d1b2d",
        text: "#f0d0f0",
        heading: "#ff6b6b",
        accent: "#ffa07a",
        codeBackground: "#3d1f3d",
        codeText: "#e8c0e8"
    )

    public static let minimal = ThemeDefinition(
        name: "minimal",
        background: "#fafafa",
        text: "#333333",
        heading: "#111111",
        accent: "#0066cc",
        codeBackground: "#f0f0f0",
        codeText: "#333333"
    )

    public static let solarizedDark = ThemeDefinition(
        name: "solarized-dark",
        background: "#002b36",
        text: "#839496",
        heading: "#93a1a1",
        accent: "#268bd2",
        codeBackground: "#073642",
        codeText: "#93a1a1"
    )

    public static let solarizedLight = ThemeDefinition(
        name: "solarized-light",
        background: "#fdf6e3",
        text: "#657b83",
        heading: "#586e75",
        accent: "#268bd2",
        codeBackground: "#eee8d5",
        codeText: "#586e75"
    )

    public static let nord = ThemeDefinition(
        name: "nord",
        background: "#2e3440",
        text: "#d8dee9",
        heading: "#eceff4",
        accent: "#88c0d0",
        codeBackground: "#3b4252",
        codeText: "#d8dee9"
    )

    public static let dracula = ThemeDefinition(
        name: "dracula",
        background: "#282a36",
        text: "#f8f8f2",
        heading: "#ff79c6",
        accent: "#bd93f9",
        codeBackground: "#44475a",
        codeText: "#f8f8f2"
    )
}
