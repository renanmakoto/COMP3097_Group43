//
//  Internal Documentation Header (COMP3097 Final)
//  File: LaunchScreenView.swift
//  Author: Renan Yoshida Avelan (101536279, CRN: 54621)
//  Editors:
//    - Gustavo Miranda (101488574): reviewed header compliance and team-credit display notes.
//    - Lucas Tavares Criscuolo (101500671): reviewed header compliance and visual consistency notes.
//  External/AI References: NOT USED
//  Description: Branded launch screen that presents app identity and team members.
//

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
                        Text("Renan Yoshida Avelan - 101536279")
                        Text("Lucas Tavares Criscuolo - 101500671")
                        Text("Gustavo Miranda - 101488574")
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
