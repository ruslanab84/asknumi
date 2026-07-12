# Ask Numi — Localization Rules

Ask Numi targets Russian-speaking users in Azerbaijan with plans to expand to additional languages and RTL locales. This document defines the canonical localization architecture every contributor must follow.

---

## Supported Languages (Roadmap)

| Code | Language | Script | Direction | Status |
|---|---|---|---|---|
| `ru` | Russian | Cyrillic | LTR | Primary |
| `az` | Azerbaijani | Latin | LTR | Planned |
| `en` | English | Latin | LTR | Planned |
| `ar` | Arabic | Arabic | RTL | Future |

---

## Core Architecture

```
┌──────────────────────────────────────────────────────┐
│                     Presentation                      │
│   View uses L10n.Key enum — never raw string literals │
├──────────────────────────────────────────────────────┤
│                  LocalizationManager                  │
│   Runtime language selection · Bundle resolution      │
├──────────────────────────────────────────────────────┤
│              Localization Resources                   │
│   .strings · .stringsdict · per-language Bundle       │
└──────────────────────────────────────────────────────┘
```

### The Non-Negotiable Rule

**No raw string literal may appear in any View, ViewModel, or UseCase.** Every user-visible string must pass through `L10n`.

---

## Folder Structure

```
Ask Numi/
├── Resources/
│   └── Localizations/
│       ├── ru.lproj/
│       │   ├── Localizable.strings
│       │   └── Localizable.stringsdict
│       ├── az.lproj/
│       │   ├── Localizable.strings
│       │   └── Localizable.stringsdict
│       └── en.lproj/
│           ├── Localizable.strings
│           └── Localizable.stringsdict
│
├── Infrastructure/
│   └── Localization/
│       ├── LocalizationManager.swift   # Runtime language switcher
│       ├── L10n.swift                  # Generated key enum + helpers
│       └── Bundle+Localization.swift   # Bundle extension for runtime override
```

---

## Key Naming Convention

Keys use **dot-notation** scoped from screen to element. All keys are lowercase with underscores within a segment.

```
<screen>.<component>.<element>[.<variant>]
```

### Examples

```
dashboard.header.title
dashboard.balance_card.label.total_balance
dashboard.balance_card.label.safe_to_spend
dashboard.insight_card.cta.show_details
transactions.list.section.recent
transactions.row.category.food
add_transaction.button.save
add_transaction.field.amount.placeholder
error.network.no_connection
error.generic.retry
common.button.cancel
common.button.done
common.label.loading
```

### Rules

- Keys are all lowercase.
- Segments are separated by `.` (dot).
- Words within a segment are separated by `_` (underscore).
- Keys are **never** reused across semantically different contexts even if the translation is identical today.
- A key's English value acts as documentation; the key itself must be self-describing.

---

## Localizable.strings Format

```strings
/* Dashboard — Header */
"dashboard.header.title" = "Главная";

/* Dashboard — Balance Card */
"dashboard.balance_card.label.total_balance" = "Общий баланс";
"dashboard.balance_card.label.safe_to_spend" = "Безопасно потратить";
"dashboard.balance_card.label.until_date" = "до %@ августа";

/* Dashboard — Insight Card */
"dashboard.insight_card.title" = "AI-инсайт";
"dashboard.insight_card.cta.show_details" = "Показать детали →";

/* Transactions */
"transactions.list.section.recent" = "Последние операции";
"transactions.list.cta.see_all" = "Все";
"transactions.category.food" = "Продукты";
"transactions.category.transport" = "Транспорт";
"transactions.category.income" = "Доход";

/* Tab Bar */
"tab.home" = "Главная";
"tab.transactions" = "Операции";
"tab.add" = "Добавить операцию";
"tab.assistant" = "Помощник";
"tab.plan" = "План";

/* Common */
"common.button.cancel" = "Отмена";
"common.button.done" = "Готово";
"common.button.retry" = "Повторить";
"common.label.loading" = "Загрузка…";

/* Errors */
"error.network.no_connection" = "Нет подключения к интернету";
"error.generic.message" = "Что-то пошло не так";
```

