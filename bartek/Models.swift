//
//  Models.swift
//  bartek
//
//  Created by Jakub Nowosad on 06/06/2025.
//

import Foundation
import SwiftUI

// MARK: - Pomocnicze struktury i rozszerzenia

struct CarRentalColors {
    static let primary = Color.blue
    static let success = Color.green
    static let danger = Color.red
    static let warning = Color.orange
    static let background = Color(.systemGray6)
}

// MARK: - Rozszerzenia

extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}

extension Double {
    func asCurrency() -> String {
        return String(format: "%.0f zł", self)
    }
}

extension Date {
    func asShortString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "pl_PL")
        return formatter.string(from: self)
    }
}

// MARK: - Modifikatory widoków

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    func primaryButton() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding()
            .background(CarRentalColors.primary)
            .foregroundColor(.white)
            .cornerRadius(10)
            .font(.headline)
    }
}
