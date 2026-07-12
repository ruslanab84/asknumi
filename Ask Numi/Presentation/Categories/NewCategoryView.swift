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
            .navigationTitle("Новая категория")
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

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var kindPicker: some View {
        Picker("Тип категории", selection: $kind) {
            ForEach(CategoryKind.allCases, id: \.self) { item in
                Label(item.title, systemImage: item.symbol).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .tint(kind == .expense ? .red : .green)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Название категории")
                .font(.caption.weight(.semibold))

            TextField("Например: Продукты", text: $name)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .description }
                .padding(14)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Цвет")
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
            Text("Иконка")
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
                    .accessibilityLabel("Выбрать иконку")
                    .accessibilityAddTraits(icon == selectedIcon ? .isSelected : [])
                }
            }
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Описание (необязательно)")
                .font(.caption.weight(.semibold))

            TextField("Введите описание категории", text: $description, axis: .vertical)
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
        case .expense: "Расход"
        case .income: "Доход"
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
        CategoryColorOption(id: "red", title: "Красный", color: .red),
        CategoryColorOption(id: "pink", title: "Розовый", color: .pink),
        CategoryColorOption(id: "orange", title: "Оранжевый", color: .orange),
        CategoryColorOption(id: "yellow", title: "Жёлтый", color: .yellow),
        CategoryColorOption(id: "green", title: "Зелёный", color: .green),
        CategoryColorOption(id: "mint", title: "Мятный", color: .mint),
        CategoryColorOption(id: "cyan", title: "Голубой", color: .cyan),
        CategoryColorOption(id: "blue", title: "Синий", color: .blue),
        CategoryColorOption(id: "purple", title: "Фиолетовый", color: .purple)
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
