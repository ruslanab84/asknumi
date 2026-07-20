---
name: local-ai
description: Choose and integrate the smallest private on-device intelligence approach for an Ask Numi feature. Use when deciding between deterministic Swift, Natural Language, Vision, Core ML, and Apple Foundation Models; when defining fallback behavior and data flow; or when reviewing whether a proposed AI dependency is necessary.
---

# Local AI

## Selection Ladder

Stop at the first option that solves the task:

1. Deterministic Swift for calculations, validation, parsing with stable rules, and known finance policy.
2. Native deterministic frameworks such as Vision or Natural Language for OCR and language processing.
3. Existing Core ML models for bounded prediction tasks with known labels.
4. Foundation Models for flexible extraction, classification, summarization, or grounded phrasing.
5. No feature or a manual fallback when no local option is reliable enough.

Do not add a server model, MLX runtime, llama.cpp, or a multi-backend abstraction without an explicit product requirement that the current stack cannot satisfy.

## Ask Numi Map

- Use Swift domain code for totals, trends, budgets, dates, evidence, and validation.
- Use Vision for receipt text recognition.
- Use the bundled Core ML classifier for merchant-category prediction.
- Use Foundation Models for natural transaction extraction and concise phrasing of verified financial summaries.
- Keep every AI output behind an existing domain port and preserve a deterministic or manual path when the model is unavailable.

## Architecture Rules

- Keep private financial data on device unless the product explicitly introduces a disclosed remote flow.
- Send the minimum data needed for one task, even when inference is local.
- Reuse existing models, ports, and adapters before adding a parallel engine.
- Keep model availability out of Domain by mapping it to domain-level states.
- Keep model-specific types in Infrastructure.
- Avoid a generic `AIService`; name ports after domain capabilities such as parsing or advising.
- Add caching only after measuring repeated expensive work and define its invalidation source.

## Product Rules

- Do not make core transaction entry, editing, or reporting depend exclusively on Apple Intelligence availability.
- Explain unavailable or downloading states in localized English and Russian UI.
- Provide review and correction for extracted or generated content.
- Do not imply that on-device execution makes generated facts accurate.
- Validate generative latency and Foundation Models behavior on an eligible physical device; Simulator remains useful for deterministic fallbacks and UI states.

## Boundaries

- Foundation Models APIs belong to `$ios-foundation-models`.
- Core ML implementation details belong to the existing `coreml` skill.
- Feature interaction belongs to `$ai-feature-design`.
- Finance recommendation policy belongs to the later `financial-ai-coach` skill.

## Check

- Confirm the chosen rung is the first one that satisfies the task.
- Confirm unavailable AI never blocks unrelated finance workflows.
- Confirm no duplicate model or abstraction was added without a current caller.
