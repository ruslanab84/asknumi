//
//  TransactionCategoryEntity.swift
//  Ask Numi
//

import Foundation
import SwiftData

@Model
final class TransactionCategoryEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var icon: String
    var colorRaw: String?

    init(_ category: TransactionCategory) {
        id = category.id
        name = category.name
        kindRaw = category.kind.rawValue
        icon = category.icon
        colorRaw = category.color.rawValue
    }

    func toDomain() -> TransactionCategory? {
        guard let kind = TransactionKind(rawValue: kindRaw) else { return nil }
        return TransactionCategory(
            id: id,
            name: name,
            kind: kind,
            icon: icon,
            color: colorRaw.flatMap(CategoryColor.init(rawValue:))
        )
    }
}
