//
//  SavingsGoalEntity.swift
//  Ask Numi
//

import Foundation
import SwiftData

@Model
final class SavingsGoalEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbol: String
    var targetAmount: Decimal
    var savedAmount: Decimal
    var targetDate: Date

    init(_ goal: SavingsGoal) {
        id = goal.id
        name = goal.name
        symbol = goal.symbol
        targetAmount = goal.targetAmount
        savedAmount = goal.savedAmount
        targetDate = goal.targetDate
    }

    func toDomain() -> SavingsGoal {
        SavingsGoal(
            id: id,
            name: name,
            symbol: symbol,
            targetAmount: targetAmount,
            savedAmount: savedAmount,
            targetDate: targetDate
        )
    }
}
