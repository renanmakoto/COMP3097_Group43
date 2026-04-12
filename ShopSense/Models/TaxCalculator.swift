//
//  TaxCalculator.swift
//  ShopSense - Shopping List with Tax Calculator
//
//  COMP3097 - Mobile App Development II
//  Final Project
//
//
//  Description: Tax calculator utility for computing taxes based on
//  Canadian tax rates. Supports HST, GST, and PST calculations
//  based on province selection.
//

import Foundation

/// TaxCalculator handles tax calculations for shopping items
/// Supports various Canadian tax rates by province
struct TaxCalculator {

    /// Canadian provinces with their tax configurations
    enum Province: String, CaseIterable, Identifiable {
        case ontario = "Ontario"
        case quebec = "Quebec"
        case britishColumbia = "British Columbia"
        case alberta = "Alberta"
        case manitoba = "Manitoba"
        case saskatchewan = "Saskatchewan"
        case novascotia = "Nova Scotia"
        case newbrunswick = "New Brunswick"
        case newfoundland = "Newfoundland"
        case pei = "Prince Edward Island"

        var id: String { rawValue }

        /// GST rate (5% federal in all provinces)
        var gstRate: Double { 0.05 }

        /// PST rate (varies by province)
        var pstRate: Double {
            switch self {
            case .ontario, .novascotia, .newbrunswick, .newfoundland, .pei:
                return 0.0 // HST provinces
            case .quebec:
                return 0.09975
            case .britishColumbia:
                return 0.07
            case .alberta:
                return 0.0
            case .manitoba:
                return 0.07
            case .saskatchewan:
                return 0.06
            }
        }

        /// HST rate (for HST provinces)
        var hstRate: Double {
            switch self {
            case .ontario:
                return 0.13
            case .novascotia, .newfoundland, .pei:
                return 0.15
            case .newbrunswick:
                return 0.15
            default:
                return 0.0
            }
        }

        /// Total tax rate for the province
        var totalTaxRate: Double {
            if hstRate > 0 {
                return hstRate
            }
            return gstRate + pstRate
        }

        /// Description of tax breakdown
        var taxDescription: String {
            if hstRate > 0 {
                return "HST \(Int(hstRate * 100))%"
            } else if pstRate > 0 {
                return "GST 5% + PST \(String(format: "%.2f", pstRate * 100))%"
            } else {
                return "GST 5%"
            }
        }
    }

    // Current selected province
    var province: Province

    /// Calculates tax for a given subtotal
    /// - Parameters:
    ///   - subtotal: The pre-tax amount
    ///   - isTaxable: Whether the item is taxable
    /// - Returns: The tax amount
    func calculateTax(subtotal: Double, isTaxable: Bool) -> Double {
        guard isTaxable else { return 0.0 }
        return subtotal * province.totalTaxRate
    }

    /// Calculates the total including tax
    /// - Parameters:
    ///   - subtotal: The pre-tax amount
    ///   - isTaxable: Whether the item is taxable
    /// - Returns: The total amount with tax
    func calculateTotal(subtotal: Double, isTaxable: Bool) -> Double {
        return subtotal + calculateTax(subtotal: subtotal, isTaxable: isTaxable)
    }

    /// Formats a price for display
    /// - Parameter amount: The amount to format
    /// - Returns: Formatted currency string
    static func formatPrice(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

/// Categories that are typically tax-exempt in Canada
/// Used for default settings when creating product categories
enum TaxExemptCategory: String, CaseIterable {
    case food = "Basic Groceries"
    case medication = "Prescription Medication"
    case childrenClothing = "Children's Clothing"
    case childrenFootwear = "Children's Footwear"

    var isTaxExempt: Bool { true }
}
