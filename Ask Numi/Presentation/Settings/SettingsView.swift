//
//  SettingsView.swift
//  Ask Numi
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: LocalizationManager
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("weeklySummaryEnabled") private var weeklySummaryEnabled = true
    @AppStorage("faceIDEnabled") private var faceIDEnabled = true
    @AppStorage(CurrencySettings.storageKey) private var currencyCode = CurrencySettings.defaultCode
    @AppStorage(AppearanceSettings.darkModeStorageKey) private var isDarkModeEnabled = false

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                Form {
                    Section(L10n.Settings.sectionAccount) {
                        destinationRow(title: L10n.Settings.profile, symbol: "person.crop.circle")
                        Picker(L10n.Settings.currency, selection: $currencyCode) {
                            ForEach(CurrencySettings.supportedCodes, id: \.self) { code in
                                Text("\(code) — \(CurrencySettings.displayName(for: code))").tag(code)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        Picker(L10n.Settings.language, selection: Binding(
                            get: { localization.currentLanguage },
                            set: localization.setLanguage
                        )) {
                            Text(L10n.Settings.languageName("ru")).tag("ru")
                            Text(L10n.Settings.languageName("en")).tag("en")
                        }
                        .pickerStyle(.navigationLink)
                    }

                    Section(L10n.Settings.sectionAppearance) {
                        Picker(L10n.Settings.theme, selection: $isDarkModeEnabled) {
                            Text(L10n.Settings.themeLight).tag(false)
                            Text(L10n.Settings.themeDark).tag(true)
                        }
                        .pickerStyle(.segmented)
                        destinationRow(title: L10n.Settings.accent, symbol: "paintpalette", value: L10n.Settings.accentValue)
                    }

                    Section(L10n.Settings.sectionNotifications) {
                        settingsToggle(title: L10n.Settings.reminders, symbol: "bell", isOn: $notificationsEnabled)
                        settingsToggle(title: L10n.Settings.weeklySummary, symbol: "calendar", isOn: $weeklySummaryEnabled)
                    }

                    Section(L10n.Settings.sectionSecurity) {
                        settingsToggle(title: L10n.Settings.faceID, symbol: "faceid", isOn: $faceIDEnabled)
                        destinationRow(title: L10n.Settings.passcode, symbol: "lock")
                    }

                    Section(L10n.Settings.sectionData) {
                        destinationRow(title: L10n.Settings.exportData, symbol: "square.and.arrow.up")
                        destinationRow(title: L10n.Settings.backup, symbol: "externaldrive")
                    }

                    Section(L10n.Settings.sectionAbout) {
                        destinationRow(title: L10n.Settings.rateApp, symbol: "star")
                        destinationRow(title: L10n.Settings.writeFeedback, symbol: "bubble.left")
                    }

                    Text(L10n.Settings.version(appVersion))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(L10n.Settings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel(L10n.Common.back)
                }
            }
            .tint(.indigo)
        }
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
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
                description: Text(L10n.Settings.placeholderMessage)
            )
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Светлая тема") {
    SettingsView()
        .environmentObject(LocalizationManager.shared)
}

#Preview("Тёмная тема") {
    SettingsView()
        .environmentObject(LocalizationManager.shared)
        .preferredColorScheme(.dark)
}
