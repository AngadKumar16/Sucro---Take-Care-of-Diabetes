//
//  FoodSearchView.swift
//  DiabetesCare
//
//  Look up carbs: search the bundled USDA foods, pick a portion, and the
//  carbs are added to the meal being logged. Scanned packages and foods
//  the person adds are kept for next time.
//

import SwiftUI
import TipKit

/// A food added to a meal: what it was and the carbs it brought.
struct FoodPick: Equatable {
    var name: String
    var carbs: Double
}

struct FoodSearchView: View {
    let onAdd: (FoodPick) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var library = FoodLibrary.shared
    @State private var query = ""
    @State private var results: [FoodItem] = []
    @State private var path: [FoodItem] = []
    @State private var showScanner = false
    @State private var showAddOwn = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if query.isEmpty {
                    TipView(FoodSearchTip())
                        .listRowBackground(Color.clear)
                    if !library.recent.isEmpty {
                        Section("Recent") {
                            ForEach(library.recent) { food in row(food) }
                        }
                        .listRowBackground(Theme.card)
                    }
                    if !library.saved.isEmpty {
                        Section("My Foods") {
                            ForEach(library.saved) { food in row(food) }
                                .onDelete { offsets in
                                    for index in offsets { library.remove(library.saved[index]) }
                                }
                        }
                        .listRowBackground(Theme.card)
                    }
                    if library.recent.isEmpty && library.saved.isEmpty {
                        ContentUnavailableView("Search for a Food", systemImage: "fork.knife",
                                               description: Text("Try \"apple\", \"pizza\" or \"orange juice\"."))
                            .listRowBackground(Color.clear)
                    }
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(results) { food in row(food) }
                    } footer: {
                        Text("Carbs from USDA FoodData Central. Values are estimates; check labels when you can.")
                    }
                    .listRowBackground(Theme.card)
                }
            }
            .instrumentBackground()
            .navigationTitle("Look Up Carbs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search foods")
            .task(id: query) {
                let text = query
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                let found = await FoodDatabase.shared.search(text)
                let mine = FoodSearch.search(text, in: library.saved)
                results = mine + found.filter { food in !mine.contains { $0.id == food.id } }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Scan Barcode", systemImage: "barcode.viewfinder") { showScanner = true }
                        .accessibilityIdentifier("scanBarcode")
                    Button("Add Your Own Food", systemImage: "plus") { showAddOwn = true }
                        .accessibilityIdentifier("addOwnFood")
                }
            }
            .navigationDestination(for: FoodItem.self) { food in
                FoodPortionView(food: food) { pick in
                    library.used(food)
                    FoodSearchTip().invalidate(reason: .actionPerformed)
                    onAdd(pick)
                    dismiss()
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeLookupView { food in
                    library.add(food)
                    showScanner = false
                    path = [food]
                }
            }
            .sheet(isPresented: $showAddOwn) {
                AddOwnFoodView { food in
                    library.add(food)
                    path = [food]
                }
            }
        }
    }

    private func row(_ food: FoodItem) -> some View {
        NavigationLink(value: food) {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let portion = food.defaultPortion {
                        Text("\(Int(food.carbs(portion: portion, amount: 1))) g carbs · \(portion.name)")
                    }
                    if food.source != .usda {
                        Text(food.source == .label ? "Label" : "Mine")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Theme.green.opacity(0.15), in: .capsule)
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.soft)
                .lineLimit(1)
            }
        }
        .accessibilityIdentifier("food.\(food.id)")
    }
}

/// Pick how much: a portion and how many of it.
struct FoodPortionView: View {
    let food: FoodItem
    let onAdd: (FoodPick) -> Void

    @State private var portion: FoodPortion
    @State private var amount = 1.0

    init(food: FoodItem, onAdd: @escaping (FoodPick) -> Void) {
        self.food = food
        self.onAdd = onAdd
        _portion = State(initialValue: food.defaultPortion ?? FoodPortion(name: "100 g", grams: 100))
    }

    private var carbs: Double { food.carbs(portion: portion, amount: amount) }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 4) {
                    Text("\(Int(carbs))")
                        .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.green)
                        .contentTransition(.numericText(value: carbs))
                    Text("grams of carbs (estimate)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.soft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
                .animation(.snappy, value: carbs)
            }
            .listRowBackground(Theme.card)

            Section {
                Picker("Portion", selection: $portion) {
                    ForEach(food.portions, id: \.self) { portion in
                        Text(portion.name).tag(portion)
                    }
                }
                Stepper(value: $amount, in: 0.5...20, step: 0.5) {
                    LabeledContent("How many", value: amount.formatted(.number.precision(.fractionLength(0...1))))
                }
            } footer: {
                Text("\(food.carbsPer100g.formatted(.number.precision(.fractionLength(0...1)))) g carbs per 100 g\(food.fiberPer100g > 0 ? String(localized: ", \(food.fiberPer100g.formatted(.number.precision(.fractionLength(0...1)))) g fiber") : "").")
            }
            .listRowBackground(Theme.card)

            Section {
                Button("Add to Meal") {
                    let label = amount == 1 ? portion.name : "\(amount.formatted(.number.precision(.fractionLength(0...1)))) × \(portion.name)"
                    onAdd(FoodPick(name: "\(food.name) (\(label))", carbs: carbs))
                }
                .buttonStyle(.soft)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("addFoodToMeal")
            }
        }
        .instrumentBackground()
        .navigationTitle(food.name)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: amount)
    }
}

/// A food the person adds themselves, e.g. from a label or a family recipe.
private struct AddOwnFoodView: View {
    let onSave: (FoodItem) -> Void
    @State private var name = ""
    @State private var carbsText = ""
    @State private var servingName = ""
    @State private var gramsText = ""

    var body: some View {
        EntryForm(
            title: "Add Your Own Food",
            canSave: !name.trimmingCharacters(in: .whitespaces).isEmpty && (parseNumber(carbsText) ?? -1) >= 0,
            hasChanges: !name.isEmpty || !carbsText.isEmpty
        ) {
            guard let carbs = parseNumber(carbsText) else { return false }
            onSave(FoodLibrary.custom(name: name, carbs: carbs, servingName: servingName, servingGrams: parseNumber(gramsText)))
            return true
        } content: {
            Section {
                TextField("Name", text: $name)
                    .accessibilityIdentifier("ownFoodName")
                NumberField(title: "Carbs per serving", prompt: "0", text: $carbsText, unit: "g")
                TextField("Serving (e.g. 1 bowl)", text: $servingName)
                NumberField(title: "Serving weight", prompt: "optional", text: $gramsText, unit: "g")
            } footer: {
                Text("Saved in My Foods on this phone.")
            }
            .listRowBackground(Theme.card)
        }
    }
}
