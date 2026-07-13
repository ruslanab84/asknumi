//
//  BudgetEntity.swift
//  Ask Numi
//

import Foundation
import SwiftData

@Model
final class BudgetEntity {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var categoryKey: String
    var category: String
    var categoryIcon: String
    var monthlyLimit: Decimal

    init(_ budget: Budget) {
        id = budget.id
        categoryKey = budget.categoryKey
        category = budget.category
        categoryIcon = budget.categoryIcon
        monthlyLimit = budget.monthlyLimit
    }

    func toDomain() -> Budget {
        Budget(id: id, category: category, categoryIcon: categoryIcon, monthlyLimit: monthlyLimit)
    }
}
