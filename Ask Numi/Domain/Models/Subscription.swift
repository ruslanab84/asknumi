//
//  Subscription.swift
//  Ask Numi
//

import Foundation

struct Subscription: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var amount: Decimal
    var billingDay: Int
    var nextChargeDate: Date
    var endDate: Date?

    nonisolated init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        nextChargeDate: Date,
        endDate: Date? = nil,
        calendar: Calendar = .current
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.billingDay = calendar.component(.day, from: nextChargeDate)
        self.nextChargeDate = calendar.startOfDay(for: nextChargeDate)
        self.endDate = endDate.map { calendar.startOfDay(for: $0) }
    }

    nonisolated var hasRemainingCharges: Bool {
        endDate.map { nextChargeDate <= $0 } ?? true
    }

    nonisolated static func followingChargeDate(
        after date: Date,
        billingDay: Int,
        calendar: Calendar = .current
    ) -> Date {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        let day = min(billingDay, calendar.range(of: .day, in: .month, for: nextMonth)?.count ?? billingDay)
        var components = calendar.dateComponents([.year, .month], from: nextMonth)
        components.day = day
        return calendar.date(from: components) ?? nextMonth
    }
}

#if DEBUG
extension Subscription {
    nonisolated static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        guard
            let firstCharge = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31)),
            let endDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 30))
        else {
            assertionFailure("Could not create Subscription self-check dates")
            return
        }

        let subscription = Subscription(
            name: "Six-month loan",
            amount: 100,
            nextChargeDate: firstCharge,
            endDate: endDate,
            calendar: calendar
        )
        var chargeDate = subscription.nextChargeDate
        var chargeCount = 0
        while chargeDate <= endDate {
            chargeCount += 1
            chargeDate = followingChargeDate(
                after: chargeDate,
                billingDay: subscription.billingDay,
                calendar: calendar
            )
        }

        assert(chargeCount == 6)
        assert(chargeDate > endDate)
    }
}
#endif
