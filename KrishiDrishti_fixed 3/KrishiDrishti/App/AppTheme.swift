// App/AppTheme.swift
// KrishiDrishti — centralised design tokens

import SwiftUI

enum AppTheme {
    // MARK: - Brand Colors
    static let green        = Color(red: 0.18, green: 0.42, blue: 0.31)
    static let greenLight   = Color(red: 0.32, green: 0.72, blue: 0.53)
    static let greenSoft    = Color(red: 0.85, green: 0.97, blue: 0.88)
    static let amber        = Color(red: 0.90, green: 0.60, blue: 0.10)
    static let red          = Color(red: 0.85, green: 0.12, blue: 0.12)
    static let earthBrown   = Color(red: 0.55, green: 0.35, blue: 0.18)

    // MARK: - Severity Colors
    static func severityColor(_ s: Severity) -> Color {
        switch s {
        case .low:    return Color(red: 0.18, green: 0.56, blue: 0.34)
        case .medium: return amber
        case .high:   return red
        }
    }
    static func severityBg(_ s: Severity) -> Color {
        switch s {
        case .low:    return Color(red: 0.88, green: 0.97, blue: 0.89)
        case .medium: return Color(red: 1.00, green: 0.95, blue: 0.82)
        case .high:   return Color(red: 1.00, green: 0.90, blue: 0.90)
        }
    }

    // MARK: - Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [greenLight, green],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - Corner Radius
    static let radius: CGFloat  = 16
    static let radiusLg: CGFloat = 22
}
