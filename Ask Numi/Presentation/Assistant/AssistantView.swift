//
//  AssistantView.swift
//  Ask Numi
//

import SwiftUI

struct AssistantView: View {
    let snapshot: AssistantSnapshot
    @Binding var selectedTab: AppTab
    @State private var draft = ""
    @State private var sentMessages: [String] = []
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    GlassEffectContainer(spacing: 18) {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            header
                            UserBubble(text: snapshot.question)
                            SpendingAnswer(snapshot: snapshot)
                            suggestions

                            ForEach(sentMessages, id: \.self) { message in
                                UserBubble(text: message)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
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

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 10) {
            suggestion("На чем можно сэкономить?")
            suggestion("Хватит ли мне денег до зарплаты?")
        }
    }

    private func suggestion(_ title: String) -> some View {
        Button(title) {
            draft = title
            isInputFocused = true
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
                .onSubmit(send)

            Image(systemName: "mic.fill")
                .foregroundStyle(.secondary)

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .glassEffect(.regular.tint(.indigo).interactive(), in: .circle)
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Отправить")
        }
        .padding(.leading, 16)
        .padding(.trailing, 5)
        .frame(height: 50)
        .glassEffect(.regular, in: .capsule)
    }

    private func send() {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        sentMessages.append(message)
        draft = ""
    }
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

private struct SpendingAnswer: View {
    let snapshot: AssistantSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Вот ваши расходы за июль\n(1–14 июля):")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 18) {
                SpendingRing(total: snapshot.total, categories: snapshot.categories)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(snapshot.categories) { category in
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

            Text(snapshot.insight)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Показать операции") { }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.indigo)
        }
        .padding(16)
        .glassEffect(.regular.tint(.indigo.opacity(0.12)), in: .rect(cornerRadius: 22))
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

struct AssistantSnapshot {
    let question: String
    let total: String
    let categories: [SpendingCategory]
    let insight: String

    static let preview = AssistantSnapshot(
        question: "Куда ушли деньги в этом месяце?",
        total: "2 904 AZN",
        categories: [
            SpendingCategory(id: "groceries", title: "Продукты", share: 0.38, color: .blue),
            SpendingCategory(id: "transport", title: "Транспорт", share: 0.17, color: .green),
            SpendingCategory(id: "coffee", title: "Кафе", share: 0.14, color: .orange),
            SpendingCategory(id: "subscriptions", title: "Подписки", share: 0.11, color: .yellow),
            SpendingCategory(id: "other", title: "Другое", share: 0.20, color: .purple)
        ],
        insight: "Вы больше всего тратите на продукты. Это на 12% больше, чем в прошлом месяце."
    )
}

struct SpendingCategory: Identifiable {
    let id: String
    let title: String
    let share: Double
    let color: Color
}

#Preview("Светлая тема") {
    AssistantView(snapshot: .preview, selectedTab: .constant(.assistant))
}

#Preview("Тёмная тема") {
    AssistantView(snapshot: .preview, selectedTab: .constant(.assistant))
        .preferredColorScheme(.dark)
}