---

## Plural Rules — Localizable.stringsdict

Use `.stringsdict` for any string that contains a count. Never concatenate count into a translated string.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>

  <key>transactions.list.count</key>
  <dict>
    <key>NSStringLocalizedFormatKey</key>
    <string>%#@transactions@</string>
    <key>transactions</key>
    <dict>
      <key>NSStringFormatSpecTypeKey</key>
      <string>NSStringPluralRuleType</string>
      <key>NSStringFormatValueTypeKey</key>
      <string>d</string>
      <!-- Russian requires one/few/many/other -->
      <key>one</key>   <string>%d операция</string>
      <key>few</key>   <string>%d операции</string>
      <key>many</key>  <string>%d операций</string>
      <key>other</key> <string>%d операции</string>
    </dict>
  </dict>

</dict>
</plist>
```

Russian plural rules: **one** (1, 21, 31…), **few** (2–4, 22–24…), **many** (5–20, 25–30…), **other** (fractions).

---

## L10n — The Central Access Point

`L10n.swift` is the single public interface for all localized strings. It is the **only** place that calls `NSLocalizedString`.

```swift
// Infrastructure/Localization/L10n.swift

import Foundation

enum L10n {

    // MARK: - Dashboard

    enum Dashboard {
        enum Header {
            static var title: String { l("dashboard.header.title") }
        }
        enum BalanceCard {
            static var totalBalance: String   { l("dashboard.balance_card.label.total_balance") }
            static var safeToSpend: String    { l("dashboard.balance_card.label.safe_to_spend") }
            static func untilDate(_ date: String) -> String {
                String(format: l("dashboard.balance_card.label.until_date"), date)
            }
        }
        enum InsightCard {
            static var title: String      { l("dashboard.insight_card.title") }
            static var showDetails: String { l("dashboard.insight_card.cta.show_details") }
        }
    }

    // MARK: - Transactions

    enum Transactions {
        static var recentSection: String { l("transactions.list.section.recent") }
        static var seeAll: String        { l("transactions.list.cta.see_all") }
        static func count(_ n: Int) -> String {
            String(format: lp("transactions.list.count"), n)
        }
        enum Category {
            static var food: String      { l("transactions.category.food") }
            static var transport: String { l("transactions.category.transport") }
            static var income: String    { l("transactions.category.income") }
        }
    }

    // MARK: - Tab Bar

    enum Tab {
        static var home: String         { l("tab.home") }
        static var transactions: String { l("tab.transactions") }
        static var add: String          { l("tab.add") }
        static var assistant: String    { l("tab.assistant") }
        static var plan: String         { l("tab.plan") }
    }

    // MARK: - Common

    enum Common {
        static var cancel: String  { l("common.button.cancel") }
        static var done: String    { l("common.button.done") }
        static var retry: String   { l("common.button.retry") }
        static var loading: String { l("common.label.loading") }
    }

    // MARK: - Errors

    enum Error {
        static var noConnection: String { l("error.network.no_connection") }
        static var generic: String      { l("error.generic.message") }
    }

    // MARK: - Private helpers

    private static func l(_ key: String) -> String {
        LocalizationManager.shared.localizedString(for: key)
    }

    private static func lp(_ key: String) -> String {
        // stringsdict plural lookup — same bundle resolution
        LocalizationManager.shared.localizedString(for: key)
    }
}
```

**Usage in a View:**

```swift
Text(L10n.Dashboard.Header.title)
Text(L10n.Transactions.count(42))
```

---

## Runtime Language Switching

iOS respects the system language but Ask Numi allows in-app language selection. This requires loading a custom `Bundle`.

```swift
// Infrastructure/Localization/Bundle+Localization.swift

import Foundation

private var overrideBundle: Bundle?

