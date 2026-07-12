# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Ask Numi is a personal finance iOS app with AI-powered insights. Primary audience: Russian-speaking users in Azerbaijan (currency: AZN, primary UI language: Russian). Deployment target: iOS 26.5+, Swift 5, iPhone + iPad.

## Build Commands

```bash
# Build for simulator
xcodebuild -project "Ask Numi.xcodeproj" -scheme "Ask Numi" -destination "platform=iOS Simulator,name=iPhone 17" build

# Run tests (once a test target exists)
xcodebuild -project "Ask Numi.xcodeproj" -scheme "Ask Numi" -destination "platform=iOS Simulator,name=iPhone 17" test

# Run a single test class
xcodebuild -project "Ask Numi.xcodeproj" -scheme "Ask Numi" -destination "platform=iOS Simulator,name=iPhone 17" test -only-testing:"Ask NumiTests/ClassName"
```

Prefer the `BuildProject` MCP tool (xcode-tools) for faster incremental builds during development, and `XcodeRefreshCodeIssuesInFile` for quick per-file type checking.

## Architecture

The project follows **Clean Architecture + MVVM**. Full detail is in `ARCHITECTURE.md`; the rules that matter most day-to-day:

- **Four layers:** Presentation → Domain → Data → Infrastructure. Dependencies only point inward.
- **Views** contain zero business logic and zero networking. They observe a `@MainActor` `ViewModel` and send user intents to it.
- **ViewModels** call use-cases, map domain models to UI models (`DashboardSnapshot`, `TransactionRow`), and own `@Published` loading/error state.
- **Domain** has no UIKit/SwiftUI imports. Repository protocols live here; implementations live in Data.
- **Dependency injection** via `AppContainer` (composition root in `App/`). No singletons accessed inside business logic.
- **async/await only** — no Combine, no callbacks anywhere.

### Canonical folder layout (target state)

```
Presentation/{Screen}/  — View + ViewModel + Components/
Domain/Models/          — pure Swift value types
Domain/Repositories/    — protocols only
Domain/UseCases/        — one file per use-case
Data/Repositories/      — protocol implementations
Data/Remote/DTOs/       — Decodable network response types
Infrastructure/Network/ — NetworkClient (URLSession wrapper)
Infrastructure/Localization/ — LocalizationManager, L10n enum
```

## Localization

Full rules are in `LOCALIZATION_RULES.md`. The critical constraints:

- **No raw string literals in Views, ViewModels, or UseCases.** Every user-visible string must go through `L10n`.
- `L10n` is the only place that calls into `LocalizationManager`; views never touch `NSLocalizedString` directly.
- Keys follow `screen.component.element` dot-notation (e.g. `dashboard.balance_card.label.total_balance`).
- Plurals live in `.stringsdict`; never concatenate a count into a translated string.
- Currency and dates must use locale-aware formatters (`CurrencyFormatter`, `DateFormatter+Localized`), never string interpolation.

## UI

The app uses the **Liquid Glass** design system introduced in iOS 26 (`.glassEffect()` modifier, `GlassEffectContainer`). When working on UI:

- Search Apple developer documentation for `glassEffect` / `GlassEffectContainer` before assuming behavior — this API is new and may differ from training data.
- Use `.leading` / `.trailing` layout semantics (never hardcoded left/right) for future RTL readiness.
- Text alignment uses `.leading`, not `.left`.
- `@MainActor` is required on every `ViewModel`.
