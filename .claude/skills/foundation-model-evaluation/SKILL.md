---
name: foundation-model-evaluation
description: Build, run, or review repeatable evaluations for Ask Numi Foundation Models prompts, structured outputs, tool choices, fallbacks, and user-facing AI behavior. Use before shipping or changing an AI feature, prompt, schema, model-backed parser, advisor, locale, or operating-system model version.
---

# Foundation Model Evaluation

## Workflow

1. Define the user task and hard invariants before editing the prompt or schema.
2. Select relevant cases from [Ask Numi evaluation cases](references/ask-numi-cases.md) and add a regression case for the reported failure.
3. Record OS and SDK version, device, locale, model availability, prompt revision, schema revision, and generation options.
4. Run deterministic domain and fallback checks separately from model checks.
5. Run model cases on an eligible physical device.
6. Classify failures, change one variable, and rerun the same cases.
7. Keep the smallest prompt or schema change that passes hard gates and improves the target quality dimension.

## Evaluation Layers

### Hard gates

- No invented personal amount, transaction, category, date, currency, balance, or guarantee.
- No persistence or financial mutation without explicit confirmation and domain validation.
- Structured output always decodes or fails safely.
- Unsupported locale, unavailable assets, refusal, cancellation, and context overflow produce a valid fallback state.
- User text and saved labels cannot override instructions.

### Quality rubric

Score groundedness, task relevance, missing-data honesty, language correctness, brevity, actionability, and consistency with displayed evidence. Do not score prose style above factual grounding.

### Runtime signals

Measure first-response latency, completion latency, cancellations, context usage, tool-call count, decoding failures, and fallback frequency where the API exposes them.

## Regression Design

- Prefer semantic assertions and domain invariants over exact generated sentences.
- Use greedy or seeded sampling for stable regression runs.
- Run a separate small randomized sample to expose variation.
- Include English, Russian, transliterated Russian, sparse data, conflicting requests, malicious labels, large category sets, and boundary amounts.
- Use synthetic or anonymized financial data. Do not store private transaction text in fixtures or logs.
- Rebaseline quality after an OS model update; do not silently relax safety gates.

## Failure Labels

Use one primary label: `hallucination`, `grounding`, `injection`, `schema`, `locale`, `availability`, `refusal`, `context`, `tool-selection`, `latency`, `cancellation`, or `ux`.

## Boundaries

- This skill defines evaluation cases and acceptance criteria, not the Phase 4 XCTest architecture.
- Prompt changes belong to `$ai-prompt-engineering`.
- Schema changes belong to `$ai-structured-output`.
- Product-state failures belong to `$ai-feature-design`.

## Check

- Require zero hard-gate failures before shipping.
- Attach every fixed production failure to a permanent regression case.
- Report environment and case counts with results so comparisons remain meaningful.
