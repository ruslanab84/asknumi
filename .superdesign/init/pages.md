# Page Dependency Trees

## Home dashboard

Entry: `Ask Numi/Presentation/Dashboard/HomeDashboardView.swift`

Dependencies:
- `Ask Numi/App/ContentView.swift`
- `Ask Numi/Presentation/Dashboard/FinancialTwinView.swift`
- `Ask Numi/Presentation/Settings/SettingsView.swift`
- `Ask Numi/Presentation/Operations/OperationsView.swift` (`OperationFormatting`, `TransactionKind.title`)
- `Ask Numi/Domain/Models/FinancialSummary.swift`
- `Ask Numi/Domain/Models/Transaction.swift`
- `Ask Numi/Domain/Models/Budget.swift`
- `Ask Numi/Domain/Models/Subscription.swift`
- `Ask Numi/Domain/Models/FinancialTwin.swift`
- `Ask Numi/Infrastructure/CurrencySettings.swift`
- `Ask Numi/Infrastructure/Localization/L10n.swift`
- `Ask Numi/Resources/Localizations/ru.lproj/Localizable.strings`
- `Ask Numi/Infrastructure/CategoryColor+SwiftUI.swift`

## Operations

Entry: `Ask Numi/Presentation/Operations/OperationsView.swift`

Dependencies:
- `Ask Numi/App/ContentView.swift`
- `Ask Numi/Presentation/Categories/NewCategoryView.swift`
- `Ask Numi/Presentation/Operations/AddOperationClassificationViewModel.swift`
- `Ask Numi/Domain/Models/Transaction.swift`
- `Ask Numi/Domain/Models/TransactionCategory.swift`
- `Ask Numi/Infrastructure/CurrencySettings.swift`
- `Ask Numi/Infrastructure/Localization/L10n.swift`

## Assistant

Entry: `Ask Numi/Presentation/Assistant/AssistantView.swift`

Dependencies:
- `Ask Numi/App/ContentView.swift`
- `Ask Numi/Domain/Models/FinancialAdvice.swift`
- `Ask Numi/Infrastructure/Localization/L10n.swift`

## Plan

Entry: `Ask Numi/Presentation/Plan/PlanView.swift`

Dependencies:
- `Ask Numi/App/ContentView.swift`
- `Ask Numi/Presentation/Plan/SavingsGoalsView.swift`
- `Ask Numi/Domain/Models/Budget.swift`
- `Ask Numi/Domain/Models/Subscription.swift`
- `Ask Numi/Domain/Models/SavingsGoal.swift`
- `Ask Numi/Infrastructure/CurrencySettings.swift`
- `Ask Numi/Infrastructure/Localization/L10n.swift`

## Settings

Entry: `Ask Numi/Presentation/Settings/SettingsView.swift`

Dependencies:
- `Ask Numi/Infrastructure/CurrencySettings.swift`
- `Ask Numi/Infrastructure/CategoryColor+SwiftUI.swift`
- `Ask Numi/Infrastructure/Localization/LocalizationManager.swift`
- `Ask Numi/Infrastructure/Localization/L10n.swift`
