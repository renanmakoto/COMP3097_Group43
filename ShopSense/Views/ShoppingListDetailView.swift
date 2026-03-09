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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProductCategory.name, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<ProductCategory>

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
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    TaxBreakdownReportView(list: list)
                } label: {
                    Label("Tax Report", systemImage: "doc.text.magnifyingglass")
                }
            }
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
                        ShoppingItemRowView(
                            item: item,
                            taxCalculator: taxCalculator,
                            isTaxable: isCategoryTaxable(item.categoryName)
                        )
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
        CategoryDefaults.isTaxable(
            categoryName: categoryName,
            categories: Array(categories)
        )
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
    let isTaxable: Bool

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
}

struct TaxBreakdownReportView: View {
    @ObservedObject var list: ShoppingList

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProductCategory.name, ascending: true)],
        animation: .default
    )
    private var categories: FetchedResults<ProductCategory>

    @AppStorage("selectedProvince") private var selectedProvince = "Ontario"
    @State private var comparisonProvince = TaxCalculator.Province.alberta.rawValue

    private var items: [ShoppingItem] {
        (list.items?.allObjects as? [ShoppingItem]) ?? []
    }

    private var currentProvince: TaxCalculator.Province {
        TaxCalculator.Province(rawValue: selectedProvince) ?? .ontario
    }

    private var compareProvince: TaxCalculator.Province {
        TaxCalculator.Province(rawValue: comparisonProvince) ?? .alberta
    }

    private var currentCalculator: TaxCalculator {
        TaxCalculator(province: currentProvince)
    }

    private var compareCalculator: TaxCalculator {
        TaxCalculator(province: compareProvince)
    }

    private var taxableSubtotal: Double {
        items
            .filter { isCategoryTaxable($0.categoryName) }
            .reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    private var taxExemptSubtotal: Double {
        items
            .filter { !isCategoryTaxable($0.categoryName) }
            .reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }

    private var currentTax: Double {
        currentCalculator.calculateTax(subtotal: taxableSubtotal, isTaxable: true)
    }

    private var currentTotal: Double {
        taxableSubtotal + taxExemptSubtotal + currentTax
    }

    private var taxSavedFromExemptItems: Double {
        currentCalculator.calculateTax(subtotal: taxExemptSubtotal, isTaxable: true)
    }

    private var compareTax: Double {
        compareCalculator.calculateTax(subtotal: taxableSubtotal, isTaxable: true)
    }

    private var compareTotal: Double {
        taxableSubtotal + taxExemptSubtotal + compareTax
    }

    private var totalDifference: Double {
        compareTotal - currentTotal
    }

    private var categoryRows: [CategoryTaxRowData] {
        let grouped = Dictionary(grouping: items) { item in
            let name = item.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.isEmpty ? "Uncategorized" : name
        }

        return grouped
            .map { key, values in
                let subtotal = values.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
                let taxable = isCategoryTaxable(key)
                let tax = currentCalculator.calculateTax(subtotal: subtotal, isTaxable: taxable)
                return CategoryTaxRowData(
                    categoryName: key,
                    subtotal: subtotal,
                    isTaxable: taxable,
                    taxAmount: tax
                )
            }
            .sorted { $0.categoryName < $1.categoryName }
    }

    var body: some View {
        List {
            if items.isEmpty {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "cart")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("No Items In This List")
                            .font(.headline)
                        Text("Add items to generate a tax breakdown report.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                }
            } else {
                Section("Overview") {
                    LabeledContent("Province") {
                        Text(currentProvince.rawValue)
                    }
                    LabeledContent("Tax Rule") {
                        Text(currentProvince.taxDescription)
                    }
                    LabeledContent("Taxable Subtotal") {
                        Text(TaxCalculator.formatPrice(taxableSubtotal))
                    }
                    LabeledContent("Tax-Exempt Subtotal") {
                        Text(TaxCalculator.formatPrice(taxExemptSubtotal))
                    }
                    LabeledContent("Tax Amount") {
                        Text(TaxCalculator.formatPrice(currentTax))
                            .foregroundColor(.orange)
                    }
                    LabeledContent("Grand Total") {
                        Text(TaxCalculator.formatPrice(currentTotal))
                            .fontWeight(.semibold)
                    }
                    LabeledContent("Tax Saved (Exempt)") {
                        Text(TaxCalculator.formatPrice(taxSavedFromExemptItems))
                            .foregroundColor(.green)
                    }
                }

                Section("By Category") {
                    ForEach(categoryRows) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(row.categoryName)
                                    .font(.headline)
                                Spacer()
                                Text(row.isTaxable ? "Taxable" : "Tax-Exempt")
                                    .font(.caption)
                                    .foregroundColor(row.isTaxable ? .orange : .green)
                            }

                            HStack {
                                Text("Subtotal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(TaxCalculator.formatPrice(row.subtotal))
                                    .font(.caption)
                            }

                            HStack {
                                Text("Tax")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(TaxCalculator.formatPrice(row.taxAmount))
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Province Comparison") {
                    Picker("Compare With", selection: $comparisonProvince) {
                        ForEach(TaxCalculator.Province.allCases) { province in
                            Text(province.rawValue).tag(province.rawValue)
                        }
                    }
                    .pickerStyle(.menu)

                    LabeledContent("Current Total (\(currentProvince.rawValue))") {
                        Text(TaxCalculator.formatPrice(currentTotal))
                    }
                    LabeledContent("Compared Total (\(compareProvince.rawValue))") {
                        Text(TaxCalculator.formatPrice(compareTotal))
                    }
                    LabeledContent("Difference") {
                        Text(
                            totalDifference >= 0
                                ? "+\(TaxCalculator.formatPrice(totalDifference))"
                                : "-\(TaxCalculator.formatPrice(abs(totalDifference)))"
                        )
                        .foregroundColor(totalDifference >= 0 ? .orange : .green)
                    }
                }
            }
        }
        .navigationTitle("Tax Breakdown")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isCategoryTaxable(_ categoryName: String?) -> Bool {
        CategoryDefaults.isTaxable(
            categoryName: categoryName,
            categories: Array(categories)
        )
    }
}

struct CategoryTaxRowData: Identifiable {
    let id = UUID()
    let categoryName: String
    let subtotal: Double
    let isTaxable: Bool
    let taxAmount: Double
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
