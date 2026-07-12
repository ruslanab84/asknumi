//
//  TransactionCategory.swift
//  Ask Numi
//

import Foundation

struct TransactionCategory: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var kind: TransactionKind
    var icon: String

    init(id: UUID = UUID(), name: String, kind: TransactionKind, icon: String) {
        self.id = id
        self.name = name
        self.kind = kind
        self.icon = icon
    }
}

enum CategoryIcon {
    static let fallback = "tag.fill"

    static let options = [
        "cart", "bag", "car", "house", "heart",
        "fork.knife", "figure.walk", "cup.and.saucer", "tshirt", "cross.case",
        "gift", "airplane", "book", "gamecontroller", "pawprint",
        "calendar", "phone", "graduationcap", "music.note", "ellipsis"
    ]

    static func suggested(for category: String, kind: TransactionKind) -> String {
        let name = category.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        if name.contains("bolt") || name.contains("transport") || name.contains("авто") { return "car" }
        if name.contains("продукт") || name.contains("grocery") { return "cart" }
        if name.contains("еда") || name.contains("food") || name.contains("кафе") { return "fork.knife" }
        if name.contains("аренд") || name.contains("дом") || name.contains("home") { return "house" }
        if name.contains("зарплат") || name.contains("salary") { return "banknote" }
        return kind == .income ? "arrow.down.left.circle.fill" : fallback
    }
}
