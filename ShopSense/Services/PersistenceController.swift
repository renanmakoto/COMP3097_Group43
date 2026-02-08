//
//  PersistenceController.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//
//  Description: Core Data persistence controller that manages the Core Data stack.
//  Handles saving, loading, and managing shopping list data in persistent storage.
//

import CoreData

/// PersistenceController manages Core Data stack for the ShopSense application
struct PersistenceController {
    // Shared singleton instance used throughout the application
    static let shared = PersistenceController()

    // Preview instance with in-memory store for SwiftUI previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample product categories for preview
        let categories = [
            ("Food", "#4CAF50", "cart.fill", false),
            ("Medication", "#F44336", "pills.fill", false),
            ("Cleaning", "#2196F3", "sparkles", true),
            ("Electronics", "#9C27B0", "bolt.fill", true),
            ("Clothing", "#FF9800", "tshirt.fill", true)
        ]

        for (name, color, icon, taxable) in categories {
            let category = ProductCategory(context: viewContext)
            category.id = UUID()
            category.name = name
            category.colorHex = color
            category.iconName = icon
            category.isTaxable = taxable
        }

        // Create sample shopping lists for preview
        let list = ShoppingList(context: viewContext)
        list.id = UUID()
        list.name = "Weekly Groceries"
        list.createdAt = Date()
        list.budget = 150.00

        // Create sample items
        let items = [
            ("Milk", 4.99, 2, "Food"),
            ("Bread", 3.49, 1, "Food"),
            ("Aspirin", 8.99, 1, "Medication"),
            ("Dish Soap", 5.99, 2, "Cleaning")
        ]

        for (name, price, quantity, category) in items {
            let item = ShoppingItem(context: viewContext)
            item.id = UUID()
            item.name = name
            item.price = price
            item.quantity = Int16(quantity)
            item.categoryName = category
            item.isPurchased = false
            item.list = list
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    // NSPersistentContainer manages the Core Data stack
    let container: NSPersistentContainer

    /// Initializes the persistence controller
    /// - Parameter inMemory: If true, uses in-memory store
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ShopSense")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// Saves the view context if there are unsaved changes
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
