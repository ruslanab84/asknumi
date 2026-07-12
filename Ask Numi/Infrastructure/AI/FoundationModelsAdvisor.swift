//
//  FoundationModelsAdvisor.swift
//  Ask Numi
//
//  Adapter over Apple's on-device Foundation Model. All numbers arrive
//  pre-computed in `FinancialSummary`; the model only phrases advice.
//

import Foundation
import FoundationModels

final class FoundationModelsAdvisor: FinancialAdvisor {

    var availability: AdvisorAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(.modelNotReady):
            return .downloading
        case .unavailable:
            return .unavailable
        }
    }

    func advise(on summary: FinancialSummary, transactions: [Transaction], question: String?) async throws -> FinancialAdvice {
        // ponytail: session per request — advice is stateless; switch to one
        // shared session + isResponding checks when a chat screen appears.
        let session = LanguageModelSession {
            """
            You are a friendly personal finance assistant.
            The user's currency is Azerbaijani manat (AZN).
            All amounts are already calculated by the app. Do not recalculate them
            or invent numbers that are not present in the request.
            The app has already filtered the data to the requested category and period.
            The saved transactions below are the complete and exclusive dataset.
            DO NOT mention, estimate, or give tips about categories absent from them.
            Answer briefly and concretely in simple English.
            """
        }
        let response = try await session.respond(
            to: prompt(for: summary, transactions: transactions, question: question),
            generating: AdviceOutput.self
        )
        return FinancialAdvice(headline: response.content.headline, tips: response.content.tips)
    }

    private func prompt(for summary: FinancialSummary, transactions: [Transaction], question: String?) -> String {
        var lines = [
            "User financial summary:",
            "Income: \(plain(summary.totalIncome)) AZN",
            "Expenses: \(plain(summary.totalExpenses)) AZN",
            "Balance: \(plain(summary.balance)) AZN",
        ]
        if let rate = summary.savingsRate {
            lines.append("Savings rate: \(Int(rate * 100))%")
        }
        if !summary.expensesByCategory.isEmpty {
            lines.append("Expenses by category, descending:")
            for item in summary.expensesByCategory.prefix(8) {
                lines.append("- \(latin(item.category)): \(plain(item.amount)) AZN")
            }
        }
        lines.append("Saved transactions, newest first:")
        // ponytail: cap keeps the on-device model within its context window.
        for transaction in transactions.sorted(by: { $0.date > $1.date }).prefix(100) {
            let kind = transaction.kind == .income ? "income" : "expense"
            lines.append("- \(transaction.date.formatted(date: .numeric, time: .omitted)); \(kind); \(latin(transaction.category)); \(plain(transaction.amount)) AZN")
        }
        if let question, !question.isEmpty {
            lines.append("User question: \(latin(question))")
            lines.append("Give a short direct answer as the headline, followed by three practical tips.")
        } else {
            lines.append("Give a headline and three practical tips to improve the user's finances.")
        }
        return lines.joined(separator: "\n")
    }

    private func latin(_ value: String) -> String {
        value.applyingTransform(.toLatin, reverse: false) ?? value
    }

    private func plain(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}

@Generable
private struct AdviceOutput {
    @Guide(description: "A short direct answer, up to eight words")
    var headline: String

    @Guide(description: "Concrete and practical personal finance tips", .count(3))
    var tips: [String]
}