extension Bundle {
    static var localized: Bundle {
        overrideBundle ?? .main
    }

    static func setLanguage(_ languageCode: String) {
        guard
            let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return }
        overrideBundle = bundle
    }
}
```

```swift
// Infrastructure/Localization/LocalizationManager.swift

import Foundation
import Combine

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private let storageKey = "app.selected.language"

    @Published private(set) var currentLanguage: String

    private init() {
        currentLanguage = UserDefaults.standard.string(forKey: "app.selected.language")
            ?? Locale.current.language.languageCode?.identifier
            ?? "ru"
        Bundle.setLanguage(currentLanguage)
    }

    func setLanguage(_ code: String) {
        guard currentLanguage != code else { return }
        UserDefaults.standard.set(code, forKey: storageKey)
        currentLanguage = code
        Bundle.setLanguage(code)
        // Publish change so any observing view rebuilds
        objectWillChange.send()
    }

    func localizedString(for key: String) -> String {
        Bundle.localized.localizedString(forKey: key, value: nil, table: "Localizable")
    }
}
```

Inject `LocalizationManager` into the SwiftUI environment at the root:

```swift
@main
struct Ask_NumiApp: App {
    @StateObject private var localization = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localization)
        }
    }
}
```

Any `View` that must respond to language changes:

```swift
struct HomeDashboardView: View {
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        // L10n.* calls always go through LocalizationManager.shared,
        // so they pick up the new bundle automatically.
        // Observing localization triggers a body rebuild.
        Text(L10n.Dashboard.Header.title)
    }
}
```

---

## SwiftUI Integration

### Always prefer `L10n` over raw `LocalizedStringKey`

```swift
// WRONG — bypasses LocalizationManager, ignores runtime switching
Text("dashboard.header.title")

// WRONG — hardcoded, will not be translated
Text("Главная")

// CORRECT
Text(L10n.Dashboard.Header.title)
```

### Interpolated strings

```swift
// WRONG
Text("Добрый вечер, \(name)!")

// CORRECT — key in .strings: "dashboard.greeting" = "Добрый вечер, %@!"
Text(L10n.Dashboard.greeting(name))
```

### Accessibility labels

```swift
Image(systemName: "plus")
    .accessibilityLabel(L10n.Tab.add)
```

---

## UIKit Integration

UIKit views do not auto-update when language changes. Force a full UI rebuild:

```swift
// In AppDelegate or SceneDelegate, after language change:
NotificationCenter.default.post(name: .languageDidChange, object: nil)

// In each UIViewController:
override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(applyLocalization),
        name: .languageDidChange,
        object: nil
    )
    applyLocalization()
}

@objc private func applyLocalization() {
    titleLabel.text = L10n.Dashboard.Header.title
}
```

---

## RTL Support

Prepare for Arabic and Hebrew now so the refactor cost is zero later.

### Layout

- Use `HStack` with `.environment(\.layoutDirection, .rightToLeft)` testing during development.
- Avoid fixed `leading`/`trailing` offsets; use `.leading` alignment which flips automatically.
- Use `.listRowInsets` and `EdgeInsets` rather than hardcoded left/right padding.
- Never use `offset(x:)` with hardcoded positive/negative values for layout; use `.padding(.leading, n)` instead.

### Icons

- Use system images that flip automatically (SF Symbols marked as "direction-aware").
- For custom icons that must mirror, apply `.flipsForRightToLeftLayoutDirection(true)`.

### Text alignment

```swift
// WRONG — hardcoded
Text(L10n.Dashboard.Header.title)
    .multilineTextAlignment(.left)

// CORRECT — adapts to locale
Text(L10n.Dashboard.Header.title)
    .multilineTextAlignment(.leading)
```

### Numbers and currency

Never format currency manually. Use `Locale`-aware formatters:

```swift
// Infrastructure/Localization/CurrencyFormatter.swift

import Foundation

