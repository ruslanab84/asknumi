---
name: repository-pattern
description: Design, implement, or review domain-facing repository contracts and their Swift data-source adapters. Use when adding fetch, save, update, delete, query, batch, mapping, or persistence behavior; when isolating SwiftData from the domain; or when choosing repository boundaries and error semantics.
---

# Repository Pattern

## Workflow

1. Start from the domain operation the caller needs, not from storage API shape.
2. Search existing repository protocols and implementations for the same aggregate.
3. Add the smallest capability to the existing domain protocol.
4. Implement it in the concrete adapter and keep entity mapping inside Data.
5. Wire the existing concrete repository through the composition root.
6. Test or self-check behavior that includes filtering, batching, migration-sensitive mapping, or money data.

## Contract Rules

- Define protocols in the Domain layer using domain models and standard value types.
- Use `async throws` for I/O that can suspend or fail.
- Return domain values, never SwiftData entities or `ModelContext`.
- Keep storage predicates, descriptors, transactions, and entity mapping in Data.
- Express caller-relevant query semantics explicitly, such as a `DateInterval`; do not expose a generic storage query builder.
- Preserve error meaning. Translate storage errors only when the domain can act on the translated case.
- Make multi-item writes atomic when partial persistence would corrupt user intent.
- Keep one repository per aggregate boundary. Do not create a repository for pure calculations or stateless formatting.

## Ask Numi Rules

- Keep protocols such as `TransactionRepository` in `Domain/Repositories` and SwiftData implementations in `Data/Repositories`.
- Use `@ModelActor` for SwiftData repositories that own a serialized `ModelContext`.
- Map through entity initializers and `toDomain()` methods; update both directions when a field changes.
- Treat transaction, subscription, budget, category, and savings-goal data as persisted source of truth.
- Override default sequential batch behavior when Ask Numi requires an atomic import, as receipt imports do.

## Boundaries

- Layer ownership belongs to `$clean-architecture`.
- Construction belongs to `$dependency-injection`.
- Actor and `Sendable` correctness belongs to `$swift-concurrency`.
- SwiftData schema, migrations, and fetch tuning belong to the later `swiftdata` skill.

## Check

- Verify protocol and implementation signatures match.
- Verify every persisted field maps in both directions.
- Verify date bounds, ordering, uniqueness, batching, and failure behavior where applicable.
