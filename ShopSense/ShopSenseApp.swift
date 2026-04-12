//
//  Internal Documentation Header (COMP3097 Final)
//  File: ShopSenseApp.swift
//  Author: Renan Yoshida Avelan (101536279, CRN: 54621)
//  Editors:
//    - Gustavo Miranda (101488574): reviewed header compliance and startup flow notes.
//    - Lucas Tavares Criscuolo (101500671): reviewed header compliance and launch sequence notes.
//  External/AI References: NOT USED
//  Description: Main app entry point that wires Core Data and launch-to-main navigation.
//

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
    @State private var showLaunch = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showLaunch {
                    LaunchScreenView()
                        .transition(.opacity)
                } else {
                    MainView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: showLaunch)
            .task {
                guard showLaunch else { return }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                showLaunch = false
            }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
