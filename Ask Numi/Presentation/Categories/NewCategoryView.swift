//
//  NewCategoryView.swift
//  Ask Numi
//

import SwiftUI

struct NewCategoryView: View {
    let addCategory: AddTransactionCategoryUseCase?
    let onSaved: (TransactionCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var kind: TransactionKind
    @State private var name = ""
    @State private var selectedIcon = CategoryIcon.options[0]
    @State private var selectedColor: CategoryColor
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var isNameFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    init(
        kind: TransactionKind = .expense,
        addCategory: AddTransactionCategoryUseCase? = nil,
        onSaved: @escaping (TransactionCategory) -> Void = { _ in }
    ) {
        self.addCategory = addCategory
        self.onSaved = onSaved
        _kind = State(initialValue: kind)
        _selectedColor = State(initialValue: .defaultColor(for: kind))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && trimmedName.count <= 60 && !isSaving
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    GlassEffectContainer(spacing: 16) {
                        VStack(alignment: .leading, spacing: 24) {
                            kindPicker
                            nameField
                            colorPicker
                            iconPicker

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(16)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(L10n.NewCategory.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? L10n.Common.saving : L10n.Common.save) {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear { isNameFocused = true }
            .tint(selectedColor.displayColor)
        }
    }

    private var kindPicker: some View {
        Picker(L10n.NewCategory.kindPickerLabel, selection: $kind) {
            ForEach(TransactionKind.allCases, id: \.self) { kind in
                Label(kind.title, systemImage: kind == .expense ? "minus.circle.fill" : "plus.circle.fill")
                    .tag(kind)
            }
        }
        .pickerStyle(.segmented)
        .tint(kind == .expense ? .red : .green)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.NewCategory.nameLabel)
                .font(.caption.weight(.semibold))

            TextField(L10n.NewCategory.namePlaceholder, text: $name)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit { Task { await save() } }
                .padding(14)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
        }
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.NewCategory.iconLabel)
                .font(.caption.weight(.semibold))

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(CategoryIcon.options, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.body.weight(.medium))
                            .foregroundStyle(icon == selectedIcon ? selectedColor.displayColor : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .glassEffect(
                                .regular
                                    .tint(icon == selectedIcon ? selectedColor.displayColor.opacity(0.18) : .clear)
                                    .interactive(),
                                in: .rect(cornerRadius: 14)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.NewCategory.selectIconLabel)
                    .accessibilityAddTraits(icon == selectedIcon ? .isSelected : [])
                }
            }
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.NewCategory.colorLabel)
                .font(.caption.weight(.semibold))

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(CategoryColor.allCases, id: \.self) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        Circle()
                            .fill(color.displayColor)
                            .frame(width: 38, height: 38)
                            .overlay {
                                if color == selectedColor {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                Circle()
                                    .stroke(color == selectedColor ? .white.opacity(0.9) : .clear, lineWidth: 3)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.NewCategory.color(color.rawValue))
                    .accessibilityAddTraits(color == selectedColor ? .isSelected : [])
                }
            }
        }
    }

    private func save() async {
        guard canSave else { return }
        isSaving = true

        let category = TransactionCategory(name: trimmedName, kind: kind, icon: selectedIcon, color: selectedColor)
        do {
            if let addCategory {
                try await addCategory.execute(category)
            }
            onSaved(category)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}

#Preview("Светлая тема") {
    NewCategoryView()
}

#Preview("Тёмная тема") {
    NewCategoryView()
        .preferredColorScheme(.dark)
}
