---
name: dependency-injection
description: Wire explicit, testable dependencies through an iOS composition root and feature initializers. Use when adding or replacing repositories, use cases, AI or platform adapters, preview or test doubles, app services, or screen dependencies; also use to remove hidden singleton or service-locator coupling.
---

# Dependency Injection

## Workflow

1. Identify the narrowest existing domain contract required by the consumer.
2. Reuse an existing concrete implementation when it already satisfies that contract.
3. Construct long-lived concrete dependencies once in the app composition root.
4. Construct use cases from those dependencies and pass them through initializers.
5. Inject fakes or in-memory implementations directly in tests and previews.
6. Search all initializers and previews after changing a dependency.

## Ask Numi Pattern

- Keep `AppContainer` as the only type that knows the complete concrete graph.
- Keep `AppContainer` on `@MainActor` while it owns app startup and SwiftData container construction.
- Store shared repositories and adapters once; expose small `make...UseCase()` methods where screens need fresh lightweight use-case values.
- Pass `AppContainer` only at the top-level composition boundary. Prefer passing the exact use cases or ports deeper into the view tree.
- Use an in-memory `ModelContainer` for persistence tests rather than adding a second production graph.

## Rules

- Prefer constructor injection for required dependencies.
- Use default arguments only for harmless values, not to hide production services.
- Use SwiftUI environment values for truly tree-wide presentation concerns such as localization or appearance, not as a general service locator.
- Keep global singletons only where an existing platform-wide concern requires them; do not introduce new ones for feature dependencies.
- Do not add a protocol solely to mock a concrete value with no external behavior or alternate implementation need.
- Do not add a DI framework; the current graph is small and explicit Swift is sufficient.

## Boundaries

- Decide which layer owns the dependency with `$clean-architecture`.
- Define data contracts with `$repository-pattern`.
- Apply actor isolation with `$swift-concurrency`.
- Design screen composition with `$swiftui-architecture`.

## Check

- Confirm concrete types appear only in App, Data, or Infrastructure as appropriate.
- Confirm domain and presentation consumers can be initialized with a test substitute.
- Confirm the dependency has one clear lifetime and no duplicate production instance.
