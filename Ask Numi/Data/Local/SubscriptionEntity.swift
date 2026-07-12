//
//  SubscriptionEntity.swift
//  Ask Numi
//

import Foundation
import SwiftData

@Model
final class SubscriptionEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Decimal
    var billingDay: Int
    var nextChargeDate: Date

    init(_ subscription: Subscription) {
        id = subscription.id
        name = subscription.name
        amount = subscription.amount
        billingDay = subscription.billingDay
        nextChargeDate = subscription.nextChargeDate
    }

    func toDomain() -> Subscription {
        var subscription = Subscription(id: id, name: name, amount: amount, nextChargeDate: nextChargeDate)
        subscription.billingDay = billingDay
        return subscription
    }
}
