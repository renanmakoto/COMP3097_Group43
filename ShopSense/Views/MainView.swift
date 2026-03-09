//
//  MainView.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//
//  Description: Main navigation view with tab bar for accessing different sections.
//  Provides access to shopping lists, categories, and settings screens.
//

import SwiftUI

/// MainView serves as the root navigation container with tab-based navigation
struct MainView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Shopping Lists
            ShoppingListsView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Lists")
                }
                .tag(0)

            // Tab 2: Categories
            CategoriesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Categories")
                }
                .tag(1)

            // Tab 3: Tax Calculator
            TaxCalculatorView()
                .tabItem {
                    Image(systemName: "percent")
                    Text("Calculator")
                }
                .tag(2)

            // Tab 4: Settings
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.green)
    }
}

#Preview {
    MainView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
