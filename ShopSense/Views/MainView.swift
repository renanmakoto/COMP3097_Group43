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
import CoreData

/// MainView serves as the root navigation container with tab-based navigation
struct MainView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView { tab in
                selectedTab = tab
            }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            // Tab 1: Shopping Lists
            ShoppingListsView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Lists")
                }
                .tag(1)

            // Tab 2: Categories
            CategoriesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Categories")
                }
                .tag(2)

            // Tab 3: Tax Calculator
            TaxCalculatorView()
                .tabItem {
                    Image(systemName: "percent")
                    Text("Calculator")
                }
                .tag(3)

            // Tab 4: Settings
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.green)
    }
}

struct DashboardView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingList.createdAt, ascending: false)],
        animation: .default
    )
    private var lists: FetchedResults<ShoppingList>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingItem.name, ascending: true)],
        animation: .default
    )
    private var allItems: FetchedResults<ShoppingItem>

    let onSelectTab: (Int) -> Void

    private var itemCount: Int {
        allItems.count
    }

    private var purchasedCount: Int {
        allItems.filter { $0.isPurchased }.count
    }

    private var remainingCount: Int {
        max(0, itemCount - purchasedCount)
    }

    private var totalBudget: Double {
        lists.reduce(0) { $0 + $1.budget }
    }

    private var spentTotal: Double {
        allItems.filter { $0.isPurchased }.reduce(0) { total, item in
            total + (item.price * Double(item.quantity))
        }
    }

    private var budgetProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(spentTotal / totalBudget, 1.0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Shopping Overview")
                        .font(.title2)
                        .fontWeight(.bold)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DashboardStatCard(
                            title: "Lists",
                            value: "\(lists.count)",
                            systemImage: "list.bullet.clipboard",
                            tint: .green
                        )
                        DashboardStatCard(
                            title: "Items Left",
                            value: "\(remainingCount)",
                            systemImage: "cart",
                            tint: .orange
                        )
                        DashboardStatCard(
                            title: "Purchased",
                            value: "\(purchasedCount)",
                            systemImage: "checkmark.circle.fill",
                            tint: .blue
                        )
                        DashboardStatCard(
                            title: "Budget",
                            value: TaxCalculator.formatPrice(totalBudget),
                            systemImage: "dollarsign.circle",
                            tint: .purple
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Budget Progress")
                            .font(.headline)

                        ProgressView(value: budgetProgress)
                            .tint(budgetProgress < 1 ? .green : .red)

                        HStack {
                            Text("Spent: \(TaxCalculator.formatPrice(spentTotal))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Total Budget: \(TaxCalculator.formatPrice(totalBudget))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Actions")
                            .font(.headline)

                        DashboardActionButton(
                            title: "Open Shopping Lists",
                            systemImage: "list.bullet.clipboard"
                        ) {
                            onSelectTab(1)
                        }

                        DashboardActionButton(
                            title: "Open Categories",
                            systemImage: "folder.fill"
                        ) {
                            onSelectTab(2)
                        }

                        DashboardActionButton(
                            title: "Open Tax Calculator",
                            systemImage: "percent"
                        ) {
                            onSelectTab(3)
                        }

                        DashboardActionButton(
                            title: "Open Settings",
                            systemImage: "gear"
                        ) {
                            onSelectTab(4)
                        }
                    }

                    if lists.isEmpty {
                        Text("No lists yet. Open Lists and create your first shopping list.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(tint)
                .font(.title3)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct DashboardActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.primary)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
