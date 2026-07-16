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
    nonisolated static let fallback = "tag.fill"

    nonisolated static let options = [
        "cart", "basket", "bag", "banknote", "creditcard",
        "car", "bus", "tram", "fuelpump", "airplane",
        "house", "building.2", "bolt", "drop", "flame",
        "fork.knife", "takeoutbag.and.cup.and.straw", "cup.and.saucer", "wineglass", "smoke.fill",
        "heart", "cross.case", "pills", "stethoscope", "dumbbell",
        "figure.walk", "tshirt", "gift", "birthday.cake", "stroller",
        "pawprint", "suitcase", "calendar", "clock", "phone",
        "book", "graduationcap", "briefcase", "laptopcomputer", "chart.line.uptrend.xyaxis",
        "gamecontroller", "film", "music.note", "headphones", "camera",
        "wrench.and.screwdriver", "hammer", "scissors", "paintbrush", "leaf",
        "tree", "lightbulb", "ellipsis"
    ]

    nonisolated static func suggested(for category: String, kind: TransactionKind) -> String {
        let name = category.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        if name.contains("bolt") || name.contains("transport") || name.contains("авто") { return "car" }
        if name.contains("продукт") || name.contains("grocery") { return "cart" }
        if name.contains("еда") || name.contains("food") || name.contains("кафе") { return "fork.knife" }
        if name.contains("сигар") || name.contains("табак") || name.contains("cigarette") || name.contains("smok") { return "smoke.fill" }
        if name.contains("вино") || name.contains("алког") || name.contains("wine") || name.contains("alcohol") { return "wineglass" }
        if name.contains("аренд") || name.contains("дом") || name.contains("home") { return "house" }
        if name.contains("зарплат") || name.contains("salary") { return "banknote" }
        return kind == .income ? "arrow.down.left.circle.fill" : fallback
    }
}
