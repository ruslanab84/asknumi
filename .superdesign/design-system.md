# Ask Numi Design System

## Product

Ask Numi is a private, on-device personal finance iPhone app. The primary journey is checking the current balance, recording transactions, reviewing deterministic financial insights, and planning payments/budgets. Designs should feel native to iOS, calm, trustworthy, and data-first.

## Target

- Platform: iPhone, portrait.
- Reference viewport: 390 × 844 points.
- Safe areas: preserve 59pt top and 34pt bottom.
- Language for this canvas: Russian.

## Typography

- Use only Apple system fonts: `-apple-system`, BlinkMacSystemFont, SF Pro Display, SF Pro Text.
- Balance amount: 40px, 800, rounded feel, `-0.6px` tracking.
- Screen title: 17px, 600.
- Section title: 17px, 600.
- Card title: 15px, 700.
- Body: 15–17px, 400–600.
- Caption: 11–12px, 500–600.

## Color

- Background: `#F6F7FB` to `#FFFFFF` diagonal gradient.
- Primary text: `#111827`.
- Secondary text: `rgba(60,60,67,0.60)`.
- Accent indigo: `#4F46E5`.
- Avatar highlight: `#7C7FF0`.
- AI purple: `#AF52DE`.
- Income green: `#34C759`; label green: `#248A3D`.
- Expense red: `#FF3B30`.
- Glass fill: `rgba(255,255,255,0.64)` with background blur.
- Glass border: `rgba(17,24,39,0.06)` or tinted equivalent.

## Spacing and geometry

- Screen horizontal padding: 20px.
- Main section gap: 24px.
- Internal card gaps: 12–16px.
- Metric card radius: 18px.
- Content and attention card radius: 22px.
- Generic glass card radius: 24px.
- Icon tile: 36–38px with 12px radius.
- Bottom tab capsule: 54px high, 6px horizontal inner padding; outer inset 20px.

## Effects

- iOS Liquid Glass: translucent light material, 18–24px blur, low-contrast 1px stroke.
- Card shadow: `0 8px 24px rgba(20,20,50,0.05)`.
- Avoid heavy gradients, dark outlines, skeuomorphism, and decorative illustrations.
- Use SF Symbols or faithful monochrome equivalents for every icon.

## Home dashboard composition

1. Header: centered `Ask Numi`; left user capsule with gradient avatar and `Руслан`; right circular bell glass button.
2. Overview: `Общий баланс` label with eye icon, large balance, two equal glass metric cards for `Доходы` and `Расходы`.
3. Section `Требует внимания`: three-page horizontal carousel. First visible card is budget; pagination dots sit in the section header.
4. Section `Последние операции`: glass list card with transaction rows and inset dividers.
5. Floating four-tab capsule above the bottom safe area: `Главная`, `Операции`, `Помощник`, `План`; `Главная` is active in indigo.

## Accessibility

- Minimum interactive target: 44 × 44px.
- Maintain readable contrast through translucent surfaces.
- Do not encode income/expense only by color; preserve arrow direction and labels.
- Layout must remain legible with enlarged text.
