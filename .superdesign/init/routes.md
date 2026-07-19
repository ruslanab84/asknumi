# Screen Routes

Ask Numi is a native SwiftUI app with state-driven tab routing rather than URL routes.

| Route | Root view | Shared layout |
| --- | --- | --- |
| `home` | `Ask Numi/Presentation/Dashboard/HomeDashboardView.swift` | `AppTabBar` |
| `operations` | `Ask Numi/Presentation/Operations/OperationsView.swift` | `AppTabBar` |
| `assistant` | `Ask Numi/Presentation/Assistant/AssistantView.swift` | `AppTabBar` |
| `plan` | `Ask Numi/Presentation/Plan/PlanView.swift` | `AppTabBar` |
| `settings` modal | `Ask Numi/Presentation/Settings/SettingsView.swift` | full-screen cover from Home |
| `financial-twin` sheet | `Ask Numi/Presentation/Dashboard/FinancialTwinView.swift` | sheet from Home |

The full routing source is included in `layouts.md`. The app launches on `home` because `ContentView.selectedTab` defaults to `.home`.
