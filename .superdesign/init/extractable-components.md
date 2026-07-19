# Extractable Components

## AppTabBar

- Source: `Ask Numi/App/ContentView.swift`
- Category: layout
- Description: Floating four-item Liquid Glass bottom navigation shared by root screens.
- Extractable props: `activeItem` (string, default: `home`)
- Hardcoded: home/list/sparkles/calendar icon set, Russian labels, capsule glass treatment, all layout values.

## AttentionCard

- Source: `Ask Numi/Presentation/Dashboard/HomeDashboardView.swift`
- Category: basic
- Description: Purple-tinted dashboard card with icon, title, detail text, and northeast arrow.
- Extractable props: none; content is page data.
- Hardcoded: corner radius, purple tint, icon container, arrow, glass and stroke styling.
