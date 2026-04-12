//
//  TaxCalculatorView.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//
//  Description: Standalone tax calculator for quick calculations.
//  Supports different Canadian provinces with their respective tax rates.
//

import SwiftUI

/// TaxCalculatorView provides a standalone tax calculator
struct TaxCalculatorView: View {
    @AppStorage("selectedProvince") private var selectedProvince = "Ontario"

    @State private var amount: Double = 0
    @State private var isTaxable = true

    private var province: TaxCalculator.Province {
        TaxCalculator.Province(rawValue: selectedProvince) ?? .ontario
    }

    private var calculator: TaxCalculator {
        TaxCalculator(province: province)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Amount input section
                Section("Amount") {
                    HStack {
                        Text("$")
                            .font(.title2)
                        TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }

                // Province selector
                Section("Province") {
                    Picker("Select Province", selection: $selectedProvince) {
                        ForEach(TaxCalculator.Province.allCases) { province in
                            Text(province.rawValue).tag(province.rawValue)
                        }
                    }
                    .pickerStyle(.menu)

                    // Tax rate info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(province.taxDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Total Rate: \(String(format: "%.2f", province.totalTaxRate * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Taxable toggle
                Section {
                    Toggle("Apply Tax", isOn: $isTaxable)
                }

                // Results section
                Section("Calculation") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(TaxCalculator.formatPrice(amount))
                    }

                    if isTaxable {
                        HStack {
                            Text("Tax (\(province.taxDescription))")
                            Spacer()
                            Text(TaxCalculator.formatPrice(calculator.calculateTax(subtotal: amount, isTaxable: true)))
                                .foregroundColor(.orange)
                        }
                    }

                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(TaxCalculator.formatPrice(calculator.calculateTotal(subtotal: amount, isTaxable: isTaxable)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }

                // Quick amounts
                Section("Quick Amounts") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach([5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0], id: \.self) { quickAmount in
                            Button {
                                amount = quickAmount
                            } label: {
                                Text(TaxCalculator.formatPrice(quickAmount))
                                    .font(.caption)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Tax information
                Section("Tax Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Canadian Tax Rates")
                            .font(.headline)

                        Text("In Canada, sales tax varies by province. Some provinces use a Harmonized Sales Tax (HST), while others apply GST and PST separately.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Divider()

                        Text("Tax-Exempt Items:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Basic groceries (food)")
                            Text("• Prescription medication")
                            Text("• Children's clothing & footwear")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Tax Calculator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        amount = 0
                    }
                }
            }
        }
    }
}

#Preview {
    TaxCalculatorView()
}
