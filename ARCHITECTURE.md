# Ask Numi — Architecture

Ask Numi is a personal finance iOS application with AI-powered insights. This document defines the architectural principles, layer responsibilities, folder structure, and conventions that every contributor must follow.

---

## Guiding Principles

- **Clean Architecture** — dependencies always point inward; outer layers know about inner ones, never vice-versa.
- **MVVM** — `View` observes `ViewModel`; `ViewModel` orchestrates use-cases; neither touches the network or database directly.
- **SOLID** — single responsibility per type, open for extension, program to protocols.
- **Composition over inheritance** — prefer small focused types composed together.
- **async/await everywhere** — no Combine, no callbacks; structured concurrency via Swift's async/await.
- **Dependency injection** — every dependency is injected; no singletons accessed directly inside business logic.
- **Repository pattern** — data sources are hidden behind repository protocols; callers never know whether data comes from the network, cache, or mock.

---

## Layer Map

```
┌──────────────────────────────────────────────────────────────┐
│                      Presentation Layer                       │
│   Views  ·  ViewModels  ·  UI Models  ·  Coordinators        │
├──────────────────────────────────────────────────────────────┤
│                        Domain Layer                           │
│        Use Cases  ·  Domain Models  ·  Repository Protocols  │
├──────────────────────────────────────────────────────────────┤
│                         Data Layer                            │
│  Repository Implementations  ·  Remote  ·  Local  ·  DTOs   │
├──────────────────────────────────────────────────────────────┤
│                     Infrastructure Layer                      │
│       NetworkClient  ·  PersistenceClient  ·  Keychain        │
└──────────────────────────────────────────────────────────────┘
```

Dependencies flow **downward only**. A `View` may import `Domain` types but must never import `Data` or `Infrastructure` types directly.

---

## Folder Structure

```
Ask Numi/
├── App/
│   ├── Ask_NumiApp.swift           # @main entry point, DI container bootstrap
│   └── AppContainer.swift          # Composition root — wires all dependencies
│
├── Presentation/
│   ├── Dashboard/
│   │   ├── HomeDashboardView.swift
│   │   ├── HomeDashboardViewModel.swift
│   │   └── Components/             # Private sub-views for this screen
│   ├── Transactions/
│   │   ├── TransactionListView.swift
│   │   ├── TransactionListViewModel.swift
│   │   └── AddTransactionView.swift
│   ├── Assistant/
│   │   ├── AssistantView.swift
│   │   └── AssistantViewModel.swift
│   ├── Plan/
│   │   ├── BudgetPlanView.swift
│   │   └── BudgetPlanViewModel.swift
│   └── Shared/
│       ├── Components/             # Reusable UI components (GlassCard, TabBar…)
│       └── Theme/                  # Colors, typography, spacing constants
│
├── Domain/
│   ├── Models/
│   │   ├── Transaction.swift       # Pure value types, no UI imports
│   │   ├── Budget.swift
│   │   ├── Account.swift
│   │   └── AIInsight.swift
│   ├── Repositories/
│   │   ├── TransactionRepository.swift   # protocol
│   │   ├── BudgetRepository.swift        # protocol
│   │   └── InsightRepository.swift       # protocol
│   └── UseCases/
│       ├── FetchDashboardUseCase.swift
│       ├── AddTransactionUseCase.swift
│       ├── FetchInsightUseCase.swift
│       └── GetBudgetProgressUseCase.swift
│
├── Data/
│   ├── Repositories/
│   │   ├── DefaultTransactionRepository.swift
│   │   ├── DefaultBudgetRepository.swift
│   │   └── DefaultInsightRepository.swift
│   ├── Remote/
│   │   ├── DTOs/
│   │   │   ├── TransactionDTO.swift
│   │   │   └── InsightDTO.swift
│   │   └── Endpoints/
│   │       ├── TransactionEndpoint.swift
│   │       └── InsightEndpoint.swift
│   └── Local/
│       ├── TransactionStore.swift   # SwiftData / SQLite wrapper
│       └── CachePolicy.swift
│
└── Infrastructure/
    ├── Network/
    │   ├── NetworkClient.swift      # URLSession wrapper
    │   ├── APIError.swift
    │   └── RequestBuilder.swift
    ├── Persistence/
    │   └── PersistenceController.swift
    └── Keychain/
        └── KeychainService.swift
```

---

## Layer Responsibilities

### Presentation

- **View** — pure SwiftUI, zero business logic. Observes `ViewModel` via `@StateObject` / `@ObservedObject`. Sends user intents to the `ViewModel` (button taps, pull-to-refresh).
- **ViewModel** — `@MainActor final class`, conforms to `ObservableObject`. Holds `@Published` UI state. Calls use-cases. Maps domain models → UI models. Owns loading/error state.
- **UI Model** — a display-only struct (`DashboardSnapshot`, `TransactionRow`) that contains pre-formatted strings. Views never format data themselves.
- **Components** — reusable SwiftUI views (`GlassCard`, `DashboardTabBar`) live in `Presentation/Shared/Components/`.

### Domain

- No UIKit/SwiftUI imports.
- **Domain Model** — plain Swift structs/enums representing business concepts (`Transaction`, `Budget`, `AIInsight`).
- **Repository Protocol** — `protocol TransactionRepository { func fetchAll() async throws -> [Transaction] }`. The domain owns this protocol; implementations live in Data.
- **Use Case** — a single-responsibility struct/class that orchestrates one business operation. Injected with repository protocols.

