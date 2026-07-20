---
name: observation
description: Model SwiftUI presentation state with Apple's Observation framework using @Observable, @State, @Bindable, and @MainActor without introducing Combine. Use when creating or refactoring view state, form models, derived UI state, bindings, asynchronous presentation models, or legacy ObservableObject code.
---

# Observation

## Choose the Smallest Owner

1. Keep a simple value used by one view in `@State`.
2. Create an `@Observable` model when multiple values and actions form one screen state or require asynchronous coordination.
3. Own an injected observable model with `@State` in the view that controls its lifetime.
4. Use `@Bindable` only where a child needs bindings to observable properties.
5. Use environment injection only for genuinely tree-wide presentation state.

## Model Rules

- Mark observable UI models `@MainActor`.
- Expose mutable input properties deliberately; make produced state `private(set)` where callers should not mutate it.
- Keep derived values computed when inexpensive instead of synchronizing duplicate stored state.
- Put user intents in methods with names such as `load`, `save`, or `refreshSuggestion`.
- Inject ports or use cases through the initializer.
- Keep domain calculations and persistence outside the observable model.
- Let SwiftUI own asynchronous work with `.task` or `.task(id:)` when its lifetime matches the view.
- Replace new `ObservableObject`, `@Published`, and Combine pipelines with Observation and async/await unless an existing API requires Combine.
- Do not create a view model for a screen whose state and actions remain trivial.

## Ask Numi Pattern

Use `AddOperationClassificationViewModel` as the compact pattern: `@MainActor`, `@Observable`, injected classifier, mutable input, read-only suggestion, cancellable async refresh, and stale-result protection.

Do not copy legacy `@StateObject` usage into new features merely because app-wide localization still uses it.

## Boundaries

- Screen hierarchy and component extraction belong to `$swiftui-architecture`.
- Cancellation and isolation details belong to `$swift-concurrency`.
- Dependency construction belongs to `$dependency-injection`.
- A later `mvvm` skill may define View/ViewModel communication but must not repeat these property-wrapper rules.

## Check

- Confirm there is one owner for each mutable presentation value.
- Confirm no derived state is stored twice.
- Confirm async results cannot outlive their screen or overwrite newer input.
