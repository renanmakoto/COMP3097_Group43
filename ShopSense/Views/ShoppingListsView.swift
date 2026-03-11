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
    @State private var showingTemplates = false

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingTemplates = true
                    } label: {
                        Label("Templates", systemImage: "doc.on.doc")
                    }
                }
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
            .sheet(item: $selectedList) { list in
                AddEditListView(list: list)
            }
            .sheet(isPresented: $showingTemplates) {
                ListTemplateManagerView { template in
                    createListFromTemplate(template)
                }
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
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        selectedList = list
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
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

    private func createListFromTemplate(_ template: ListTemplate) {
        let newList = ShoppingList(context: viewContext)
        newList.id = UUID()
        newList.createdAt = Date()
        newList.name = template.name.trimmingCharacters(in: .whitespacesAndNewlines)
        newList.budget = max(0, template.budget)

        for templateItem in template.items {
            let item = ShoppingItem(context: viewContext)
            item.id = UUID()
            item.list = newList
            item.name = templateItem.name.trimmingCharacters(in: .whitespacesAndNewlines)
            item.price = max(0, templateItem.price)
            item.quantity = Int16(max(1, templateItem.quantity))
            item.categoryName = templateItem.categoryName.isEmpty ? nil : templateItem.categoryName
            item.isPurchased = false
        }

        PersistenceController.shared.save()
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
    @State private var showingValidationAlert = false

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
                        .disabled(
                            name.trimmingCharacters(in: .whitespaces).isEmpty ||
                            (hasBudget && budget < 0)
                        )
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Budget cannot be negative.")
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
        guard !hasBudget || budget >= 0 else {
            showingValidationAlert = true
            return
        }

        let listToSave = list ?? ShoppingList(context: viewContext)

        if list == nil {
            listToSave.id = UUID()
            listToSave.createdAt = Date()
        }

        listToSave.name = name.trimmingCharacters(in: .whitespaces)
        listToSave.budget = hasBudget ? max(0, budget) : 0

        PersistenceController.shared.save()
        dismiss()
    }
}

struct ListTemplate: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var budget: Double
    var items: [ListTemplateItem]
}

struct ListTemplateItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var price: Double
    var quantity: Int
    var categoryName: String
}

enum ListTemplateStore {
    private static let storageKey = "shopsense.list.templates.v1"

