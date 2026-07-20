---
name: budget-domain
description: Implement or review Ask Numi personal-finance domain behavior for transactions, categories, funding sources, budgets, subscriptions, savings goals, cash-flow summaries, forecasts, anomalies, and Financial Twin insights. Use when calculating, validating, or changing money, category, period, recurrence, projection, or evidence semantics.
---

# Budget Domain

## Workflow

1. Identify the saved source records and the exact question being answered.
2. Define currency, calendar, time zone, period, and `asOf` date explicitly.
3. Reuse the domain model or overview that already owns the calculation.
4. Validate inputs before persistence and compute outputs deterministically in Swift.
5. Return finished values plus the evidence needed to explain them.
6. Leave localization and formatting to Presentation.

## Money and Transactions

- Store transaction `amount` as a positive `Decimal`; use `TransactionKind` for direction.
- Define cash flow as income minus expenses for a stated interval. Never label it account balance, wealth, or available savings.
- Treat the currently selected currency as the unit for current aggregates because transactions do not persist per-record currency.
- Do not convert or combine currencies without modeled currency and an explicit rate source.
- Preserve category name for display and use the normalized category key only for matching.
- Reuse saved income categories as expense funding-source choices; do not invent a separate account model without a real account feature.

## Budgets

- Require a nonempty category and positive monthly limit.
- Keep one saved budget per normalized expense category.
- Use a half-open calendar month `[start, end)` and include expenses only.
- Compute `spent`, `remaining`, `progress`, projected spend, daily allowance, pace, and unbudgeted spending from transactions.
- Allow `remaining` to become negative as evidence of overrun; clamp only display-oriented allowance values at zero.
- Label straight-line projection as a projection based on spending to the `asOf` day, not a guaranteed month-end result.

## Savings Goals

- Require a nonempty name, positive target, nonnegative saved amount, and explicit target date.
- Resolve complete before overdue when saved amount reaches target.
- Compute remaining amount and monthly contribution from target, saved amount, date, and inclusive remaining months.
- Compare required contribution with recorded completed-month surplus only as a feasibility signal.
- Treat missing history as `noHistory`, not as zero income or an impossible goal.

## Subscriptions and Forecasts

- Require positive amount and a valid next charge date.
- Preserve billing day across short months and normalize charge dates consistently.
- Stop generated charges after optional `endDate`.
- Define a forecast horizon and generate every applicable charge within it; never subtract one subscription amount and imply a full future forecast.
- Distinguish saved subscriptions from recurring-expense candidates inferred from transactions.

## Insights and Anomalies

- Build insights from deterministic thresholds, minimum sample sizes, and visible transaction samples.
- Report a pattern or candidate, not intent, blame, or certainty.
- Keep `FinancialSummary`, `BudgetOverview`, `SavingsGoalsOverview`, and `FinancialTwinReport` as reusable evidence sources.
- Put new calculations in a domain model or use case and leave the model to phrasing only.
- Include the method, observation period, sample count, and values behind every conclusion.

## Boundaries

- Persistence belongs to `$swiftdata`.
- AI recommendation policy belongs to `$financial-ai-coach`.
- Evidence phrasing belongs to `$ai-prompt-engineering`.
- UI composition and formatting belong to `$swiftui-architecture`.

## Check

- Test zero income, zero expenses, negative cash flow, month boundaries, leap dates, sparse history, category normalization, over-budget values, completed and overdue goals, and subscription end dates.
- Leave one deterministic self-check or Phase 4 unit test for every non-trivial formula.

## Reference

- [CFPB cash-flow budget tool](https://www.consumerfinance.gov/documents/10038/cfpb_creating-cash-flow-budget_tool_2021-08.pdf)
