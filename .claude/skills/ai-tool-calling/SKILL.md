---
name: ai-tool-calling
description: Design, implement, or review Foundation Models Tool conformances, tool selection, arguments, authorization, outputs, errors, and side-effect safety. Use when a LanguageModelSession needs model-directed access to app data or actions; do not add tools for deterministic data that can be supplied directly in the prompt.
---

# AI Tool Calling

## Tool Decision

Add a tool only when the model must decide whether or how to request dynamic information during generation. Fetch deterministic required data before generation and include a compact result in the prompt.

Ask Numi's current advisor does not need tools: its use case already fetches transactions and computes `FinancialSummary`. Keep that path until a real model-directed lookup is required.

## Workflow

1. Define the exact user task and why prompt context cannot satisfy it.
2. Reuse an existing domain use case or repository port behind the tool.
3. Give the tool a short verb-led name and one-sentence description.
4. Define the smallest `@Generable` arguments with constrained values.
5. Authorize and validate every call using current app state.
6. Return a compact, clearly labeled result without secrets or unrelated records.
7. Register only the tools needed for that session and evaluate call selection.

## Safety Rules

- Treat model arguments as untrusted input.
- Enforce account, date-range, category, and record access in Swift, not in the prompt.
- Never expose raw persistence entities, tokens, credentials, or full transaction history by default.
- Keep tool results untrusted when they contain user-authored text.
- Return bounded results and explicit empty states to protect the shared context window.
- Convert internal errors to safe, actionable tool failures; do not leak implementation details.
- Keep tools `Sendable` and respect actor isolation through `$swift-concurrency`.

## Side Effects

- Prefer read-only tools.
- Do not let the model autonomously add, edit, delete, transfer, subscribe, or change a budget.
- Generate a proposed draft, show the exact effect, require explicit user confirmation, then execute the domain use case outside generation.
- Make unavoidable write operations idempotent and auditable.
- Recheck authorization and validation at execution time; prior model text is not approval.

## Foundation Models Shape

- Conform a concrete type to `Tool`.
- Use an `@Generable` `Arguments` type; primitive argument types are unsupported as direct tool arguments in the iOS 26.5 SDK.
- Keep `name`, `description`, argument schema, and output short because each consumes context.
- Let thrown errors stop a failed call; never return a fabricated success string.

## Boundaries

- Session construction belongs to `$ios-foundation-models`.
- Argument schemas belong jointly to `$ai-structured-output`.
- Prompt grounding belongs to `$ai-prompt-engineering`.
- User review and confirmation UI belongs to `$ai-feature-design`.

## Check

- Test unnecessary-call, missing-call, repeated-call, invalid-argument, authorization, cancellation, empty-result, and error paths.
- Verify no financial mutation can occur from model choice alone.