    static func load() -> [ListTemplate] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let templates = try? JSONDecoder().decode([ListTemplate].self, from: data)
        else {
            return []
        }
        return templates
    }

    static func save(_ templates: [ListTemplate]) {
        guard let data = try? JSONEncoder().encode(templates) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

struct ListTemplateManagerView: View {
    @Environment(\.dismiss) private var dismiss

    let onApplyTemplate: (ListTemplate) -> Void

    @State private var templates: [ListTemplate] = ListTemplateStore.load()
    @State private var showingCreateTemplate = false
    @State private var editingTemplate: ListTemplate?

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Templates")
                            .font(.headline)
                        Text("Create a reusable shopping template with budget and items.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(templates) { template in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(template.name)
                                        .font(.headline)
                                    Text("\(template.items.count) items")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if template.budget > 0 {
                                        Text("Budget: \(TaxCalculator.formatPrice(template.budget))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Button("Use") {
                                    onApplyTemplate(template)
                                    dismiss()
                                }
                                .buttonStyle(.borderedProminent)
                                .font(.caption)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingTemplate = template
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteTemplate(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("List Templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showingCreateTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                ListTemplateEditorView(template: nil) { created in
                    templates.append(created)
                    persistTemplates()
                }
            }
            .sheet(item: $editingTemplate) { template in
                ListTemplateEditorView(template: template) { updated in
                    if let index = templates.firstIndex(where: { $0.id == updated.id }) {
                        templates[index] = updated
                        persistTemplates()
                    }
                }
            }
        }
    }

    private func deleteTemplate(_ template: ListTemplate) {
        templates.removeAll { $0.id == template.id }
        persistTemplates()
    }

    private func persistTemplates() {
        ListTemplateStore.save(templates)
    }
}

struct ListTemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let template: ListTemplate?
    let onSave: (ListTemplate) -> Void

    @State private var name = ""
    @State private var budget: Double = 0
    @State private var hasBudget = false
    @State private var items: [ListTemplateItem] = []

    @State private var showingAddItem = false
    @State private var editingItem: ListTemplateItem?
    @State private var showingValidationAlert = false
    @State private var validationMessage = "Template name is required."

    private var isEditMode: Bool {
        template != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template") {
                    TextField("Template Name", text: $name)
                        .textInputAutocapitalization(.words)

                    Toggle("Set Budget", isOn: $hasBudget.animation())

                    if hasBudget {
                        HStack {
                            Text("$")
                            TextField("0.00", value: $budget, format: .number)
                                .keyboardType(.decimalPad)
                        }
                    }
                }

                Section("Items") {
                    if items.isEmpty {
                        Text("Add at least one item to make this template useful.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.subheadline)
                                Text("Qty \(item.quantity) • \(TaxCalculator.formatPrice(item.price)) • \(item.categoryName.isEmpty ? "Uncategorized" : item.categoryName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingItem = item
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

                    Button {
                        showingAddItem = true
                    } label: {
                        Label("Add Template Item", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .sheet(isPresented: $showingAddItem) {
                ListTemplateItemEditorView(item: nil) { newItem in
                    items.append(newItem)
                }
            }
            .sheet(item: $editingItem) { item in
                ListTemplateItemEditorView(item: item) { updatedItem in
                    if let index = items.firstIndex(where: { $0.id == updatedItem.id }) {
                        items[index] = updatedItem
                    }
                }
            }
            .onAppear {
                loadTemplate()
            }
        }
    }

    private func loadTemplate() {
        guard let template else { return }
        name = template.name
        items = template.items
        if template.budget > 0 {
            hasBudget = true
            budget = template.budget
        }
    }

    private func saveTemplate() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationMessage = "Template name is required."
            showingValidationAlert = true
            return
        }

        guard !items.isEmpty else {
            validationMessage = "Add at least one item before saving a template."
            showingValidationAlert = true
            return
        }

        guard !hasBudget || budget >= 0 else {
            validationMessage = "Budget cannot be negative."
            showingValidationAlert = true
            return
        }

        let result = ListTemplate(
            id: template?.id ?? UUID(),
            name: trimmedName,
            budget: hasBudget ? max(0, budget) : 0,
            items: items
        )

        onSave(result)
        dismiss()
    }

    private func deleteItem(_ item: ListTemplateItem) {
        items.removeAll { $0.id == item.id }
    }
}

struct ListTemplateItemEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let item: ListTemplateItem?
    let onSave: (ListTemplateItem) -> Void

    @State private var name = ""
    @State private var price: Double = 0
    @State private var quantity = 1
    @State private var categoryName = ""

    @State private var showingValidationAlert = false
    @State private var validationMessage = "Item name is required."

    private let categoryOptions = CategoryDefaults.definitions.map { $0.name }

    private var isEditMode: Bool {
        item != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text("$")
                        TextField("Price", value: $price, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                    }

                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                }

                Section("Category") {
                    Picker("Quick Select", selection: $categoryName) {
                        Text("None").tag("")
                        ForEach(categoryOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Or enter custom category", text: $categoryName)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle(isEditMode ? "Edit Template Item" : "New Template Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                }
            }
            .alert("Validation Error", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                loadItem()
            }
        }
    }

    private func loadItem() {
        guard let item else { return }
        name = item.name
        price = item.price
        quantity = item.quantity
        categoryName = item.categoryName
    }

    private func saveItem() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = "Item name is required."
            showingValidationAlert = true
            return
        }

        guard price >= 0 else {
            validationMessage = "Price cannot be negative."
            showingValidationAlert = true
            return
        }

        guard quantity > 0 else {
            validationMessage = "Quantity must be at least 1."
            showingValidationAlert = true
            return
        }

        let result = ListTemplateItem(
            id: item?.id ?? UUID(),
            name: trimmedName,
            price: price,
            quantity: quantity,
            categoryName: trimmedCategory
        )

        onSave(result)
        dismiss()
    }
}

#Preview {
    ShoppingListsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
