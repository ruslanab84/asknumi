---
name: ai-feature-design
description: Design or review Ask Numi AI capabilities as native iOS product features with clear value, states, evidence, privacy, correction, and fallback behavior. Use when shaping an AI interaction, deciding between inline assistance and chat, presenting generated content, handling model availability, or requiring user review before actions.
---

# AI Feature Design

## Start with the User Task

1. Name the existing finance task and the exact friction AI removes.
2. Define the deterministic or manual path before the AI enhancement.
3. Place assistance at the task's point of use.
4. Define input, generation, review, correction, confirmation, and failure states.
5. Verify that the feature remains useful when generation is unavailable.

Do not create a chat surface when an inline suggestion, generated draft, smart filter, evidence card, or one-tap action completes the task more directly.

## Ask Numi Patterns

- Parse natural transaction text into a prefilled add-operation form; never save directly.
- Phrase verified financial summaries beside their totals, charts, interval, and evidence.
- Use deterministic dashboard insights when the model is unavailable or adds no value.
- Offer AI Coach recommendations only after the domain supplies budgets, goals, transactions, and explicit missing inputs.
- Keep charts and financial data primary; generated prose explains rather than replaces them.

## States

Design localized English and Russian UI for:

- available and idle;
- preparing or downloading model assets;
- generating with a task-specific progress message;
- partial output when streaming adds value;
- completed output with evidence;
- editable or confirmable draft;
- refusal, unsupported locale, cancellation, and recoverable error;
- unavailable feature with a manual or deterministic alternative.

## Trust and Agency

- Tell people when content is generated and can be wrong where that affects decisions.
- Show the data period, currency, totals, and method behind financial conclusions.
- Provide Edit, Retry, Undo, or Cancel where each action is meaningful.
- Require explicit confirmation before adding or changing financial records.
- Never use urgency, certainty, or visual authority to overstate a probabilistic result.
- Keep private data on device and disclose any future remote processing before it occurs.

## Native Experience

- Reuse SwiftUI navigation, forms, sheets, charts, alerts, accessibility labels, Dynamic Type, and app appearance.
- Use familiar finance language instead of model terminology.
- Make progress text specific, such as analyzing recorded spending, rather than generic processing copy.
- Preserve interaction during longer generation when safe and allow cancellation.
- Avoid decorative AI branding that competes with the user's financial content.

## Boundaries

- SwiftUI composition belongs to `$swiftui-architecture`.
- Framework selection belongs to `$local-ai`.
- Prompt and schema correctness belong to `$ai-prompt-engineering` and `$ai-structured-output`.
- Evaluation belongs to `$foundation-model-evaluation`.
- Detailed visual compliance belongs to the later `human-interface-guidelines` skill.

## Check

- Confirm AI removes measurable task friction rather than merely adding conversation.
- Confirm every generated value can be reviewed, corrected, retried, or safely ignored.
- Confirm model unavailability does not strand the user.
- Confirm displayed evidence and persisted effects come from deterministic app logic.

## Apple Reference

- [Human Interface Guidelines: Generative AI](https://developer.apple.com/design/human-interface-guidelines/generative-ai)
