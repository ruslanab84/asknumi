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
        let period = question.flatMap(requestedPeriod)
        let periodItems = period.map { selected in
            allItems.filter { selected.contains($0.date) }
        } ?? allItems
        let items: [Transaction]
        if let question, let category = Self.requestedCategory(in: question, candidates: allItems.map(\.category)) {
            items = periodItems.filter { category.matches($0.category) }
        } else {
            items = periodItems
        }
        guard !items.isEmpty else { throw DomainError.notEnoughData }
        let summary = FinancialSummary(
            transactions: items,
            period: period ?? DateInterval(start: .distantPast, end: .distantFuture)
        )
        let advice = try await advisor.advise(on: summary, transactions: items, question: question)
        return FinancialAdviceReport(summary: summary, advice: advice)
    }

    private func requestedPeriod(from question: String) -> DateInterval? {
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

    private static func requestedCategory(in question: String, candidates: [String]) -> CategoryQuery? {
        let tokens = Self.tokens(in: question)
        let tokenSet = Set(tokens)
        guard Self.isAmountQuestion(tokens) else { return nil }

        if let aliases = Self.categoryAliases.first(where: { !$0.isDisjoint(with: tokenSet) }) {
            return CategoryQuery(terms: aliases)
        }

        if let category = candidates.first(where: { category in
            let categoryTokens = Set(Self.tokens(in: category)).filter { $0.count > 2 }
            return !categoryTokens.isEmpty && !categoryTokens.isDisjoint(with: tokenSet)
        }) {
            return CategoryQuery(terms: Set(Self.tokens(in: category)))
        }

        return nil
    }

    private static func isAmountQuestion(_ tokens: [String]) -> Bool {
        let terms = Set(tokens)
        return !terms.isDisjoint(with: financialTerms)
    }

    private static func isFinancialQuestion(_ question: String) -> Bool {
        let tokens = tokens(in: question)
        guard question.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else { return false }

        return tokens.contains { token in
            financialTopicRoots.contains { token.hasPrefix($0) }
        }
    }

    private static let financialTopicRoots: Set<String> = [
        "spend", "spent", "expense", "income", "earn", "balance", "budget", "money", "save", "saving",
        "salary", "rent", "debt", "loan", "credit", "transaction", "cost", "afford", "financ", "subscript",
        "потрат", "расход", "доход", "заработ", "баланс", "бюджет", "деньг", "денег", "сэконом",
        "зарплат", "аренд", "долг", "кредит", "операц", "стоим", "финанс", "подпис",
        "potrat", "rasxod", "doxod", "zarabot", "balans", "byudjet", "dengi", "deneg", "sekonom",
        "zarplat", "arend", "dolg", "kredit", "operac", "stoim", "finans", "podpisk"
    ]

    private static let financialTerms: Set<String> = [
            "spend", "spent", "spending", "expense", "expenses", "income", "earned", "earn",
            "потрат", "трата", "расход", "доход", "сколько"
    ]

    private static func tokens(in value: String) -> [String] {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
            .map(stem)
    }

    nonisolated private static func stem(_ token: String) -> String {
        if token.hasSuffix("ies") { return String(token.dropLast(3)) + "y" }
        if token.hasSuffix("s"), token.count > 3 { return String(token.dropLast()) }
        return token
    }

    private static let categoryAliases: [Set<String>] = [
        ["grocery", "product", "продукт", "продукты", "produkty", "produkt"],
        ["food", "еда", "кафе", "restaurant"],
        ["transport", "bolt", "taxi", "авто", "транспорт"],
        ["salary", "зарплата", "zarplata"],
        ["rent", "аренда", "arenda"],
        ["interest", "процент", "procent"]
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

    #if DEBUG
    static func assertSelfCheck() {
        assert(isFinancialQuestion("What should I do to save 1000 USD?"))
        assert(isFinancialQuestion("How should I plan my finances?"))
        assert(!isFinancialQuestion("How much does an elephant weigh?"))
        assert(!isFinancialQuestion("Skolko vesit slon?"))
        assert(requestedCategory(
            in: "What should I do to save 1000 USD?",
            candidates: ["Groceries"]
        ) == nil)
        assert(requestedCategory(
            in: "How much did I spend on groceries?",
            candidates: ["Groceries"]
        ) != nil)
    }
    #endif
}

private struct CategoryQuery {
    let terms: Set<String>

    func matches(_ category: String) -> Bool {
        let categoryTerms = Set(tokens(in: category))
        return !terms.isDisjoint(with: categoryTerms)
    }

    private func tokens(in value: String) -> [String] {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
            .map { token in
                if token.hasSuffix("ies") { return String(token.dropLast(3)) + "y" }
                if token.hasSuffix("s"), token.count > 3 { return String(token.dropLast()) }
                return token
            }
    }
}
