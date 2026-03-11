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
                createDefaultCategoriesIfNeeded()
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

    private func deleteCategory(_ category: ProductCategory) {
        withAnimation {
            viewContext.delete(category)
            PersistenceController.shared.save()
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
        }
    }

    private func loadCategoryData() {
        guard let category = category else { return }
        name = category.name ?? ""
        selectedColor = category.colorHex ?? "#4CAF50"
        selectedIcon = category.iconName ?? "folder.fill"
        isTaxable = category.isTaxable
    }

    private func saveCategory() {
        let categoryToSave = category ?? ProductCategory(context: viewContext)

        if category == nil {
            categoryToSave.id = UUID()
        }

        categoryToSave.name = name.trimmingCharacters(in: .whitespaces)
        categoryToSave.colorHex = selectedColor
        categoryToSave.iconName = selectedIcon
        categoryToSave.isTaxable = isTaxable

        PersistenceController.shared.save()
        dismiss()
    }
}

#Preview {
    CategoriesView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
