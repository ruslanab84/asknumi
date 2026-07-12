//
//  SettingsView.swift
//  Ask Numi
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("weeklySummaryEnabled") private var weeklySummaryEnabled = true
    @AppStorage("faceIDEnabled") private var faceIDEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                Form {
                    Section("Аккаунт") {
                        destinationRow(title: "Профиль", symbol: "person.crop.circle")
                        destinationRow(title: "Валюта", symbol: "banknote", detail: "AZN — Азербайджанский манат")
                        destinationRow(title: "Язык", symbol: "globe", value: "Русский")
                    }

                    Section("Внешний вид") {
                        destinationRow(title: "Тема", symbol: "circle.lefthalf.filled", value: "Системная")
                        destinationRow(title: "Цвет акцента", symbol: "paintpalette", value: "Фиолетовый")
                    }

                    Section("Уведомления") {
                        settingsToggle(title: "Напоминания", symbol: "bell", isOn: $notificationsEnabled)
                        settingsToggle(title: "Еженедельная сводка", symbol: "calendar", isOn: $weeklySummaryEnabled)
                    }

                    Section("Безопасность") {
                        settingsToggle(title: "Face ID", symbol: "faceid", isOn: $faceIDEnabled)
                        destinationRow(title: "Код-пароль", symbol: "lock")
                    }

                    Section("Данные") {
                        destinationRow(title: "Экспорт данных", symbol: "square.and.arrow.up")
                        destinationRow(title: "Резервная копия", symbol: "externaldrive")
                    }

                    Section("О приложении") {
                        destinationRow(title: "Оценить приложение", symbol: "star")
                        destinationRow(title: "Написать отзыв", symbol: "bubble.left")
                    }

                    Text("Версия \(appVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Назад")
                }
            }
            .tint(.indigo)
        }
    }

    private func destinationRow(
        title: String,
        symbol: String,
        detail: String? = nil,
        value: String? = nil
    ) -> some View {
        NavigationLink {
            SettingsPlaceholder(title: title, symbol: symbol)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .foregroundStyle(.indigo)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let value {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func settingsToggle(
        title: String,
        symbol: String,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            Label(title, systemImage: symbol)
                .labelStyle(SettingsLabelStyle())
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

private struct SettingsLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .foregroundStyle(.indigo)
                .frame(width: 24)
            configuration.title
        }
    }
}

private struct SettingsPlaceholder: View {
    let title: String
    let symbol: String

    var body: some View {
        ZStack {
            DashboardBackground()
            ContentUnavailableView(
                title,
                systemImage: symbol,
                description: Text("Настройка будет доступна позже.")
            )
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Светлая тема") {
    SettingsView()
}

#Preview("Тёмная тема") {
    SettingsView()
        .preferredColorScheme(.dark)
}
