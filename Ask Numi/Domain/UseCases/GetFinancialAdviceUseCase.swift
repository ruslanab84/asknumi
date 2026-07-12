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
        let allItems = try await transactions.fetchAll()
        let period = question.flatMap(requestedPeriod)
        let items = period.map { selected in
            allItems.filter { selected.contains($0.date) }
        } ?? allItems
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
}
