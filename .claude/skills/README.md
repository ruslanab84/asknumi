# Ask Numi iOS Skills

Project-local skills for building and reviewing Ask Numi with Claude Code or Codex. Each skill owns one concern and links to adjacent skills instead of repeating their rules.

Claude Code reads `.claude/skills`. Codex uses the `.agents/skills` symlink, so both tools share these same files.

## Phase 1

| Skill | Owns |
| --- | --- |
| `swiftui-architecture` | SwiftUI composition, navigation, and reusable UI |
| `clean-architecture` | Layer boundaries and dependency direction |
| `repository-pattern` | Domain data contracts and data-source implementations |
| `dependency-injection` | Composition root and explicit dependency wiring |
| `swift-concurrency` | Isolation, structured concurrency, and cancellation |
| `observation` | Observable UI state without Combine |

## Phase 2

| Skill | Owns |
| --- | --- |
| `ios-foundation-models` | Foundation Models availability, sessions, streaming, context, and errors |
| `ai-prompt-engineering` | Grounded instructions and prompt construction |
| `ai-tool-calling` | Minimal, authorized model tools |
| `ai-structured-output` | `@Generable`, `@Guide`, schemas, and output validation |
| `local-ai` | Selection between deterministic Swift, Vision, Core ML, and Foundation Models |
| `foundation-model-evaluation` | Ask Numi AI regression cases and quality gates |
| `ai-feature-design` | Native, trustworthy AI product interactions |

## Phase 3

| Skill | Owns |
| --- | --- |
| `swiftdata` | Ask Numi entities, mappings, queries, migrations, and model actors |
| `budget-domain` | Transactions, budgets, goals, subscriptions, forecasts, and insights |
| `financial-ai-coach` | Evidence-grounded personal-finance coaching policy |

## Boundaries

```text
SwiftUI -> use cases -> domain ports <- data/infrastructure adapters
   |           |                    |
Observation  Concurrency       Dependency injection
```

- Keep domain policy in domain models and use cases.
- Keep persistence and framework models behind repositories.
- Keep concrete construction in the composition root.
- Keep view state in Observation types only when local `@State` is insufficient.
- Follow links in a skill only when the task crosses that boundary.

## Roadmap

- Phase 4: `mvvm`, `performance-review`, `code-review`, `testing`, `human-interface-guidelines`, final consistency pass.

The planned library contains 18 general iOS skills and 3 Ask Numi-specific skills.
