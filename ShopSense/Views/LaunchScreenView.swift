//
//  LaunchScreenView.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//
//  Description: Launch screen displaying app name and team member information.
//

import SwiftUI

/// LaunchScreenView displays the app branding during startup
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // App icon
                Image(systemName: "cart.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)

                // App name
                Text("ShopSense")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Shopping List with Tax Calculator")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                // Team information
                VStack(spacing: 8) {
                    Text("COMP3097 - Mobile App Development II")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Text("Developed by:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    VStack(spacing: 4) {
                        Text("Renan Yoshida Avelan")
                        Text("Lucas Tavares Criscuolo")
                        Text("Gustavo Miranda")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
