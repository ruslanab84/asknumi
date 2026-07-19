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
    var color: CategoryColor

    init(
        id: UUID = UUID(),
        name: String,
        kind: TransactionKind,
        icon: String,
        color: CategoryColor? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.icon = icon
        self.color = color ?? CategoryColor.defaultColor(for: kind)
    }
}

enum CategoryColor: String, CaseIterable, Sendable {
    case red, pink, orange, yellow, green, mint, cyan, blue, purple

    nonisolated static func defaultColor(for kind: TransactionKind) -> Self {
        kind == .income ? .green : .red
    }

    nonisolated static func assertSelfCheck() {
        assert(defaultColor(for: .expense) == .red)
        assert(defaultColor(for: .income) == .green)
    }
}

enum CategoryIcon {
    nonisolated static let fallback = "tag.fill"

    nonisolated static let options = [
        "cart", "basket", "bag", "banknote", "creditcard",
        "car", "bus", "tram", "fuelpump", "airplane",
        "bicycle", "scooter", "ferry", "train.side.front.car", "steeringwheel",
        "house", "building.2", "bolt", "drop", "flame",
        "bed.double", "sofa", "washer", "refrigerator", "lamp.table",
        "fork.knife", "takeoutbag.and.cup.and.straw", "cup.and.saucer", "wineglass", "smoke.fill",
        "carrot", "fish", "fork.knife.circle", "popcorn", "mug",
        "heart", "cross.case", "pills", "stethoscope", "dumbbell",
        "tooth", "bandage", "facemask", "figure.run", "figure.mind.and.body",
        "figure.walk", "tshirt", "gift", "birthday.cake", "stroller",
        "shoe", "handbag", "eyeglasses", "watch.analog", "sunglasses",
        "pawprint", "suitcase", "calendar", "clock", "phone",
        "globe", "map", "mappin.and.ellipse", "tent", "beach.umbrella",
        "book", "graduationcap", "briefcase", "laptopcomputer", "chart.line.uptrend.xyaxis",
        "printer", "keyboard", "display", "server.rack", "shippingbox",
        "gamecontroller", "film", "music.note", "headphones", "camera",
        "tv", "ticket", "theatermasks", "paintpalette", "sportscourt",
        "wrench.and.screwdriver", "hammer", "scissors", "paintbrush", "leaf",
        "tree", "lightbulb", "ellipsis", "person.2", "person.crop.circle",
        "shield", "lock", "key", "doc.text", "folder",
        "percent", "dollarsign.circle", "eurosign.circle", "bitcoinsign.circle", "chart.pie"
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
        if name.contains("card") || name.contains("карт") { return "creditcard" }
        if name.contains("account") || name.contains("счёт") || name.contains("счет") || name.contains("deposit") || name.contains("депозит") { return "building.2" }
        return kind == .income ? "arrow.down.left.circle.fill" : fallback
    }
}
