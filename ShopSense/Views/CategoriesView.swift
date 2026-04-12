//
//  Internal Documentation Header (COMP3097 Final)
//  File: CategoriesView.swift
//  Author: Lucas Tavares Criscuolo (101500671, CRN: 54621)
//  Editors:
//    - Renan Yoshida Avelan (101536279): reviewed header compliance and category defaults notes.
//    - Gustavo Miranda (101488574): reviewed header compliance and list-category integration notes.
//  External/AI References: NOT USED
//  Description: Category management for custom names, icons, colors, and taxable flags.
//

//
//  CategoriesView.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//
//  Description: View for managing product categories.
//  Users can create custom categories with colors, icons, and tax settings.
//

import SwiftUI
import CoreData

/// CategoriesView manages product categories for shopping items
struct CategoriesView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProductCategory.name, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<ProductCategory>

    @State private var showingAddCategory = false
    @State private var editingCategory: ProductCategory?

    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    emptyStateView
                } else {
                    categoryList
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddEditCategoryView(category: nil)
            }
            .sheet(item: $editingCategory) { category in
                AddEditCategoryView(category: category)
            }
            .onAppear {
                CategoryDefaults.seedIfNeeded(in: viewContext)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Categories")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap + to create your first category")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var categoryList: some View {
        List {
            // Tax-exempt categories
            Section(header: Text("Tax-Exempt")) {
                ForEach(categories.filter { !$0.isTaxable }) { category in
                    CategoryRowView(category: category)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = category
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteCategory(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }

            // Taxable categories
            Section(header: Text("Taxable")) {
                ForEach(categories.filter { $0.isTaxable }) { category in
                    CategoryRowView(category: category)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = category
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteCategory(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Methods

    private func deleteCategory(_ category: ProductCategory) {
        let deletedName = (category.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        withAnimation {
            _ = ensureUncategorizedExists(excluding: category)
            if !deletedName.isEmpty {
                _ = reassignItems(from: deletedName, to: "Uncategorized")
            }

            viewContext.delete(category)
            PersistenceController.shared.save()
        }
    }

    private func ensureUncategorizedExists(excluding categoryBeingDeleted: ProductCategory?) -> ProductCategory {
        let request: NSFetchRequest<ProductCategory> = ProductCategory.fetchRequest()
        request.predicate = NSPredicate(format: "name =[c] %@", "Uncategorized")

        do {
            let matches = try viewContext.fetch(request)
            if let existing = matches.first(where: { $0.objectID != categoryBeingDeleted?.objectID }) {
                return existing
            }
        } catch {
            print("Error checking Uncategorized category: \(error)")
        }

        let fallback = ProductCategory(context: viewContext)
        fallback.id = UUID()
        fallback.name = "Uncategorized"
        fallback.colorHex = "#9E9E9E"
        fallback.iconName = "tray.fill"
        fallback.isTaxable = true
        return fallback
    }

    private func reassignItems(from sourceCategory: String, to targetCategory: String) -> Int {
        let request: NSFetchRequest<ShoppingItem> = ShoppingItem.fetchRequest()
        request.predicate = NSPredicate(format: "categoryName == %@", sourceCategory)

        do {
            let items = try viewContext.fetch(request)
            for item in items {
                item.categoryName = targetCategory
            }
            return items.count
        } catch {
            print("Error reassigning items for deleted category: \(error)")
            return 0
        }
    }
}

/// Row view for a single category
struct CategoryRowView: View {
    @ObservedObject var category: ProductCategory

    var body: some View {
        HStack(spacing: 12) {
            // Icon with background
            Image(systemName: category.iconName ?? "folder.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color(hex: category.colorHex ?? "#007AFF"))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name ?? "Unnamed")
                    .font(.headline)

                Text(category.isTaxable ? "Taxable" : "Tax-exempt")
                    .font(.caption)
                    .foregroundColor(category.isTaxable ? .orange : .green)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

/// View for adding or editing a category
struct AddEditCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    let category: ProductCategory?

    @State private var name = ""
    @State private var selectedColor = "#4CAF50"
    @State private var selectedIcon = "folder.fill"
    @State private var isTaxable = true
    @State private var originalName = ""
    @State private var activeAlert: CategoryAlert?

    private var isEditMode: Bool { category != nil }

    private let colors = [
        "#4CAF50", "#F44336", "#2196F3", "#9C27B0", "#FF9800",
        "#795548", "#607D8B", "#E91E63", "#00BCD4", "#8BC34A",
        "#FF5722", "#3F51B5", "#009688", "#FFEB3B", "#673AB7"
    ]

    private let icons = [
        "folder.fill", "cart.fill", "pills.fill", "sparkles", "bolt.fill",
        "tshirt.fill", "house.fill", "gift.fill", "leaf.fill", "drop.fill",
        "flame.fill", "snowflake", "star.fill", "heart.fill", "bag.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Name") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Tax Setting") {
                    Toggle("Taxable", isOn: $isTaxable)

                    Text(isTaxable ? "Items in this category will have tax applied" : "Items in this category are tax-exempt (e.g., basic groceries, medication)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture { selectedColor = color }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(selectedIcon == icon ? .white : Color(hex: selectedColor))
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color(hex: selectedColor) : Color(hex: selectedColor).opacity(0.1))
                                .cornerRadius(10)
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Preview") {
                    HStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: selectedColor))
                            .cornerRadius(10)

                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "Category Name" : name)
                                .font(.headline)
                            Text(isTaxable ? "Taxable" : "Tax-exempt")
                                .font(.caption)
                                .foregroundColor(isTaxable ? .orange : .green)
                        }
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCategory() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                loadCategoryData()
            }
            .alert(item: $activeAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK")) {
                        if alert.dismissAfterAcknowledgement {
                            dismiss()
                        }
                    }
                )
            }
        }
    }

    private func loadCategoryData() {
        guard let category = category else { return }
        name = category.name ?? ""
        originalName = category.name ?? ""
        selectedColor = category.colorHex ?? "#4CAF50"
        selectedIcon = category.iconName ?? "folder.fill"
        isTaxable = category.isTaxable
    }

    private func saveCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if hasDuplicateCategoryName(trimmedName) {
            activeAlert = CategoryAlert(
                title: "Duplicate Category Name",
                message: "A category named \"\(trimmedName)\" already exists. Please choose a different name.",
                dismissAfterAcknowledgement: false
            )
            return
        }

        let categoryToSave = category ?? ProductCategory(context: viewContext)

        if category == nil {
            categoryToSave.id = UUID()
        }

        let previousName = originalName.trimmingCharacters(in: .whitespacesAndNewlines)
        categoryToSave.name = trimmedName
        categoryToSave.colorHex = selectedColor
        categoryToSave.iconName = selectedIcon
        categoryToSave.isTaxable = isTaxable

        // Keep item-category linkage stable when a category name changes.
        var renamedItemCount = 0
        if isEditMode && !previousName.isEmpty && previousName != trimmedName {
            renamedItemCount = migrateItemCategoryNames(from: previousName, to: trimmedName)
        }

        PersistenceController.shared.save()

        if renamedItemCount > 0 {
            activeAlert = CategoryAlert(
                title: "Items Updated",
                message: "\(renamedItemCount) item\(renamedItemCount == 1 ? " was" : "s were") updated to \"\(trimmedName)\".",
                dismissAfterAcknowledgement: true
            )
        } else {
            dismiss()
        }
    }

    private func hasDuplicateCategoryName(_ candidateName: String) -> Bool {
        let request: NSFetchRequest<ProductCategory> = ProductCategory.fetchRequest()
        request.predicate = NSPredicate(format: "name =[c] %@", candidateName)

        do {
            let matches = try viewContext.fetch(request)
            if let category {
                return matches.contains { $0.objectID != category.objectID }
            }
            return !matches.isEmpty
        } catch {
            print("Error validating duplicate category names: \(error)")
            return false
        }
    }

    private func migrateItemCategoryNames(from oldName: String, to newName: String) -> Int {
        let request: NSFetchRequest<ShoppingItem> = ShoppingItem.fetchRequest()
        request.predicate = NSPredicate(format: "categoryName == %@", oldName)

        do {
            let items = try viewContext.fetch(request)
            for item in items {
                item.categoryName = newName
            }
            return items.count
        } catch {
            print("Error updating item categories after rename: \(error)")
            return 0
        }
    }
}

private struct CategoryAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let dismissAfterAcknowledgement: Bool
}

#Preview {
    CategoriesView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
