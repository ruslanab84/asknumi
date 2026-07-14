//
//  GetFinancialAdviceUseCase.swift
//  Ask Numi
//
//  The full AI pipeline: fetch transactions → aggregate deterministically
//  in Swift → hand the compact summary to the advisor for phrasing.
//

import Foundation

/// The deterministic numbers and the model's phrasing, together, so the UI
/// can chart the summary next to the advice without a second fetch.
struct FinancialAdviceReport: Sendable {
    let summary: FinancialSummary
    let advice: FinancialAdvice
    let showsSpendingChart: Bool
}

enum FinancialAdviceTask: Equatable, Sendable {
    case categoryTotal(String)
    case spendingTotal
    case spendingOverview
    case savingsPlan
    case general

    var showsSpendingChart: Bool { self == .spendingOverview }
}

struct GetFinancialAdviceUseCase: Sendable {
    private let transactions: TransactionRepository
    private let advisor: FinancialAdvisor

    init(transactions: TransactionRepository, advisor: FinancialAdvisor) {
        self.transactions = transactions
        self.advisor = advisor
    }

    var advisorAvailability: AdvisorAvailability { advisor.availability }

    func execute(question: String? = nil) async throws -> FinancialAdviceReport {
        if let question, !Self.isFinancialQuestion(question) {
            throw DomainError.invalidQuestion
        }

        let allItems = try await transactions.fetchAll()
        let inferredTask = question.map(Self.adviceTask) ?? .general
        let period = question.flatMap { question in
            inferredTask == .savingsPlan
                ? Self.requestedSavingsAnalysisPeriod(from: question)
                : Self.requestedPeriod(from: question)
        }
        let periodItems = period.map { selected in
            allItems.filter { $0.date >= selected.start && $0.date < selected.end }
        } ?? allItems
        let items: [Transaction]
        let task: FinancialAdviceTask
        if inferredTask == .savingsPlan {
            items = periodItems
            task = .savingsPlan
        } else if let question {
            switch Self.requestedCategory(
                in: question,
                candidates: allItems.filter { $0.kind == .expense }.map(\.category)
            ) {
            case .matched(let category):
                items = periodItems.filter { transaction in
                    transaction.kind == .expense && category.categories.contains {
                        Self.sameCategory($0, transaction.category)
                    }
                }
                guard !items.isEmpty else { throw DomainError.categoryNotFound }
                task = .categoryTotal(category.name)
            case .missing:
                throw DomainError.categoryNotFound
            case .none:
                items = periodItems
                task = inferredTask == .general
                    && Self.isCategoryAmountQuestion(Self.tokens(in: question))
                    ? .spendingTotal
                    : inferredTask
            }
        } else {
            items = periodItems
            task = .general
        }
        guard !items.isEmpty else { throw DomainError.notEnoughData }
        let summary = FinancialSummary(
            transactions: items,
            period: period ?? Self.dataPeriod(for: items)
        )
        let advice = try await advisor.advise(on: summary, question: question, task: task)
        return FinancialAdviceReport(
            summary: summary,
            advice: advice,
            showsSpendingChart: task.showsSpendingChart
        )
    }

    private static func requestedPeriod(from question: String) -> DateInterval? {
        let text = question.lowercased()
        let calendar = Calendar.current

        if text.contains("this month") || text.contains("этом месяце") || text.contains("tekushhem mesyace") {
            return calendar.dateInterval(of: .month, for: .now)
        }

        let tokens = Set(text.components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty })
        let month = Self.monthAliases.first { _, aliases in !tokens.isDisjoint(with: aliases) }?.key
        let year = text.range(of: #"\b(?:19|20)\d{2}\b"#, options: .regularExpression).flatMap {
            Int(text[$0])
        }

