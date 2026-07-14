//
//  ParsedTransactionDraft.swift
//  Ask Numi
//
//  A transaction the assistant extracted from free-form text. It is a
//  *draft*: the user reviews and confirms it in the form before it is saved.
//

import Foundation

struct ParsedTransactionDraft: Equatable, Sendable {
    var amount: Decimal        // always positive; `kind` defines direction
    var kind: TransactionKind
    var category: String
    var note: String?
}
