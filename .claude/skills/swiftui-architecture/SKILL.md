---
name: swiftui-architecture
description: Design, implement, or refactor SwiftUI screen composition, navigation, reusable components, and presentation-layer boundaries in an iOS app. Use for changes to SwiftUI views, screen hierarchy, sheets, navigation flows, view decomposition, or shared visual components; defer state ownership, business rules, and performance audits to their dedicated skills.
---

# SwiftUI Architecture

## Workflow

1. Read the complete screen and its parent container before editing.
2. Search for an existing component or screen pattern and reuse it.
3. Trace each displayed value and user action to its current owner.
4. Keep the view declarative: render state and send user intents.
5. Make the smallest composition change that preserves navigation, localization, accessibility, and previews or call sites.
6. Build the affected target.

## Rules

- Keep ephemeral presentation state such as sheet visibility or focus in `@State`.
- Move coordinated or asynchronous screen state to an Observation model; use `$observation` for ownership rules.
- Call domain use cases for business actions. Do not fetch SwiftData entities or encode financial policy in a view.
- Pass required dependencies through initializers. Use `$dependency-injection` when wiring crosses the screen boundary.
- Use `NavigationStack`, `sheet`, `alert`, and other native SwiftUI presentation APIs before custom coordinators.
- Extract a component when it is reused or when extraction makes a long screen materially easier to read. Keep one-off fragments local.
- Parameterize shared components instead of adding feature-specific branches.
- Preserve semantic controls, labels, Dynamic Type, and tappable areas.
- Keep formatting near presentation, but keep calculations in the domain.

## Ask Numi Placement

- Put screens and presentation models in `Ask Numi/Presentation`.
- Treat `ContentView` as top-level composition and `AppContainer` as dependency wiring, not business logic.
- Reuse existing dashboard, operation, plan, and settings components before creating parallel UI.
- Display deterministic financial evidence supplied by the domain; do not invent calculations in SwiftUI.

## Boundaries

This skill does not define:

- layer direction or use-case placement — use `$clean-architecture`;
- observable model mechanics — use `$observation`;
- actor isolation or cancellation — use `$swift-concurrency`;
- visual compliance or rendering performance — use the later HIG and performance skills.

## Check

- Confirm the view has no direct persistence dependency or duplicated domain calculation.
- Confirm every new reusable component has a real caller.
- Run the project build after non-trivial edits.