### Data

- **Repository Implementation** — conforms to the domain protocol; decides when to fetch from network vs. local cache.
- **DTO** — `Decodable` structs for network responses. Mapped to domain models inside the repository, never leaking to upper layers.
- **Endpoints** — typed enums or structs defining URL, method, headers, and body for each API call.

### Infrastructure

- **NetworkClient** — thin `URLSession` wrapper. Takes a `RequestBuilder`, returns `Data`. Knows nothing about the domain.
- **PersistenceController** — SwiftData / Core Data stack setup.

---

## MVVM Contract

```swift
// Domain
protocol TransactionRepository {
    func fetchRecent(limit: Int) async throws -> [Transaction]
}

// Domain — Use Case
struct FetchDashboardUseCase {
    private let transactions: TransactionRepository
    private let insights: InsightRepository

    func execute() async throws -> DashboardData {
        async let txn = transactions.fetchRecent(limit: 3)
        async let insight = insights.fetchLatest()
        return DashboardData(transactions: try await txn, insight: try await insight)
    }
}

// Presentation — ViewModel
@MainActor
final class HomeDashboardViewModel: ObservableObject {
    @Published private(set) var snapshot: DashboardSnapshot = .empty
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let useCase: FetchDashboardUseCase

    init(useCase: FetchDashboardUseCase) {
        self.useCase = useCase
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await useCase.execute()
            snapshot = DashboardSnapshot(data)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// Presentation — View
struct HomeDashboardView: View {
    @StateObject private var viewModel: HomeDashboardViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                DashboardContent(snapshot: viewModel.snapshot)
            }
        }
        .task { await viewModel.load() }
    }
}
```

---

## Dependency Injection

All dependencies are composed in `AppContainer` at app launch. No type calls `URLSession.shared` or accesses a singleton inside business logic.

```swift
// App/AppContainer.swift
final class AppContainer {
    let networkClient: NetworkClient
    let transactionRepository: TransactionRepository
    let insightRepository: InsightRepository

    init() {
        networkClient = NetworkClient(session: .shared)
        transactionRepository = DefaultTransactionRepository(network: networkClient)
        insightRepository = DefaultInsightRepository(network: networkClient)
    }

    func makeDashboardViewModel() -> HomeDashboardViewModel {
        let useCase = FetchDashboardUseCase(
            transactions: transactionRepository,
            insights: insightRepository
        )
        return HomeDashboardViewModel(useCase: useCase)
    }
}
```

The root `ContentView` (or a `Coordinator`) receives `AppContainer` from the `@main` App struct and passes factory-created `ViewModel` instances down the tree.

---

## Async / Await Conventions

- All async work runs in `Task { }` blocks triggered from `.task { }` or user actions; never `DispatchQueue.main.async`.
- `@MainActor` on every `ViewModel` guarantees UI updates on the main thread without manual dispatch.
- Concurrent independent fetches use `async let`:
  ```swift
  async let a = repoA.fetch()
  async let b = repoB.fetch()
  return (try await a, try await b)
  ```
- Cancellation is handled automatically; long-running tasks check `Task.isCancelled` where appropriate.

---

## Error Handling

- `NetworkClient` maps HTTP errors to `APIError` (typed enum).
- Repositories catch `APIError` and either rethrow or map to domain-level errors.
- `ViewModel` catches all errors and sets `@Published var error: String?`; the View shows an alert or inline error state.
- Force-try (`try!`) and force-unwrap (`!`) are forbidden in production code.

---

## UI Model vs Domain Model

| Concern | Domain Model | UI Model |
|---|---|---|
| Lives in | `Domain/Models/` | `Presentation/.../` |
| Contains | Business data, logic | Pre-formatted strings for display |
| SwiftUI import | Never | Yes |
| Who maps | Repository → Domain | ViewModel → UI Model |

Example:

```swift
// Domain
struct Transaction {
    let amount: Decimal          // raw value
    let currency: Currency
    let date: Date
}

// UI Model (Presentation)
struct TransactionRow {
    let formattedAmount: String  // "−48 AZN"
    let formattedDate: String    // "19:42"
    let isIncome: Bool
}
```

---

## Testing Strategy

| Layer | What to test | How |
|---|---|---|
| Domain / Use Cases | Business logic, mapping | Unit tests with mock repositories |
| Repositories | Network + cache logic | Integration tests with `URLProtocol` stub |
| ViewModels | State transitions | Unit tests with mock use-cases |
| Views | Visual regressions | SwiftUI Previews + Snapshot tests |
| End-to-end | Full happy paths | UI tests with `XCUIApplication` |

- Mock dependencies by injecting protocol-conforming test doubles.
- No `@testable import` tricks to reach private state — design for testability from the start.

---

## Rules Summary

1. Views own zero business logic and zero networking code.
2. ViewModels own zero SwiftUI-specific types (no `Color`, no `Image`).
3. Domain layer has no UIKit/SwiftUI/Foundation-URL imports.
4. Every dependency is injected; no global state accessed inside business logic.
5. All async work uses `async/await`; no Combine, no callbacks.
6. DTOs never leave the Data layer.
7. Force-unwrap and `try!` are forbidden outside tests and previews.
8. One use-case per file, one responsibility per use-case.
9. UI models contain pre-formatted strings; views never call `.formatted()` on raw domain values.
10. Add a feature by adding files in the right layer — not by growing existing ones.
