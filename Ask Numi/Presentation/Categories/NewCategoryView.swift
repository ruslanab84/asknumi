//
//  NewCategoryView.swift
//  Ask Numi
//

import SwiftUI

struct NewCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var kind: CategoryKind = .expense
    @State private var name = ""
    @State private var selectedColor = CategoryColorOption.options[0]
    @State private var selectedIcon = "cart"
    @State private var description = ""
    @FocusState private var focusedField: Field?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

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
                            descriptionField
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel(L10n.Common.back)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var kindPicker: some View {
        Picker(L10n.NewCategory.kindPickerLabel, selection: $kind) {
            ForEach(CategoryKind.allCases, id: \.self) { item in
                Label(item.title, systemImage: item.symbol).tag(item)
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
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .description }
                .padding(14)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.NewCategory.colorLabel)
                .font(.caption.weight(.semibold))

            HStack(spacing: 12) {
                ForEach(CategoryColorOption.options) { option in
                    Button {
                        selectedColor = option
                    } label: {
                        Circle()
                            .fill(option.color)
                            .frame(width: 28, height: 28)
                            .padding(3)
                            .overlay {
                                Circle()
                                    .stroke(option == selectedColor ? option.color : .clear, lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(option == selectedColor ? .isSelected : [])
                }
            }
        }
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.NewCategory.iconLabel)
                .font(.caption.weight(.semibold))

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(categoryIcons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.body.weight(.medium))
                            .foregroundStyle(icon == selectedIcon ? selectedColor.color : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .glassEffect(
                                .regular
                                    .tint(icon == selectedIcon ? selectedColor.color.opacity(0.18) : .clear)
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

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.NewCategory.descriptionLabel)
                .font(.caption.weight(.semibold))

            TextField(L10n.NewCategory.descriptionPlaceholder, text: $description, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .focused($focusedField, equals: .description)
                .padding(14)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
        }
    }
}

private enum Field {
    case name
    case description
}

private enum CategoryKind: CaseIterable {
    case expense
    case income

    var title: String {
        switch self {
        case .expense: L10n.Common.expense
        case .income: L10n.Common.income
        }
    }

    var symbol: String {
        switch self {
        case .expense: "minus.circle.fill"
        case .income: "plus.circle.fill"
        }
    }
}

private struct CategoryColorOption: Identifiable, Equatable {
    let id: String
    let title: String
    let color: Color

    static let options = [
        CategoryColorOption(id: "red", title: L10n.NewCategory.color("red"), color: .red),
        CategoryColorOption(id: "pink", title: L10n.NewCategory.color("pink"), color: .pink),
        CategoryColorOption(id: "orange", title: L10n.NewCategory.color("orange"), color: .orange),
        CategoryColorOption(id: "yellow", title: L10n.NewCategory.color("yellow"), color: .yellow),
        CategoryColorOption(id: "green", title: L10n.NewCategory.color("green"), color: .green),
        CategoryColorOption(id: "mint", title: L10n.NewCategory.color("mint"), color: .mint),
        CategoryColorOption(id: "cyan", title: L10n.NewCategory.color("cyan"), color: .cyan),
        CategoryColorOption(id: "blue", title: L10n.NewCategory.color("blue"), color: .blue),
        CategoryColorOption(id: "purple", title: L10n.NewCategory.color("purple"), color: .purple)
    ]

    static func == (lhs: CategoryColorOption, rhs: CategoryColorOption) -> Bool {
        lhs.id == rhs.id
    }
}

private let categoryIcons = [
    "cart", "bag", "car", "house", "heart",
    "fork.knife", "figure.walk", "cup.and.saucer", "tshirt", "cross.case",
    "gift", "airplane", "book", "gamecontroller", "pawprint",
    "calendar", "phone", "graduationcap", "music.note", "ellipsis"
]

#Preview("Светлая тема") {
    NewCategoryView()
}

#Preview("Тёмная тема") {
    NewCategoryView()
        .preferredColorScheme(.dark)
}
