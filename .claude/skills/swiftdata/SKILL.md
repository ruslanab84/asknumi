---
name: swiftdata
description: Implement, migrate, optimize, or review Ask Numi persistence with SwiftData. Use when changing @Model entities, ModelContainer registration, entity-domain mappings, @ModelActor repositories, FetchDescriptor or #Predicate queries, atomic writes, unique attributes, legacy defaults, schema compatibility, or in-memory stores.
---

# Ask Numi SwiftData

## Architecture

Keep SwiftData behind the Data layer:

```text
Domain model <-> Data/Local entity <-> @ModelActor repository
                                      |
                                ModelContainer
```

Do not expose `@Model`, `ModelContext`, `FetchDescriptor`, or `PersistentIdentifier` to Domain or Presentation. Ask Numi uses repository-driven fetching rather than direct `@Query` in screens.

## Workflow

1. Trace the field or behavior through domain model, entity, both mapping directions, repository, use case, editor restoration, and display.
2. Inspect every entity registered in `AppContainer` before changing the schema.
3. Choose the smallest compatible storage change.
4. Keep queries and writes inside the existing aggregate repository.
5. Add explicit migration handling when a stored value must be renamed, transformed, split, combined, or made required.
6. Verify with an in-memory container and the existing store compatibility path.

## Entity Rules

- Define persistence classes in `Data/Local` with `@Model`.
- Keep domain structs as `Sendable` values and map at the repository boundary.
- Persist money as `Decimal`, identifiers as `UUID`, and enum values as stable raw strings when legacy tolerance matters.
- Map unknown required enum raw values to a rejected row with `compactMap`; map missing optional legacy fields to a safe documented default.
- Keep `@Attribute(.unique)` only for actual identity or a proven invariant such as normalized budget category key.
- Add relationships only when object-graph ownership is real; otherwise keep independent aggregates linked by stable values or IDs.
- Do not store derived totals, budget progress, savings health, or AI conclusions when they can be recomputed from source records.

## Schema Compatibility

- Prefer additive optional or defaulted fields for simple backward-compatible changes.
- Use `@Attribute(originalName:)` for a pure rename when supported by the deployment SDK.
- Introduce `VersionedSchema` and `SchemaMigrationPlan` for destructive or transformational changes.
- Never delete or recreate the user's store as a migration shortcut.
- Update `ModelContainer` registration whenever adding a new root entity.
- Keep CloudKit out of scope until sync is explicitly requested and capabilities are configured.

## Repositories and Concurrency

- Use one `@ModelActor` repository per existing aggregate boundary.
- Call `modelContext.save()` explicitly after writes.
- Use `modelContext.transaction` for imports or multi-record changes that must not partially persist.
- Keep predicates narrow and capture local scalar bounds before `#Predicate`.
- Return domain values before crossing the actor boundary; never pass live entities or `ModelContext`.
- Preserve ordering in the fetch descriptor when the UI or domain relies on it.

## Performance

- Fetch by required period or identifier instead of loading all history when a bounded query exists.
- Use `fetchLimit`, `fetchCount`, or indexes only for a measured query path.
- Avoid speculative relationships, prefetching, caching, and indexes.
- Keep receipt images out of persistence; save extracted transaction data only.

## Boundaries

- Repository contract semantics belong to `$repository-pattern`.
- Actor isolation belongs to `$swift-concurrency`.
- Finance invariants belong to `$budget-domain`.
- App construction belongs to `$dependency-injection`.

## Check

- Verify every stored field maps both ways and legacy rows remain readable.
- Verify uniqueness, sorting, half-open date bounds, atomicity, and explicit saves.
- Verify the change with an in-memory store and a normal project build.

## Apple References

- [Preserving model data across launches](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches)
- [ModelActor](https://developer.apple.com/documentation/swiftdata/modelactor)