enum CurrencyFormatter {
    static func format(_ amount: Decimal, currency: String = "AZN") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage)
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(currency)"
    }
}
```

### Date formatting

```swift
// Infrastructure/Localization/DateFormatter+Localized.swift

import Foundation

extension DateFormatter {
    static func localized(dateStyle: DateFormatter.Style = .none,
                          timeStyle: DateFormatter.Style = .short) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage)
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter
    }
}
```

---

## AI Localization Pipeline

Use AI to generate and verify translations. Treat AI output as a **first draft** that must be reviewed by a native speaker before merging.

### Workflow

1. **Export** — extract all keys from `Localizable.strings` into a structured JSON:
   ```json
   { "dashboard.header.title": "Главная", ... }
   ```
2. **Translate** — send to Claude with this system prompt:
   ```
   You are a professional translator for a personal finance app targeting {locale} speakers.
   Translate each value. Preserve %@ and %d format specifiers exactly.
   Return a JSON object with the same keys and translated values.
   Tone: friendly, concise, professional.
   ```
3. **Review** — native speaker reviews diff between existing and new translations.
4. **Import** — run a script that converts JSON back to `.strings` format and opens a PR.
5. **Validate** — CI script checks that every key in the base (`ru`) `.strings` exists in all other `.strings` files.

### AI Translation Script Location

```
Scripts/
├── export_strings.py     # Extracts keys from .strings → JSON
├── translate.py          # Calls AI API with the prompt above
└── import_strings.py     # Converts translated JSON → .strings
```

---

## Missing Translation Safety Net

`LocalizationManager.localizedString(for:)` must never silently return the key. Log a warning in DEBUG builds:

```swift
func localizedString(for key: String) -> String {
    let value = Bundle.localized.localizedString(forKey: key, value: "__MISSING__", table: "Localizable")
    if value == "__MISSING__" {
        #if DEBUG
        assertionFailure("⚠️ Missing localization key: \(key) for language: \(currentLanguage)")
        #endif
        // Fallback to Russian (primary language)
        return Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
    }
    return value
}
```

---

## CI Validation

Add a build phase script or CI step that fails if:

1. Any `.strings` file contains a key not present in `ru.lproj/Localizable.strings` (orphan key).
2. Any key in `ru.lproj/Localizable.strings` is missing from any other `.lproj` (untranslated key).
3. Any View file contains a string literal that matches a common UI word pattern (heuristic guard against hardcoding).

```bash
# Scripts/validate_strings.sh
# Exits non-zero if any language .strings is missing keys from the base (ru) file
BASE="Resources/Localizations/ru.lproj/Localizable.strings"
for lproj in Resources/Localizations/*.lproj; do
    lang=$(basename "$lproj" .lproj)
    [ "$lang" = "ru" ] && continue
    file="$lproj/Localizable.strings"
    while IFS= read -r key; do
        grep -q "\"$key\"" "$file" || echo "MISSING [$lang]: $key"
    done < <(grep -o '"[^"]*" =' "$BASE" | tr -d '" =')
done
```

---

## Rules Summary

1. **No hardcoded UI strings** in Views, ViewModels, or Use Cases. Ever.
2. **All strings go through `L10n`** — one enum, one lookup path.
3. **`LocalizationManager` owns the bundle** — never call `NSLocalizedString` directly outside it.
4. **Keys are dot-scoped** and self-describing; never reuse keys across different UI contexts.
5. **Plurals live in `.stringsdict`** — never concatenate a count into a translated string.
6. **Currency and dates use locale-aware formatters** — never format manually with string interpolation.
7. **Use `.leading` / `.trailing` layout semantics** — never hardcode left/right for RTL readiness.
8. **AI translations are first drafts** — a native speaker must review before merging.
9. **Missing keys crash in DEBUG** — `assertionFailure` on any lookup that returns the fallback sentinel.
10. **CI blocks merges with missing keys** — every language file must be complete before a PR lands.
