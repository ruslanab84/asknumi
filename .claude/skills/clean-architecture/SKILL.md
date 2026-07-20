---
name: clean-architecture
description: Place iOS feature code across presentation, domain, data, infrastructure, and app composition while preserving dependency direction and testable boundaries. Use when adding a feature end to end, deciding where logic belongs, reviewing cross-layer coupling, or changing a domain model, use case, adapter, or composition root.
---

# Clean Architecture

## Dependency Rule

Keep dependencies pointing inward:

```text
Presentation -> Domain <- Data / Infrastructure
        App composition constructs and connects concrete types
```

The domain may import Foundation but must not depend on SwiftUI, SwiftData, Vision, Foundation Models, or concrete adapters.

## Workflow

1. Trace the requested behavior from UI entry point through domain policy, persistence or service ports, concrete adapters, and composition root.
2. Reuse the existing layer and type that already owns the behavior.
3. Put business invariants and calculations in domain models or use cases.
4. Define a domain port only when the domain must call an external capability or data source.
5. Implement that port in Data or Infrastructure and wire it in App.
6. Verify mapping, validation, error propagation, and all call sites end to end.

## Ask Numi Layer Map

- `App`: composition root and app lifecycle.
- `Presentation`: SwiftUI screens and presentation state.
- `Domain/Models`: finance concepts and invariants.
- `Domain/UseCases`: application actions and orchestration.
- `Domain/Repositories`: domain-facing ports.
- `Data/Local`: SwiftData entities and persistence mapping.
- `Data/Repositories`: repository adapters.
- `Infrastructure`: Foundation Models, Vision, Core ML, localization, and platform adapters.

## Rules

- Prefer extending an existing model, use case, or port over adding a parallel abstraction.
- Create a use case for a meaningful application action, not for a one-line format or property access.
- Keep framework types at the outer layer and map them to domain values at the boundary.
- Make invalid domain states unrepresentable when practical; otherwise validate before persistence.
- Preserve one source of truth for each value through model, entity mapping, edit restoration, and display.
- Do not create interfaces, factories, or layers with only speculative future value.

## Boundaries

- Repository contract details belong to `$repository-pattern`.
- Concrete construction belongs to `$dependency-injection`.
- SwiftUI composition belongs to `$swiftui-architecture`.
- Isolation details belong to `$swift-concurrency`.

## Check

- Search every constructor and caller of changed types.
- Confirm no inner layer imports an outer framework.
- Confirm the feature works through every affected layer, not only the visible screen.
