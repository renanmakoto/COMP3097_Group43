//
//  ShoppingListsView.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//
//  Description: Main shopping lists view displaying all shopping lists.
//  Users can create, edit, and delete shopping lists with budget tracking.
//

import SwiftUI
import CoreData

/// ShoppingListsView displays all shopping lists with management options
struct ShoppingListsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch all shopping lists sorted by creation date
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingList.createdAt, ascending: false)],
        animation: .default)
    private var lists: FetchedResults<ShoppingList>

    @State private var showingAddList = false
    @State private var selectedList: ShoppingList?

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("My Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddList = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddList) {
                AddEditListView(list: nil)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Shopping Lists")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap + to create your first list")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var listView: some View {
        List {
            ForEach(lists) { list in
                NavigationLink(destination: ShoppingListDetailView(list: list)) {
                    ShoppingListRowView(list: list)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteList(list)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Methods

    private func deleteList(_ list: ShoppingList) {
        withAnimation {
            viewContext.delete(list)
            PersistenceController.shared.save()
        }
    }
}

/// Row view for displaying a single shopping list
struct ShoppingListRowView: View {
    @ObservedObject var list: ShoppingList

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(list.name ?? "Untitled List")
                    .font(.headline)

                Spacer()

                // Item count badge
                Text("\(itemCount) items")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }

            HStack {
                // Progress indicator
                if itemCount > 0 {
                    ProgressView(value: Double(purchasedCount), total: Double(itemCount))
                        .tint(.green)
                }

                Spacer()

                // Budget info
                if list.budget > 0 {
                    Text(TaxCalculator.formatPrice(list.budget))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Total spent
            HStack {
                Text("Total: \(TaxCalculator.formatPrice(totalSpent))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if list.budget > 0 {
                    Spacer()
                    let remaining = list.budget - totalSpent
                    Text(remaining >= 0 ? "Remaining: \(TaxCalculator.formatPrice(remaining))" : "Over budget!")
                        .font(.caption)
                        .foregroundColor(remaining >= 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // Computed properties
    private var items: [ShoppingItem] {
        (list.items?.allObjects as? [ShoppingItem]) ?? []
    }

    private var itemCount: Int {
        items.count
    }

    private var purchasedCount: Int {
        items.filter { $0.isPurchased }.count
    }

    private var totalSpent: Double {
        items.filter { $0.isPurchased }.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
}

/// View for adding or editing a shopping list
struct AddEditListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    let list: ShoppingList?

    @State private var name = ""
    @State private var budget: Double = 0
    @State private var hasBudget = false

    private var isEditMode: Bool { list != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("List Details") {
                    TextField("List Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Budget (Optional)") {
                    Toggle("Set Budget", isOn: $hasBudget.animation())

                    if hasBudget {
                        HStack {
                            Text("$")
                            TextField("0.00", value: $budget, format: .number)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit List" : "New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveList() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                loadListData()
            }
        }
    }

    private func loadListData() {
        guard let list = list else { return }
        name = list.name ?? ""
        if list.budget > 0 {
            hasBudget = true
            budget = list.budget
        }
    }

    private func saveList() {
        let listToSave = list ?? ShoppingList(context: viewContext)

        if list == nil {
            listToSave.id = UUID()
            listToSave.createdAt = Date()
        }

        listToSave.name = name.trimmingCharacters(in: .whitespaces)
        listToSave.budget = hasBudget ? budget : 0

        PersistenceController.shared.save()
        dismiss()
    }
}

#Preview {
    ShoppingListsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
