# Theme and Design Tokens

## Framework

- Native SwiftUI, iOS 26 Liquid Glass APIs.
- Apple system typography (SF Pro / SF Pro Rounded).
- SF Symbols for icons.
- System light/dark colors and Dynamic Type.

## Dashboard palette source

Source: `Ask Numi/Presentation/Dashboard/HomeDashboardView.swift`

```swift
enum DashboardPalette {
    static let primary = Color(red: 79.0 / 255, green: 70.0 / 255, blue: 229.0 / 255)
    static let avatarHighlight = Color(red: 124.0 / 255, green: 127.0 / 255, blue: 240.0 / 255)
    static let ai = Color(red: 175.0 / 255, green: 82.0 / 255, blue: 222.0 / 255)
    static let income = Color(red: 52.0 / 255, green: 199.0 / 255, blue: 89.0 / 255)
    static let incomeLabel = Color(red: 36.0 / 255, green: 138.0 / 255, blue: 61.0 / 255)
    static let expense = Color(red: 255.0 / 255, green: 59.0 / 255, blue: 48.0 / 255)
}
```

## App accent source

Source: `Ask Numi/Infrastructure/CategoryColor+SwiftUI.swift`

```swift
import SwiftUI

extension CategoryColor {
    var displayColor: Color {
        switch self {
        case .red: .red
        case .pink: .pink
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .cyan: .cyan
        case .blue: .blue
        case .purple: .purple
        }
    }
}

private struct AppAccentColorKey: EnvironmentKey {
    nonisolated static let defaultValue = Color.blue
}

extension EnvironmentValues {
    var appAccentColor: Color {
        get { self[AppAccentColorKey.self] }
        set { self[AppAccentColorKey.self] = newValue }
    }
}
```

## App-level appearance source

Source: `Ask Numi/App/Ask_NumiApp.swift`

```swift
@AppStorage(AppearanceSettings.darkModeStorageKey) private var isDarkModeEnabled = false
@AppStorage(AppearanceSettings.accentColorStorageKey) private var accentColorID = AppearanceSettings.defaultAccentColorID

private var accentColor: Color {
    CategoryColor(rawValue: accentColorID)?.displayColor ?? .blue
}

ContentView(container: container)
    .environment(\.appAccentColor, accentColor)
    .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
    .tint(accentColor)
```

## Visual rules extracted from source

- Screen horizontal inset: `20pt`.
- Main vertical rhythm: `24pt`; card internals use `12–16pt`.
- Dashboard background: neutral gradient `#F6F7FB → #FFFFFF` in light mode.
- Primary/accent: indigo `#4F46E5`; AI: purple `#AF52DE`.
- Income: green `#34C759`; expense: red `#FF3B30`.
- Glass cards: `18–24pt` corners, subtle 1pt stroke, soft shadow.
- Bottom navigation: 54pt capsule inside a 62pt container, four equal tab targets.
- Balance: 40pt heavy rounded, slight negative tracking.
- Card title: system headline/subheadline, semibold or bold.
