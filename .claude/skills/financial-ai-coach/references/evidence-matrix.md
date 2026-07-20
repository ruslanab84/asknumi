# Financial AI Coach Evidence Matrix

Use the narrowest row that answers the request. If required evidence is missing, name it instead of substituting historical cash flow or model knowledge.

| Request | Required evidence | Allowed conclusion | Forbidden shortcut |
| --- | --- | --- | --- |
| Where did my money go? | Transactions, interval, currency, category totals | Recorded expense distribution and largest categories | Inferring necessity, waste, or a cut amount |
| How much did I spend? | Transactions, interval, currency | Exact recorded expense total | Treating incomplete records as complete finances |
| Am I within budget? | Current-month expenses, saved category budgets, `asOf` date | Spent, remaining, pace, and deterministic projection | Calling projection a guaranteed month-end total |
| How much can I spend daily? | Remaining monthly budget and days remaining | Nonnegative daily allowance under the saved budget | Calling allowance available cash or account balance |
| Can I reach this savings goal? | Target, saved amount, deadline, recorded completed-month surplus | Required contribution and evidence-based feasibility signal | Guaranteeing success or assuming future income |
| Can I afford a purchase? | Price, date, user-confirmed available balance, expected income, obligations, known planned charges | Conditional gap or surplus using stated assumptions | Using historical cash flow or unrelated goal progress as current balance |
| What changed this month? | Comparable periods and category totals | Supplied amount and percentage changes | Explaining why behavior changed without evidence |
| Is this expense unusual? | Defined baseline, minimum sample, current value, method | Candidate anomaly with comparison evidence | Calling it fraud, error, or intent |
| What repeats unexpectedly? | Repeated transaction samples and saved subscriptions | Recurring-expense candidate | Claiming a subscription exists without a saved schedule |
| What should I review first? | Ranked deterministic budget, trend, goal, or recurring evidence | A few evidence-linked review suggestions | Inventing savings amounts or universal benchmarks |
| What will my balance be? | Starting account balance, dated income, expenses, and scheduled charges through horizon | Scenario forecast with explicit assumptions | Renaming net transaction cash flow as balance |
| Which investment or credit product should I choose? | Product and regulatory data not modeled by Ask Numi | Explain that personalized selection is unsupported | Recommending a security, lender, tax action, or guaranteed return |
