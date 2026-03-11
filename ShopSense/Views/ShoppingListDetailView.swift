//
//  ShoppingListDetailView.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//
//  Description: Detailed view for a single shopping list showing all items.
//  Displays items grouped by category with tax calculations and budget tracking.
//

import SwiftUI
import CoreData

/// ShoppingListDetailView displays items in a shopping list with tax calculations
struct ShoppingListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var list: ShoppingList

    @AppStorage("selectedProvince") private var selectedProvince = "Ontario"

    @State private var showingAddItem = false
    @State private var selectedItem: ShoppingItem?

    // Tax calculator instance
    private var taxCalculator: TaxCalculator {
        TaxCalculator(province: TaxCalculator.Province(rawValue: selectedProvince) ?? .ontario)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary card
            summaryCard

            // Items list
            if items.isEmpty {
                emptyStateView
            } else {
                itemsList
            }
        }
        .navigationTitle(list.name ?? "Shopping List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddEditItemView(list: list, item: nil)
        }
        .sheet(item: $selectedItem) { item in
            AddEditItemView(list: list, item: item)
        }
    }

    // MARK: - Subviews

    private var summaryCard: some View {
        VStack(spacing: 12) {
            // Progress bar
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(purchasedCount)/\(items.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(Double(purchasedCount) / Double(items.count) * 100))%")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    ProgressView(value: Double(purchasedCount), total: Double(items.count))
                        .tint(.green)
                }
            }

            Divider()

            // Price breakdown
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subtotal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(TaxCalculator.formatPrice(subtotal))
                        .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Tax (\(taxCalculator.province.taxDescription))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(TaxCalculator.formatPrice(taxAmount))
                        .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(TaxCalculator.formatPrice(total))
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }

            // Budget warning
            if list.budget > 0 {
                Divider()
                let remaining = list.budget - total
                HStack {
                    Text("Budget: \(TaxCalculator.formatPrice(list.budget))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(remaining >= 0 ? "Remaining: \(TaxCalculator.formatPrice(remaining))" : "Over by: \(TaxCalculator.formatPrice(abs(remaining)))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(remaining >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "cart")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Items")
                .font(.headline)
            Text("Tap + to add items to your list")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var itemsList: some View {
        List {
            // Group items by category
            ForEach(groupedItems.keys.sorted(), id: \.self) { category in
                Section(header: Text(category)) {
                    ForEach(groupedItems[category] ?? []) { item in
                        ShoppingItemRowView(item: item, taxCalculator: taxCalculator)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItem = item
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    togglePurchased(item)
                                } label: {
                                    Label(item.isPurchased ? "Undo" : "Purchased", systemImage: item.isPurchased ? "arrow.uturn.backward" : "checkmark")
                                }
                                .tint(item.isPurchased ? .orange : .green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Computed Properties

    private var items: [ShoppingItem] {
        (list.items?.allObjects as? [ShoppingItem]) ?? []
    }

    private var groupedItems: [String: [ShoppingItem]] {
        Dictionary(grouping: items) { $0.categoryName ?? "Uncategorized" }
    }

    private var purchasedCount: Int {
        items.filter { $0.isPurchased }.count
    }

    private var subtotal: Double {
        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    private var taxAmount: Double {
        items.reduce(0) { total, item in
            let itemTotal = item.price * Double(item.quantity)
            let isTaxable = isCategoryTaxable(item.categoryName)
            return total + taxCalculator.calculateTax(subtotal: itemTotal, isTaxable: isTaxable)
        }
    }

    private var total: Double {
        subtotal + taxAmount
    }

    // MARK: - Helper Methods

    private func isCategoryTaxable(_ categoryName: String?) -> Bool {
        guard let name = categoryName else { return true }
        // Food and medication are typically tax-exempt in Canada
        let exemptCategories = ["Food", "Medication", "Basic Groceries", "Prescription Medication"]
        return !exemptCategories.contains(name)
    }

    private func togglePurchased(_ item: ShoppingItem) {
        withAnimation {
            item.isPurchased.toggle()
            PersistenceController.shared.save()
        }
    }

    private func deleteItem(_ item: ShoppingItem) {
        withAnimation {
            viewContext.delete(item)
            PersistenceController.shared.save()
        }
    }
}

/// Row view for a single shopping item
struct ShoppingItemRowView: View {
    @ObservedObject var item: ShoppingItem
    let taxCalculator: TaxCalculator

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(item.isPurchased ? .green : .gray)

            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Unnamed Item")
                    .font(.headline)
                    .strikethrough(item.isPurchased)
                    .foregroundColor(item.isPurchased ? .secondary : .primary)

                HStack {
                    Text("Qty: \(item.quantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let notes = item.notes, !notes.isEmpty {
                        Text("• \(notes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Price
            VStack(alignment: .trailing, spacing: 2) {
                Text(TaxCalculator.formatPrice(item.price * Double(item.quantity)))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if isTaxable {
                    Text("+tax")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(item.isPurchased ? 0.7 : 1.0)
    }

    private var isTaxable: Bool {
        guard let category = item.categoryName else { return true }
        let exemptCategories = ["Food", "Medication", "Basic Groceries", "Prescription Medication"]
        return !exemptCategories.contains(category)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let list = ShoppingList(context: context)
    list.id = UUID()
    list.name = "Test List"
    list.budget = 100

    return NavigationStack {
        ShoppingListDetailView(list: list)
    }
    .environment(\.managedObjectContext, context)
}
