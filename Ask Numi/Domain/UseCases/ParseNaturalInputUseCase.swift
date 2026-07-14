//
//  ParseNaturalInputUseCase.swift
//  Ask Numi
//

import Foundation

struct ParseNaturalInputUseCase: Sendable {
    private let parser: TransactionParser

    init(parser: TransactionParser) {
        self.parser = parser
    }

    /// Whether the on-device model can parse right now; drives whether the
    /// quick-add field is shown at all.
    var isAvailable: Bool { parser.availability == .available }

    func execute(_ text: String) async throws -> ParsedTransactionDraft {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DomainError.invalidQuestion }
        let draft = try await parser.parse(trimmed)
        guard draft.amount > 0 else { throw DomainError.invalidAmount }
        return draft
    }
}

#if DEBUG
extension ParseNaturalInputUseCase {
    static func assertSelfCheck() async {
        let coffee = ParsedTransactionDraft(amount: 350, kind: .expense, category: "Coffee", note: "Surf")
        let valid = ParseNaturalInputUseCase(parser: StubTransactionParser(result: coffee))
        let blank = try? await valid.execute("   ")
        assert(blank == nil, "blank input must be rejected")
        let draft = try? await valid.execute("spent 350 on coffee at Surf")
        assert(draft == coffee, "valid input must pass the draft through unchanged")

        let free = ParsedTransactionDraft(amount: 0, kind: .expense, category: "Sample", note: nil)
        let zero = ParseNaturalInputUseCase(parser: StubTransactionParser(result: free))
        let rejected = try? await zero.execute("got a free sample")
        assert(rejected == nil, "non-positive amount must be rejected")
    }
}

private struct StubTransactionParser: TransactionParser {
    let result: ParsedTransactionDraft
    var availability: AdvisorAvailability { .available }
    func parse(_ text: String) async throws -> ParsedTransactionDraft { result }
}
#endif