        guard month != nil || year != nil else { return nil }
        let components = DateComponents(year: year ?? calendar.component(.year, from: .now), month: month ?? 1, day: 1)
        guard let start = calendar.date(from: components),
              let end = calendar.date(byAdding: month == nil ? .year : .month, value: 1, to: start) else { return nil }
        return DateInterval(start: start, end: end)
    }

    private static func requestedSavingsAnalysisPeriod(from question: String) -> DateInterval? {
        let text = question.lowercased()
        let targetMarkers = [
            " to save", " save ", " how can i save", " сэконом", " накоп", " sekonom", " nakop"
        ]
        let end = targetMarkers.compactMap { text.range(of: $0)?.lowerBound }.min() ?? text.endIndex
        let analysisText = String(text[..<end])
        let cues = [
            "using", "based on", "according to", "only my", "spending in", "expenses in",
            "на основе", "исходя", "расходы за", "rashody za", "na osnove"
        ]
        guard cues.contains(where: analysisText.contains) else { return nil }
        return requestedPeriod(from: analysisText)
    }

    private static func requestedCategory(in question: String, candidates: [String]) -> CategoryRequest {
        let tokens = Self.tokens(in: question)
        guard Self.isCategoryAmountQuestion(tokens) else { return .none }

        if let category = matchedCategory(in: tokens, candidates: candidates) {
            return .matched(category)
        }

        return hasUnknownCategory(in: tokens) ? .missing : .none
    }

    private static func matchedCategory(in questionTokens: [String], candidates: [String]) -> CategoryMatch? {
        let questionTokens = questionTokens.map(canonicalCategoryToken)
        let candidates = Set(candidates).sorted {
            let lhsCount = categoryTokens(in: $0).count
            let rhsCount = categoryTokens(in: $1).count
            if lhsCount != rhsCount { return lhsCount > rhsCount }
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.localizedStandardCompare($1) == .orderedAscending
        }

        let directMatches = candidates.filter { category in
            let categoryTokens = categoryTokens(in: category)
            return !categoryTokens.isEmpty && categoryTokens.allSatisfy { categoryToken in
                questionTokens.contains(categoryToken)
            }
        }
        let maximalDirectMatches = directMatches.filter { candidate in
            let candidateTokens = Set(categoryTokens(in: candidate))
            return !directMatches.contains { other in
                let otherTokens = Set(categoryTokens(in: other))
                return otherTokens.count > candidateTokens.count
                    && candidateTokens.isSubset(of: otherTokens)
            }
        }
        if !maximalDirectMatches.isEmpty {
            return combinedCategoryMatch(maximalDirectMatches.map {
                categoryMatch(for: $0, candidates: candidates)
            })
        }

        let aliasMatches = categoryAliases.compactMap { aliases -> CategoryMatch? in
            let aliases = Set(aliases.flatMap(categoryTokens))
            guard !aliases.isDisjoint(with: questionTokens) else { return nil }

            if let aliasMatch = candidates.first(where: { category in
                let tokens = categoryTokens(in: category)
                return tokens.count == 1 && aliases.contains(tokens[0])
            }) {
                return categoryMatch(for: aliasMatch, candidates: candidates, aliases: aliases)
            }
            return nil
        }
        if !aliasMatches.isEmpty { return combinedCategoryMatch(aliasMatches) }

        return nil
    }

    private static func combinedCategoryMatch(_ matches: [CategoryMatch]) -> CategoryMatch {
        var names: [String] = []
        var categories: [String] = []
        for match in matches {
            if !names.contains(where: { sameCategory($0, match.name) }) {
                names.append(match.name)
            }
            for category in match.categories where !categories.contains(where: {
                sameCategory($0, category)
            }) {
                categories.append(category)
            }
        }
        return CategoryMatch(name: names.joined(separator: " + "), categories: categories)
    }

    private static func categoryMatch(
        for name: String,
        candidates: [String],
        aliases: Set<String>? = nil
    ) -> CategoryMatch {
        let nameTokens = categoryTokens(in: name)
        guard nameTokens.count == 1 else {
            return CategoryMatch(
                name: name,
                categories: candidates.filter { sameCategory($0, name) }
            )
        }

        let aliases = aliases ?? categoryAliases
            .map { Set($0.flatMap(categoryTokens)) }
            .first { $0.contains(nameTokens[0]) }
        let categories = aliases.map { aliases in
            candidates.filter { candidate in
                let tokens = categoryTokens(in: candidate)
                return tokens.count == 1 && aliases.contains(tokens[0])
            }
        } ?? [name]
        return CategoryMatch(name: name, categories: categories)
    }

    private static func hasUnknownCategory(in tokens: [String]) -> Bool {
        guard let marker = tokens.lastIndex(where: { token in
            categoryMarkers.contains(token) || token.hasPrefix("kategori")
        }) else { return false }

        return tokens[tokens.index(after: marker)...].contains { token in
            token.count > 2
                && !questionFillerWords.contains(token)
                && !normalizedMonthTokens.contains(token)
                && !categorySpendingRoots.contains(where: { token.hasPrefix($0) })
                && !nonCategoryRoots.contains(where: { token.hasPrefix($0) })
        }
    }

    private static func isCategoryAmountQuestion(_ tokens: [String]) -> Bool {
        let terms = Set(tokens)
        let asksForAmount = terms.contains("skolko")
            || terms.contains("amount")
            || terms.contains("total")
            || terms.contains("sum")
            || terms.contains("itogo")
            || terms.contains("vsego")
            || (terms.contains("how") && terms.contains("much"))
            || (terms.contains("what") && terms.contains("did"))
        let asksAboutSpending = tokens.contains { token in
            categorySpendingRoots.contains { token.hasPrefix($0) }
        }
        return asksForAmount && asksAboutSpending
    }

    private static func adviceTask(for question: String) -> FinancialAdviceTask {
        let tokens = tokens(in: question)
        if isDefinitionQuestion(tokens) {
            return .general
        }
        if tokens.contains(where: { token in
            explicitSavingsRoots.contains { token.hasPrefix($0) }
        }) {
            return .savingsPlan
        }
        let hasSpendingContext = tokens.contains { token in
            spendingContextRoots.contains { token.hasPrefix($0) }
        }
        let asksForOverview = tokens.contains { token in
            spendingOverviewRoots.contains { token.hasPrefix($0) }
        }
        if hasSpendingContext && asksForOverview {
            return .spendingOverview
        }
        if tokens.contains(where: { token in savingsTaskRoots.contains { token.hasPrefix($0) } }) {
            return .savingsPlan
        }
        return .general
    }

    private static func isFinancialQuestion(_ question: String) -> Bool {
        let tokens = tokens(in: question)
        guard question.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else { return false }

        let hasFinancialTopic = tokens.contains { token in
            financialTopicRoots.contains { token.hasPrefix($0) }
        }
        return hasFinancialTopic || isFinancialSaveQuestion(question, tokens: tokens)
    }

    private static func isFinancialSaveQuestion(_ question: String, tokens: [String]) -> Bool {
        guard tokens.contains(where: { token in
            token == "save" || token.hasPrefix("saving")
        }) else { return false }
        guard !tokens.contains(where: { token in
            nonFinancialSaveObjectRoots.contains { token.hasPrefix($0) }
        }) else { return false }

        let terms = Set(tokens)
        let hasAmountQuestion = terms.contains("skolko")
            || (terms.contains("how") && terms.contains("much"))
        let hasCurrency = tokens.contains { Locale.commonISOCurrencyCodes.contains($0.uppercased()) }
        let hasFinancialContext = !terms.isDisjoint(with: savingsContextWords)
        let hasNumber = question.range(of: #"\d"#, options: .regularExpression) != nil
        return hasAmountQuestion || hasCurrency || hasFinancialContext || hasNumber
    }

    private static func isDefinitionQuestion(_ tokens: [String]) -> Bool {
        let terms = Set(tokens)
        return terms.contains("mean")
            || terms.contains("explain")
            || terms.contains("oznacaet")
            || terms.contains("obyasni")
    }

    private static let financialTopicRoots: Set<String> = [
        "spend", "spent", "expense", "income", "earn", "balance", "budget", "money",
        "salary", "rent", "debt", "loan", "credit", "transaction", "cost", "afford", "financ", "subscript",
        "potrat", "rashod", "rasxod", "dohod", "doxod", "zarabot", "balans", "budzet", "byudjet",
        "dengi", "deneg", "sekonom",
        "zarplat", "arend", "dolg", "kredit", "operac", "stoim", "finans", "podpisk"
    ]

    private static let categorySpendingRoots: Set<String> = [
        "spend", "spent", "expense", "cost", "potrat", "trata", "rashod", "rasxod", "stoim"
    ]

    private static let spendingContextRoots: Set<String> = [
        "spend", "expense", "money", "cost", "potrat", "trata", "rashod", "rasxod", "dengi", "deneg"
    ]

    private static let savingsTaskRoots: Set<String> = [
        "save", "saving", "budget", "afford", "plan", "debt", "loan", "credit",
        "sekonom", "sbereg", "budzet", "byudjet", "dolg", "kredit"
    ]

    private static let explicitSavingsRoots: Set<String> = [
        "save", "saving", "afford", "sekonom", "sbereg", "nakop"
    ]

    private static let savingsContextWords: Set<String> = [
        "account", "budget", "emergency", "expense", "finance", "fund", "goal", "holiday", "home",
        "income", "interest", "month", "money", "on", "pension", "plan", "rate", "retirement", "salary",
        "travel", "vacation", "wedding", "year"
    ]

    private static let nonFinancialSaveObjectRoots: Set<String> = [
        "bookmark", "cloud", "code", "contact", "disk", "document", "download", "file", "game",
        "image", "password", "photo", "progress", "project", "screen", "storage", "video"
    ]

    private static let spendingOverviewRoots: Set<String> = [
        "where", "breakdown", "categor", "chart", "graph", "distribution", "pattern", "largest", "biggest",
        "kuda", "kategori", "raspredel"
    ]

    private static let questionFillerWords: Set<String> = [
        "a", "all", "an", "at", "by", "category", "did", "do", "does", "during", "for", "from",
        "have", "how", "i", "in", "itogo", "last", "much", "my", "na", "of", "on", "our", "po",
        "selected", "skolko", "sum", "the", "this", "to", "total", "v", "vsego", "we", "ya", "za"
    ]

    private static let categoryMarkers: Set<String> = ["at", "on", "na", "category"]

    private static let nonCategoryRoots: Set<String> = [
        "average", "compare", "change", "day", "decrease", "increase", "month", "overall",
        "period", "today", "tomorrow", "week", "year", "yesterday", "pribliz", "sredn", "segod",
        "vcer", "zavtr", "nedel", "mesac", "mesyac", "god"
    ]

    nonisolated private static func tokens(in value: String) -> [String] {
        let latin = (value.applyingTransform(.toLatin, reverse: false) ?? value)
            .replacingOccurrences(of: "ʹ", with: "")
        return latin
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }

    nonisolated private static func categoryTokens(in value: String) -> [String] {
        tokens(in: value).map(canonicalCategoryToken)
    }

    nonisolated private static func canonicalCategoryToken(_ token: String) -> String {
        var token = token
        if token.hasSuffix("ies") {
            token = String(token.dropLast(3)) + "y"
        } else if token.hasSuffix("s"), token.count > 3 {
            token = String(token.dropLast())
        }
        if token.hasSuffix("y"), token.count > 3 {
            token = String(token.dropLast()) + "i"
        }
        return token
    }

    private static func sameCategory(_ lhs: String, _ rhs: String) -> Bool {
        categoryTokens(in: lhs) == categoryTokens(in: rhs)
    }

    private static func dataPeriod(for transactions: [Transaction]) -> DateInterval {
        let dates = transactions.map(\.date)
        let end = (dates.max() ?? .now).addingTimeInterval(1)
        return DateInterval(start: dates.min() ?? end, end: end)
    }

    private static let categoryAliases: [[String]] = [
        ["grocery", "product", "produkty", "produkt"],
        ["food", "eda", "edu", "edy"],
        ["transport"],
        ["car", "avto"],
        ["home", "dom"],
        ["health", "zdorove"],
        ["entertainment", "razvlecenie", "razvlecenia"],
        ["clothes", "odezda", "odezdu"],
        ["salary", "zarplata"],
        ["freelance", "frilans"],
        ["gift", "podarok"],
        ["interest", "procent"],
        ["rent", "arenda", "arendu"]
    ]

    private static let monthAliases: [Int: Set<String>] = [
        1: ["january", "jan", "январь", "января", "yanvar", "yanvarya"],
        2: ["february", "feb", "февраль", "февраля", "fevral", "fevralya"],
        3: ["march", "mar", "март", "марта", "mart", "marta"],
        4: ["april", "apr", "апрель", "апреля", "aprel", "aprelya"],
        5: ["may", "май", "мая", "mai", "maya"],
        6: ["june", "jun", "июнь", "июня", "iyun", "iyunya"],
        7: ["july", "jul", "июль", "июля", "iyul", "iyulya"],
        8: ["august", "aug", "август", "августа", "avgust", "avgusta"],
        9: ["september", "sep", "сентябрь", "сентября", "sentyabr", "sentyabrya"],
        10: ["october", "oct", "октябрь", "октября", "oktyabr", "oktyabrya"],
        11: ["november", "nov", "ноябрь", "ноября", "noyabr", "noyabrya"],
        12: ["december", "dec", "декабрь", "декабря", "dekabr", "dekabrya"],
    ]

    private static let normalizedMonthTokens = Set(monthAliases.values.flatMap { aliases in
        aliases.flatMap(tokens)
    })

    #if DEBUG
    static func assertSelfCheck() {
        assert(isFinancialQuestion("What should I do to save 1000 USD?"))
        assert(isFinancialQuestion("How should I plan my finances?"))
        assert(!isFinancialQuestion("How much does an elephant weigh?"))
        assert(!isFinancialQuestion("Skolko vesit slon?"))
        assert(requestedCategory(
            in: "What should I do to save 1000 USD?",
            candidates: ["Groceries"]
        ) == .none)
        assert(requestedCategory(
            in: "How much did I spend on groceries?",
            candidates: ["Groceries"]
        ).match?.name == "Groceries")
        assert(requestedCategory(
            in: "Skolko ya potratil na produkty?",
            candidates: ["Продукты"]
        ).match?.name == "Продукты")
        assert(requestedCategory(
            in: "Skolko ya potratil na sigareti?",
            candidates: ["Сигареты"]
        ).match?.name == "Сигареты")
        assert(requestedCategory(
            in: "Skolko ya potratil na sigareti?",
            candidates: ["Продукты"]
        ) == .missing)
        assert(requestedCategory(
            in: "Сколько я потратил на сигареты?",
            candidates: ["Продукты"]
        ) == .missing)
        assert(requestedCategory(
            in: "How much did I spend for July?",
            candidates: ["Groceries"]
        ) == .none)
        assert(requestedCategory(
            in: "Сколько я потратил за июль?",
            candidates: ["Продукты"]
        ) == .none)
        assert(requestedCategory(
            in: "How much did I spend on footwear?",
            candidates: ["Food"]
        ) == .missing)
        assert(requestedCategory(
            in: "How much did I spend on groceries?",
            candidates: ["Groceries", "Продукты"]
        ).match?.categories.count == 2)
        assert(requestedCategory(
            in: "How much did I spend on car insurance?",
            candidates: ["Car", "Car Insurance"]
        ).match?.categories == ["Car Insurance"])
        assert(Set(requestedCategory(
            in: "How much did I spend on food and rent?",
            candidates: ["Food", "Rent"]
        ).match?.categories ?? []) == ["Food", "Rent"])
        assert(requestedCategory(
            in: "How much did I spend at Starbucks?",
            candidates: ["Groceries"]
        ) == .missing)
        assert(requestedCategory(
            in: "What did I spend?",
            candidates: ["Groceries"]
        ) == .none)
        assert(requestedCategory(
            in: "How much money did I spend, please?",
            candidates: ["Groceries"]
        ) == .none)
        assert(requestedCategory(
            in: "Сколько денег я потратил?",
            candidates: ["Продукты"]
        ) == .none)
        assert(isFinancialQuestion("Какой у меня баланс?"))
        assert(isFinancialQuestion("Покажи расходы по категориям"))
        assert(isFinancialQuestion("Какой у меня доход?"))
        assert(isFinancialQuestion("Как спланировать бюджет?"))
        assert(adviceTask(for: "Where did my money go?").showsSpendingChart)
        assert(adviceTask(for: "Show my spending by category").showsSpendingChart)
        assert(adviceTask(for: "Show my credit-card spending breakdown").showsSpendingChart)
        assert(adviceTask(for: "Which expense category should I cut to save 1000 USD?") == .savingsPlan)
        assert(adviceTask(for: "How much did I spend and how can I save 1000 USD?") == .savingsPlan)
        assert(adviceTask(for: "How much did I spend by category?") == .spendingOverview)
        assert(adviceTask(for: "Show me a spending chart") == .spendingOverview)
        assert(!adviceTask(for: "What is my largest source of income?").showsSpendingChart)
        assert(!adviceTask(for: "Show my income categories").showsSpendingChart)
        assert(!adviceTask(for: "Where is my salary?").showsSpendingChart)
        assert(!adviceTask(for: "How can I save 1000 USD?").showsSpendingChart)
        assert(!isFinancialQuestion("How can I save a document?"))
        assert(isFinancialQuestion("How much should I save each month?"))
        assert(isFinancialQuestion("How can I save for retirement?"))
        assert(!isFinancialQuestion("How can I save 1000 photos?"))
        assert(!isFinancialQuestion("Why is my file saving at 50%?"))
        assert(adviceTask(for: "What does a 5% savings account rate mean?") == .general)
        assert(requestedSavingsAnalysisPeriod(
            from: "Using only my July spending, how can I save 1000 AZN?"
        ) != nil)
    }

    static func assertAsyncSelfCheck() async {
        let item = Transaction(
            amount: 50,
            kind: .expense,
            category: "Groceries",
            date: .now
        )
        let repository = FinancialAdviceSelfCheckRepository(items: [item])

        do {
            let useCase = GetFinancialAdviceUseCase(
                transactions: repository,
                advisor: FinancialAdviceSelfCheckAdvisor(failsOnCall: true)
            )
            _ = try await useCase.execute(question: "How much did I spend on cigarettes?")
            assertionFailure("A missing category must fail before calling the advisor")
        } catch DomainError.categoryNotFound {
            // Expected: the database lookup short-circuits the AI path.
        } catch {
            assertionFailure("Unexpected missing-category error: \(error)")
        }

        do {
            let useCase = GetFinancialAdviceUseCase(
                transactions: repository,
                advisor: FinancialAdviceSelfCheckAdvisor(failsOnCall: false)
            )
            let overview = try await useCase.execute(question: "Where did my money go?")
            let total = try await useCase.execute(question: "How much did I spend?")
            assert(overview.showsSpendingChart)
            assert(!total.showsSpendingChart)
        } catch {
            assertionFailure("Financial advice route self-check failed: \(error)")
        }
    }
    #endif

    private enum CategoryRequest: Equatable {
        case none
        case matched(CategoryMatch)
        case missing

        var match: CategoryMatch? {
            if case .matched(let match) = self { match } else { nil }
        }
    }

    private struct CategoryMatch: Equatable {
        let name: String
        let categories: [String]
    }
}

#if DEBUG
private struct FinancialAdviceSelfCheckRepository: TransactionRepository {
    let items: [Transaction]

    func fetchAll() async throws -> [Transaction] { items }
    func fetch(in period: DateInterval) async throws -> [Transaction] {
        items.filter { period.contains($0.date) }
    }
    func add(_ transaction: Transaction) async throws {}
    func update(_ transaction: Transaction) async throws {}
    func delete(id: UUID) async throws {}
}

private struct FinancialAdviceSelfCheckAdvisor: FinancialAdvisor {
    let failsOnCall: Bool
    var availability: AdvisorAvailability { .available }

    func advise(
        on summary: FinancialSummary,
        question: String?,
        task: FinancialAdviceTask
    ) async throws -> FinancialAdvice {
        if failsOnCall { throw FinancialAdviceSelfCheckError.advisorCalled }
        return FinancialAdvice(headline: "Self-check", tips: [])
    }
}

private enum FinancialAdviceSelfCheckError: Error {
    case advisorCalled
}
#endif
