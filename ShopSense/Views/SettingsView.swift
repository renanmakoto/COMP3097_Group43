//
//  SettingsView.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//
//  Description: Settings screen for app preferences and information.
//  Includes province selection, display options, and app information.
//

import SwiftUI
import CoreData

/// SettingsView provides app settings and information
struct SettingsView: View {
    @AppStorage("selectedProvince") private var selectedProvince = "Ontario"
    @AppStorage("showPurchasedItems") private var showPurchasedItems = true
    @AppStorage("defaultBudget") private var defaultBudget: Double = 0

    @State private var showingResetAlert = false
    @State private var showingAboutSheet = false

    var body: some View {
        NavigationStack {
            List {
                // Tax Settings
                Section("Tax Settings") {
                    Picker("Province", selection: $selectedProvince) {
                        ForEach(TaxCalculator.Province.allCases) { province in
                            Text(province.rawValue).tag(province.rawValue)
                        }
                    }

                    let province = TaxCalculator.Province(rawValue: selectedProvince) ?? .ontario
                    HStack {
                        Text("Tax Rate")
                        Spacer()
                        Text(province.taxDescription)
                            .foregroundColor(.secondary)
                    }
                }

                // Display Settings
                Section("Display") {
                    Toggle("Show Purchased Items", isOn: $showPurchasedItems)

                    HStack {
                        Text("Default Budget")
                        Spacer()
                        TextField("0", value: $defaultBudget, format: .currency(code: "CAD"))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }

                // Data Section
                Section("Data") {
                    Button("Export All Lists") {
                        exportLists()
                    }

                    Button("Reset All Data", role: .destructive) {
                        showingResetAlert = true
                    }
                }

                // About Section
                Section("About") {
                    Button("About ShopSense") {
                        showingAboutSheet = true
                    }
                    .foregroundColor(.primary)

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Target Device")
                        Spacer()
                        Text("iPhone 15 Pro")
                            .foregroundColor(.secondary)
                    }
                }

                // Team Information
                Section("Development Team") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COMP3097 - Mobile App Development II")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Team Members:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)

                        Text("• Renan Yoshida Avelan - 101536279")
                            .font(.caption)
                        Text("• Lucas Tavares Criscuolo - 101500671")
                            .font(.caption)
                        Text("• Gustavo Miranda - 101488574")
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will delete all shopping lists and categories. This action cannot be undone.")
            }
            .sheet(isPresented: $showingAboutSheet) {
                AboutView()
            }
        }
    }

    private func exportLists() {
        // Placeholder for export functionality
        print("Export lists functionality")
    }

    private func resetAllData() {
        let context = PersistenceController.shared.container.viewContext

        let listRequest: NSFetchRequest<NSFetchRequestResult> = ShoppingList.fetchRequest()
        let listDelete = NSBatchDeleteRequest(fetchRequest: listRequest)

        let itemRequest: NSFetchRequest<NSFetchRequestResult> = ShoppingItem.fetchRequest()
        let itemDelete = NSBatchDeleteRequest(fetchRequest: itemRequest)

        let categoryRequest: NSFetchRequest<NSFetchRequestResult> = ProductCategory.fetchRequest()
        let categoryDelete = NSBatchDeleteRequest(fetchRequest: categoryRequest)

        do {
            try context.execute(listDelete)
            try context.execute(itemDelete)
            try context.execute(categoryDelete)
            try context.save()
        } catch {
            print("Error resetting data: \(error)")
        }
    }
}

/// About screen
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon and name
                    VStack(spacing: 12) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)

                        Text("ShopSense")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Shopping List with Tax Calculator")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)

                        Text("ShopSense helps you manage your shopping lists with built-in Canadian tax calculations. Organize items by category, track your budget, and never overspend again.")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Text("Features:")
                            .font(.headline)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "list.bullet.clipboard", text: "Multiple shopping lists")
                            FeatureRow(icon: "percent", text: "Canadian tax calculator")
                            FeatureRow(icon: "folder.fill", text: "Custom product categories")
                            FeatureRow(icon: "dollarsign.circle", text: "Budget tracking")
                            FeatureRow(icon: "checkmark.circle", text: "Mark items as purchased")
                            FeatureRow(icon: "icloud.fill", text: "Persistent Core Data storage")
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    VStack(spacing: 4) {
                        Text("COMP3097 - Mobile App Development II")
                            .font(.caption)
                        Text("George Brown College - Winter 2026")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    SettingsView()
}
