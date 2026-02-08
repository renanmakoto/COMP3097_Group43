//
//  AddEditItemView.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//
//  Description: Form view for adding or editing shopping items.
//  Includes fields for name, price, quantity, category, and notes.
//

import SwiftUI
import CoreData

/// AddEditItemView provides a form for creating or editing shopping items
struct AddEditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch available categories
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProductCategory.name, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<ProductCategory>

    let list: ShoppingList
    let item: ShoppingItem?

    @State private var name = ""
    @State private var price: Double = 0
    @State private var quantity: Int = 1
    @State private var selectedCategory = ""
    @State private var notes = ""

    @State private var showingValidationAlert = false

    private var isEditMode: Bool { item != nil }

    var body: some View {
        NavigationStack {
            Form {
                // Item details section
                Section("Item Details") {
                    TextField("Item Name *", text: $name)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text("$")
                        TextField("Price", value: $price, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                    }

                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                }

                // Category section
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag("")
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.iconName ?? "folder.fill")
                                    .foregroundColor(Color(hex: category.colorHex ?? "#007AFF"))
                                Text(category.name ?? "")
                            }
                            .tag(category.name ?? "")
                        }
                    }

                    // Tax indicator
                    if !selectedCategory.isEmpty {
                        let isTaxable = isCategoryTaxable(selectedCategory)
                        HStack {
                            Image(systemName: isTaxable ? "dollarsign.circle.fill" : "leaf.fill")
                                .foregroundColor(isTaxable ? .orange : .green)
                            Text(isTaxable ? "This category is taxable" : "This category is tax-exempt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Notes section
                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Price preview
                Section("Total") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(TaxCalculator.formatPrice(price * Double(quantity)))
                            .fontWeight(.semibold)
                    }
                }

                // Delete button (edit mode only)
                if isEditMode {
                    Section {
                        Button(role: .destructive) {
                            deleteItem()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Item")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveItem() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter an item name.")
            }
            .onAppear {
                loadItemData()
                createDefaultCategoriesIfNeeded()
            }
        }
    }

    // MARK: - Methods

    private func loadItemData() {
        guard let item = item else { return }
        name = item.name ?? ""
        price = item.price
        quantity = Int(item.quantity)
        selectedCategory = item.categoryName ?? ""
        notes = item.notes ?? ""
    }

    private func createDefaultCategoriesIfNeeded() {
        guard categories.isEmpty else { return }

        let defaults: [(name: String, color: String, icon: String, taxable: Bool)] = [
            ("Food", "#4CAF50", "cart.fill", false),
            ("Medication", "#F44336", "pills.fill", false),
            ("Cleaning", "#2196F3", "sparkles", true),
            ("Electronics", "#9C27B0", "bolt.fill", true),
            ("Clothing", "#FF9800", "tshirt.fill", true),
            ("Household", "#795548", "house.fill", true)
        ]

        for item in defaults {
            let category = ProductCategory(context: viewContext)
            category.id = UUID()
            category.name = item.name
            category.colorHex = item.color
            category.iconName = item.icon
            category.isTaxable = item.taxable
        }

        PersistenceController.shared.save()
    }

    private func isCategoryTaxable(_ categoryName: String) -> Bool {
        let exemptCategories = ["Food", "Medication", "Basic Groceries", "Prescription Medication"]
        return !exemptCategories.contains(categoryName)
    }

    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showingValidationAlert = true
            return
        }

        let itemToSave = item ?? ShoppingItem(context: viewContext)

        if item == nil {
            itemToSave.id = UUID()
            itemToSave.list = list
        }

        itemToSave.name = trimmedName
        itemToSave.price = price
        itemToSave.quantity = Int16(quantity)
        itemToSave.categoryName = selectedCategory.isEmpty ? nil : selectedCategory
        itemToSave.notes = notes.isEmpty ? nil : notes

        PersistenceController.shared.save()
        dismiss()
    }

    private func deleteItem() {
        guard let item = item else { return }
        viewContext.delete(item)
        PersistenceController.shared.save()
        dismiss()
    }
}

/// Color extension for hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let list = ShoppingList(context: context)
    list.id = UUID()
    list.name = "Test"

    return AddEditItemView(list: list, item: nil)
        .environment(\.managedObjectContext, context)
}
