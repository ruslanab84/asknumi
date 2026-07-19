# Shared SwiftUI Components

The app uses custom SwiftUI views rather than a separate component library. The reusable primitives used by the dashboard are below with their complete implementations.

## AppTabBar

- Source: `Ask Numi/App/ContentView.swift`
- Shared four-tab bottom navigation used by all primary screens.

```swift
struct AppTabBar: View {
    @Binding var selection: AppTab
    @Environment(\.appAccentColor) private var accentColor

    var body: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.operations)
                tabButton(.assistant)
                tabButton(.plan)
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 54)
            .glassEffect(.regular, in: .capsule)
        }
        .frame(height: 62)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .symbolVariant(tab == selection ? .fill : .none)
                    .font(.subheadline.weight(.semibold))
                Text(tab.title)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(tab == selection ? accentColor : .secondary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(tab == selection ? .isSelected : [])
    }
}
```

## AttentionCard

- Source: `Ask Numi/Presentation/Dashboard/HomeDashboardView.swift`
- Reusable interactive glass card in the horizontal attention carousel.

```swift
struct AttentionCard<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DashboardPalette.ai)
                        .frame(width: 36, height: 36)
                        .background(DashboardPalette.ai.opacity(0.14), in: .rect(cornerRadius: 12))
                        .accessibilityHidden(true)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DashboardPalette.ai.opacity(0.7))
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

                    content
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .background(DashboardPalette.ai.opacity(0.05), in: .rect(cornerRadius: 22))
            .glassEffect(
                .regular.tint(DashboardPalette.ai.opacity(0.12)).interactive(),
                in: .rect(cornerRadius: 22)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(DashboardPalette.ai.opacity(0.18), lineWidth: 1)
            }
            .contentShape(.rect(cornerRadius: 22))
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
```

## GlassCard

- Source: `Ask Numi/Presentation/Dashboard/HomeDashboardView.swift`
- Generic tinted glass container.

```swift
struct GlassCard<Content: View>: View {
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: 24))
    }
}
```

## DashboardBackground

- Source: `Ask Numi/Presentation/Dashboard/HomeDashboardView.swift`
- Shared light/dark gradient background for dashboard surfaces.

```swift
struct DashboardBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var isNeutral = false

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [.black, Color(red: 0.02, green: 0.06, blue: 0.12), Color(red: 0.06, green: 0.02, blue: 0.16)]
                : lightColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var lightColors: [Color] {
        isNeutral
            ? [Color(red: 246.0 / 255, green: 247.0 / 255, blue: 251.0 / 255), .white]
            : [Color(red: 0.96, green: 0.97, blue: 1), .white, Color(red: 0.95, green: 1, blue: 0.98)]
    }
}
```
