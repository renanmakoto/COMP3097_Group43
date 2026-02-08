//
//  ShopSenseApp.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//  Team Members:
//    - Renan Yoshida Avelan (Student ID: 101536279, CRN: 54621)
//    - Lucas Tavares Criscuolo (Student ID: 101500671, CRN: 54621)
//    - Gustavo Miranda (Student ID: 101488574, CRN: 54621)
//
//  Description: Main entry point for ShopSense application.
//  This app provides shopping list management with tax calculation,
//  product categorization, and budget tracking using Core Data.
//
//  Target Device: iPhone 15 Pro (Portrait orientation)
//

import SwiftUI

/// Main application entry point
/// Initializes the app with Core Data persistence and sets up the main navigation
@main
struct ShopSenseApp: App {
    // Core Data persistence controller for managing shopping data
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            // MainView serves as the root navigation container
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
