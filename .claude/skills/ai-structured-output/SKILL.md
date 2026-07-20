---
name: ai-structured-output
description: Design, implement, or review Foundation Models guided generation with @Generable, @Guide, GenerationSchema, GeneratedContent, and streaming partial values. Use when model output must decode into Swift types, obey value or count constraints, or map into validated domain drafts; exclude general prompting and tool authorization.
---

# AI Structured Output

## Workflow

1. Define the smallest output needed by the caller.
2. Prefer a compile-time `@Generable` type; use a dynamic `GenerationSchema` only when the schema truly depends on runtime data.
3. Order properties so foundational values appear before values that depend on them.
4. Use clear property names and add `@Guide` only when it improves meaning or constrains risk.
5. Generate into an Infrastructure type, then validate and map into a domain value.
6. Test decoding failures, missing meaning, and adversarial inputs.

## Schema Rules

- Use `.anyOf` or a `@Generable` enum for a closed vocabulary.
- Use `.range`, `.minimum`, and `.maximum` for supported numeric limits.
- Use `.count`, `.minimumCount`, `.maximumCount`, and `.element` for arrays.
- Use a regex guide only for a format the model can reasonably produce.
- Keep schemas shallow and omit unused properties; schema text shares the model context window.
- Do not repeat the entire schema in prompt prose unless evaluation proves it necessary.
- Prefer explicit empty values when downstream logic requires a distinction from omission.

## Validation Boundary

Guided generation guarantees shape, not truth.

- Trim strings and reject empty required values.
- Validate ranges, currencies, dates, identifiers, and domain invariants in Swift.
- Verify extracted amounts against the source text when money is involved.
- Convert floating-point extraction to `Decimal` deliberately at the domain boundary.
- Never persist generated content directly.
- Treat a decoding failure as a recoverable model failure, not as permission to accept raw text.

## Streaming

- Use `streamResponse` only when partial content improves the experience.
- Treat `PartiallyGenerated` properties as incomplete and optional.
- Render partial values without triggering domain actions or persistence.
- Commit only the final validated content after successful stream completion.
- Cancel streaming when the owning view disappears or its input changes.

## Ask Numi Patterns

- Keep `SpendingOverviewOutput`, `SpendingTrendOutput`, and `AdviceOutput` private to the Foundation Models adapter.
- Keep `ParsedTransactionOutput` separate from `ParsedTransactionDraft`; map only after amount, kind, category, and note validation.
- Cap advice tips in the schema and still verify grounding against the supplied summary.

## Boundaries

- Prompt wording belongs to `$ai-prompt-engineering`.
- Tool invocation and authorization belong to `$ai-tool-calling`.
- Session errors and context management belong to `$ios-foundation-models`.

## Apple Reference

- [Generable](https://developer.apple.com/documentation/foundationmodels/generable)
