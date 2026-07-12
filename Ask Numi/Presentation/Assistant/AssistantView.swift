//
//  AssistantView.swift
//  Ask Numi
//

import SwiftUI

struct AssistantView: View {
    let getAdvice: GetFinancialAdviceUseCase
    @Binding var selectedTab: AppTab
    @State private var draft = ""
    @State private var exchanges: [AssistantExchange] = []
    @FocusState private var isInputFocused: Bool

    private var availability: AdvisorAvailability { getAdvice.advisorAvailability }

    private var isResponding: Bool {
        exchanges.contains { if case .loading = $0.phase { true } else { false } }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    GlassEffectContainer(spacing: 18) {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            header
                            availabilityNotice

                            if exchanges.isEmpty {
                                intro
                                suggestions
                            }

                            ForEach(exchanges) { exchange in
                                UserBubble(text: exchange.question)

                                switch exchange.phase {
                                case .loading:
                                    ThinkingBubble()
                                case .answered(let report):
                                    AnswerCard(report: report)
                                case .failed(let message):
                                    ErrorBubble(message: message)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .defaultScrollAnchor(exchanges.isEmpty ? .top : .bottom)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    inputBar
                    AppTabBar(selection: $selectedTab)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack {
            Text("Помощник")
                .font(.title3.weight(.bold))
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.body.weight(.semibold))
                .accessibilityLabel("История")
        }
    }

    private var intro: some View {
        Text("Задайте вопрос о финансах — я отвечу на основе ваших операций за текущий месяц. Всё считается на устройстве.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var availabilityNotice: some View {
        switch availability {
        case .available:
            EmptyView()
        case .downloading:
            notice("Модель ИИ ещё загружается на устройство. Попробуйте чуть позже.", symbol: "arrow.down.circle")
        case .unavailable:
            notice("ИИ-помощник недоступен: требуется включённый Apple Intelligence.", symbol: "exclamationmark.triangle")
        }
    }

    private func notice(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            suggestion("Куда ушли деньги в этом месяце?")
            suggestion("На чем можно сэкономить?")
            suggestion("Хватит ли мне денег до зарплаты?")
        }
    }

    private func suggestion(_ title: String) -> some View {
        Button(title) {
            submit(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.indigo)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .glassEffect(.regular.interactive(), in: .capsule)
        .buttonStyle(.plain)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Спросите что-нибудь...", text: $draft)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit { submit(draft) }
                .disabled(availability != .available)

            Image(systemName: "mic.fill")
                .foregroundStyle(.secondary)

            Button {
                submit(draft)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .glassEffect(.regular.tint(.indigo).interactive(), in: .circle)
            }
            .buttonStyle(.plain)
            .disabled(
                draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || availability != .available
                    || isResponding
            )
            .accessibilityLabel("Отправить")
        }
        .padding(.leading, 16)
        .padding(.trailing, 5)
        .frame(height: 50)
        .glassEffect(.regular, in: .capsule)
    }

    private var currentMonth: DateInterval {
        Calendar.current.dateInterval(of: .month, for: .now)
            ?? DateInterval(start: .distantPast, end: .distantFuture)
    }

    private func submit(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, availability == .available, !isResponding else { return }
        draft = ""

        let exchange = AssistantExchange(question: question)
        exchanges.append(exchange)

        Task {
            let phase: AssistantExchange.Phase
            do {
                let report = try await getAdvice.execute(question: question, for: currentMonth)
                phase = .answered(report)
            } catch DomainError.notEnoughData {
                phase = .failed("За этот месяц ещё нет операций. Добавьте несколько — и я смогу помочь.")
            } catch {
                phase = .failed("Не получилось составить ответ. Попробуйте ещё раз.")
            }
            if let index = exchanges.firstIndex(where: { $0.id == exchange.id }) {
                exchanges[index].phase = phase
            }
        }
    }
}

private struct AssistantExchange: Identifiable {
    enum Phase {
        case loading
        case answered(FinancialAdviceReport)
        case failed(String)
    }

    let id = UUID()
    let question: String
    var phase: Phase = .loading
}

private struct UserBubble: View {
    let text: String

    var body: some View {
        HStack {
            Spacer(minLength: 40)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular.tint(.indigo), in: .rect(cornerRadius: 18))
                .multilineTextAlignment(.leading)
        }
    }
}

private struct ThinkingBubble: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("Нуми готовит ответ…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .glassEffect(.regular, in: .capsule)
    }
}

private struct ErrorBubble: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.bubble")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(14)
            .glassEffect(.regular.tint(.red.opacity(0.08)), in: .rect(cornerRadius: 18))
    }
}

private struct AnswerCard: View {
    let report: FinancialAdviceReport

    private static let palette: [Color] = [.blue, .green, .orange, .yellow]

    private var categories: [SpendingCategory] {
        let total = report.summary.totalExpenses
        guard total > 0 else { return [] }

        let ranked = report.summary.expensesByCategory
        var items = ranked.prefix(Self.palette.count).enumerated().map { index, item in
            SpendingCategory(
                id: item.category,
                title: item.category,
                share: Self.share(item.amount, of: total),
                color: Self.palette[index]
            )
        }
        let rest = ranked.dropFirst(Self.palette.count).reduce(Decimal(0)) { $0 + $1.amount }
        if rest > 0 {
            items.append(SpendingCategory(id: "other", title: "Другое", share: Self.share(rest, of: total), color: .purple))
        }
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(report.advice.headline)
                .font(.subheadline.weight(.semibold))

            if !categories.isEmpty {
                HStack(spacing: 18) {
                    SpendingRing(
                        total: OperationFormatting.plain(report.summary.totalExpenses),
                        categories: categories
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categories) { category in
                            HStack(spacing: 7) {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 8, height: 8)
                                Text(category.title)
                                    .font(.caption)
                                Spacer()
                                Text(category.share.formatted(.percent.precision(.fractionLength(0))))
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(report.advice.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkle")
                            .font(.caption2)
                            .foregroundStyle(.indigo)
                            .padding(.top, 2)
                        Text(tip)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .glassEffect(.regular.tint(.indigo.opacity(0.12)), in: .rect(cornerRadius: 22))
    }

    private static func share(_ amount: Decimal, of total: Decimal) -> Double {
        NSDecimalNumber(decimal: amount).doubleValue / NSDecimalNumber(decimal: total).doubleValue
    }
}

private struct SpendingRing: View {
    let total: String
    let categories: [SpendingCategory]

    var body: some View {
        ZStack {
            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                Circle()
                    .trim(from: start(for: index), to: start(for: index) + category.share - 0.012)
                    .stroke(category.color, style: StrokeStyle(lineWidth: 13, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text("Всего")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(total)
                    .font(.caption.weight(.bold))
            }
        }
        .frame(width: 112, height: 112)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Всего расходов \(total)")
    }

    private func start(for index: Int) -> Double {
        categories.prefix(index).reduce(0) { $0 + $1.share }
    }
}

private struct SpendingCategory: Identifiable {
    let id: String
    let title: String
    let share: Double
    let color: Color
}

#Preview("Светлая тема") {
    AssistantView(
        getAdvice: AppContainer(isStoredInMemoryOnly: true).makeAdviceUseCase(),
        selectedTab: .constant(.assistant)
    )
}

#Preview("Тёмная тема") {
    AssistantView(
        getAdvice: AppContainer(isStoredInMemoryOnly: true).makeAdviceUseCase(),
        selectedTab: .constant(.assistant)
    )
    .preferredColorScheme(.dark)
}
