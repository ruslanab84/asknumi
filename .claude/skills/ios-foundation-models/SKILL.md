---
name: ios-foundation-models
description: Implement or review Apple's Foundation Models framework on iOS, including SystemLanguageModel availability and locale support, LanguageModelSession lifecycle, instructions, prompts, streaming, transcripts, context limits, generation options, and errors. Use for FoundationModels imports or on-device language-model integration; delegate prompt content, tools, and schemas to their focused skills.
---

# iOS Foundation Models

## Start from the Project SDK

1. Read the deployment target and Swift settings.
2. Inspect the installed SDK `FoundationModels.swiftinterface` before using newly documented APIs.
3. Treat current Apple web documentation as guidance, because it may describe a newer beta SDK.
4. Keep Ask Numi compatible with its current iOS 26.5 SDK unless the user requests a target upgrade.

## Workflow

1. Check `SystemLanguageModel.default.availability` and `supportsLocale(_:)` before exposing generation.
2. Map `.modelNotReady`, `.appleIntelligenceNotEnabled`, and `.deviceNotEligible` to distinct domain or UI states where useful.
3. Choose a session lifetime: create a fresh session for isolated transformations; retain one only when transcript context is part of the feature.
4. Put stable role and safety rules in instructions. Put user content and task-specific verified data in the prompt.
5. Register only necessary tools and request the smallest useful output schema.
6. Prevent concurrent requests on one session and preserve task cancellation.
7. Handle generation errors and provide a non-model fallback.

## iOS 26.5 Baseline

- Use `LanguageModelSession(model:tools:instructions:)`, `respond`, `streamResponse`, `transcript`, `isResponding`, and `prewarm(promptPrefix:)`.
- Use `SystemLanguageModel.contextSize` instead of hardcoding a context limit.
- Use `tokenCount(for:)` where the iOS 26.4 availability requirement is satisfied and prompt size is material.
- Handle `LanguageModelSession.GenerationError` cases such as context overflow, unavailable assets, guardrails, unsupported locale or guide, decoding failure, rate limiting, concurrent requests, and refusal.
- Do not adopt iOS 27-only `LanguageModel` or dynamic-profile APIs in the iOS 26.5 target without an explicit availability design.
- Treat `LanguageModelSession` as one-request-at-a-time even though the SDK exposes it as `Sendable`.

## Ask Numi Placement

- Keep Foundation Models adapters in `Infrastructure/AI` behind domain ports such as `FinancialAdvisor` and `TransactionParser`.
- Keep Presentation and Domain free of `FoundationModels` imports.
- Keep deterministic finance calculations in Swift and send only compact verified summaries to the model.
- Keep transaction extraction as a draft that is validated and reviewed before persistence.
- Use the app's selected English or Russian locale and retain localized deterministic fallbacks.

## Boundaries

- Write and test instruction text with `$ai-prompt-engineering`.
- Define generated Swift values with `$ai-structured-output`.
- Add tools only through `$ai-tool-calling`.
- Choose between Foundation Models, Core ML, Vision, or plain Swift with `$local-ai`.
- Apply actor and task rules from `$swift-concurrency`.

## Check

- Verify unavailable, unsupported-locale, refusal, cancellation, and context-overflow paths.
- Verify no model response is the source of truth for money or persisted state.
- Build with the current Xcode SDK and test model behavior on an eligible physical device.

## Apple References

- [LanguageModelSession](https://developer.apple.com/documentation/foundationmodels/languagemodelsession)
- [Foundation Models updates](https://developer.apple.com/documentation/updates/foundationmodels)
- [WWDC25 Foundation Models deep dive](https://developer.apple.com/videos/play/wwdc2025/301/)
