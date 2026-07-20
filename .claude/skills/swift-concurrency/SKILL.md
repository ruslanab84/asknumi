---
name: swift-concurrency
description: Implement or review structured concurrency, actor isolation, Sendable boundaries, cancellation, async sequences, and task lifetime in Swift. Use for async/await code, Tasks, actors, @MainActor state, SwiftData model actors, debouncing, parallel work, streaming, or Swift concurrency compiler diagnostics.
---

# Swift Concurrency

## Workflow

1. Identify the mutable state and the actor that owns it.
2. Trace every task from creation through completion, cancellation, and error handling.
3. Prefer direct `async` calls and structured child tasks.
4. Add parallelism only for independent work with measured benefit.
5. Preserve cancellation and verify UI updates occur on the main actor.
6. Build with the project's current strict-concurrency settings.

## Rules

- Mark UI-facing mutable models `@MainActor`.
- Use actors or framework actors such as `@ModelActor` for shared mutable non-UI state.
- Keep values crossing isolation boundaries `Sendable`; prefer immutable domain values.
- Use `.task` or `.task(id:)` when SwiftUI should own task lifetime.
- Treat cancellation as normal control flow. Do not convert `CancellationError` into a user-visible failure.
- Check `Task.isCancelled` and stale input before publishing delayed or expensive results.
- Use `async let` or task groups only when operations are independent.
- Avoid `Task.detached` unless work must intentionally escape actor context and task hierarchy.
- Never block an async context with semaphores, synchronous waits, or arbitrary sleeps.
- Do not use `@unchecked Sendable` until the protected invariant is documented and verified.

## Ask Numi Patterns

- Keep presentation models such as classification state on `@MainActor`.
- Use cancellable delays for debounce and compare the captured input before applying a classification result.
- Keep SwiftData access inside `@ModelActor` repositories.
- Preserve atomic persistence for receipt imports and other multi-transaction user actions.
- Keep Foundation Models streaming tied to the consuming screen task so leaving the screen cancels work.

## Boundaries

- Observable ownership and bindings belong to `$observation`.
- Repository semantics belong to `$repository-pattern`.
- SwiftUI task placement belongs jointly to `$swiftui-architecture`.
- Performance measurement belongs to the later `performance-review` skill.

## Check

- Confirm every unstructured `Task` has an intentional owner.
- Confirm cancellation cannot publish stale state or partial financial data.
- Confirm compiler isolation warnings are fixed at the owning boundary, not silenced.
