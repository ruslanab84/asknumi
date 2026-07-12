//
//  PlanView.swift
//  Ask Numi
//

import SwiftUI

struct PlanView: View {
    let snapshot: PlanSnapshot
    @Binding var selectedTab: AppTab
    @State private var section: PlanSection = .payments

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    GlassEffectContainer(spacing: 20) {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            header
                            sectionPicker

                            switch section {
                            case .payments:
                                paymentsContent
                            case .budgets:
                                PlanPlaceholder(title: "Бюджеты", symbol: "chart.bar.fill")
                            case .goals:
                                PlanPlaceholder(title: "Цели", symbol: "target")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 104)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaInset(edge: .bottom) {
                AppTabBar(selection: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack {
            Text("План")
                .font(.title3.weight(.bold))
            Spacer()
            Image(systemName: "calendar")
                .font(.body.weight(.semibold))
                .accessibilityLabel("Календарь")
        }
    }

    private var sectionPicker: some View {
        Picker("Раздел плана", selection: $section) {
            ForEach(PlanSection.allCases, id: \.self) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }

    private var paymentsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            UpcomingPayments(payments: snapshot.payments)

            Button("Все платежи") { }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.indigo)

            BalanceForecast(balance: snapshot.forecastBalance)
            BudgetProgress(budget: snapshot.budget)
        }
    }
}

private struct UpcomingPayments: View {
    let payments: [PlannedPayment]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ближайшие платежи")
                .font(.subheadline.weight(.bold))

            VStack(spacing: 0) {
                ForEach(Array(payments.enumerated()), id: \.element.id) { index, payment in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(payment.color)
                                .frame(width: 10, height: 10)
                            if index < payments.count - 1 {
                                Rectangle()
                                    .fill(.secondary.opacity(0.25))
                                    .frame(width: 2, height: 46)
                            }
                        }
                        .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(payment.date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(payment.title)
                                .font(.subheadline.weight(.semibold))
                        }

                        Spacer()

                        Text(payment.amount)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(payment.isIncome ? .green : .primary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

private struct BalanceForecast: View {
    let balance: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Прогнозируемый остаток")
                .font(.caption)
                .foregroundStyle(.green)

            HStack {
                Text(balance)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Spacer()
                ForecastLine()
                    .stroke(.green, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 92, height: 42)
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(.green.opacity(0.18)), in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}

private struct ForecastLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.68))
        path.addLine(to: CGPoint(x: rect.width * 0.42, y: rect.height * 0.76))
        path.addLine(to: CGPoint(x: rect.width * 0.62, y: rect.height * 0.38))
        path.addLine(to: CGPoint(x: rect.width * 0.78, y: rect.height * 0.48))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        return path
    }
}

private struct BudgetProgress: View {
    let budget: PlannedBudget

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Бюджеты")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Button("Все") { }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
            }

            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.orange)
                    .frame(width: 4, height: 52)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(budget.title)
                                .font(.subheadline.weight(.semibold))
                            Text("\(budget.spent) / \(budget.limit)")
                                .font(.caption)
                        }
                        Spacer()
                        Text(budget.progress.formatted(.percent.precision(.fractionLength(0))))
                            .font(.subheadline.weight(.bold))
                    }

                    ProgressView(value: budget.progress)
                        .tint(.orange)
                }
            }

            Text("Осталось \(budget.remaining)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PlanPlaceholder: View {
    let title: String
    let symbol: String

    var body: some View {
        ContentUnavailableView(
            "Раздел «\(title)»",
            systemImage: symbol,
            description: Text("Скоро здесь появятся ваши данные.")
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}

private enum PlanSection: CaseIterable {
    case payments
    case budgets
    case goals

    var title: String {
        switch self {
        case .payments: "Платежи"
        case .budgets: "Бюджеты"
        case .goals: "Цели"
        }
    }
}

struct PlanSnapshot {
    let payments: [PlannedPayment]
    let forecastBalance: String
    let budget: PlannedBudget

    static let preview = PlanSnapshot(
        payments: [
            PlannedPayment(id: "icloud", date: "15 июля", title: "iCloud", amount: "−5 AZN", color: .blue, isIncome: false),
            PlannedPayment(id: "credit", date: "20 июля", title: "Кредит", amount: "−340 AZN", color: .gray, isIncome: false),
            PlannedPayment(id: "salary", date: "1 августа", title: "Зарплата", amount: "+3 200 AZN", color: .green, isIncome: true)
        ],
        forecastBalance: "3 890 AZN",
        budget: PlannedBudget(title: "Кафе и рестораны", spent: "186 AZN", limit: "250 AZN", remaining: "64 AZN", progress: 0.74)
    )
}

struct PlannedPayment: Identifiable {
    let id: String
    let date: String
    let title: String
    let amount: String
    let color: Color
    let isIncome: Bool
}

struct PlannedBudget {
    let title: String
    let spent: String
    let limit: String
    let remaining: String
    let progress: Double
}

#Preview("Светлая тема") {
    PlanView(snapshot: .preview, selectedTab: .constant(.plan))
}

#Preview("Тёмная тема") {
    PlanView(snapshot: .preview, selectedTab: .constant(.plan))
        .preferredColorScheme(.dark)
}
