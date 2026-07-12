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

    func advise(on summary: FinancialSummary, question: String?) async throws -> FinancialAdvice {
        // ponytail: session per request — advice is stateless; switch to one
        // shared session + isResponding checks when a chat screen appears.
        let session = LanguageModelSession {
            """
            Ты — дружелюбный финансовый помощник в приложении для личных финансов.
            Валюта пользователя — азербайджанский манат (AZN).
            Все суммы в запросе уже посчитаны приложением. DO NOT пересчитывать их
            и DO NOT придумывать числа, которых нет в запросе.
            Отвечай на русском языке, коротко и конкретно.
            """
        }
        let response = try await session.respond(
            to: prompt(for: summary, question: question),
            generating: AdviceOutput.self
        )
        return FinancialAdvice(headline: response.content.headline, tips: response.content.tips)
    }

    private func prompt(for summary: FinancialSummary, question: String?) -> String {
        var lines = [
            "Финансовая сводка пользователя за период:",
            "Доход: \(plain(summary.totalIncome)) AZN",
            "Расходы: \(plain(summary.totalExpenses)) AZN",
            "Баланс: \(plain(summary.balance)) AZN",
        ]
        if let rate = summary.savingsRate {
            lines.append("Доля сбережений: \(Int(rate * 100))%")
        }
        if !summary.expensesByCategory.isEmpty {
            lines.append("Расходы по категориям (по убыванию):")
            for item in summary.expensesByCategory.prefix(8) {
                lines.append("- \(item.category): \(plain(item.amount)) AZN")
            }
        }
        if let question, !question.isEmpty {
            lines.append("Вопрос пользователя: «\(question)»")
            lines.append("Заголовок — краткий ответ на вопрос по числам выше, затем три практичных совета.")
        } else {
            lines.append("Дай заголовок и три практичных совета, как улучшить финансы.")
        }
        return lines.joined(separator: "\n")
    }

    private func plain(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}

@Generable
private struct AdviceOutput {
    @Guide(description: "Короткий заголовок совета, до восьми слов")
    var headline: String

    @Guide(description: "Конкретные практичные советы по личным финансам", .count(3))
    var tips: [String]
}
