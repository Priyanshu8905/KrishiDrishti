// Services/Purchase/PurchaseManager.swift
// KrishiDrishti — Exposes premium product purchase states and updates to Presentation components

import SwiftUI
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    @Published var availableProducts: [Product] = []
    @Published var isPremiumUnlocked = false

    private let storeManager: StoreManagerProtocol

    init(storeManager: StoreManagerProtocol = StoreManager.shared) {
        self.storeManager = storeManager
        checkPremiumStatus()
    }

    func loadProducts() async {
        do {
            availableProducts = try await storeManager.fetchProducts()
        } catch {
            // Handle product fetching error gracefully
        }
    }

    func purchase(_ product: Product) async throws {
        _ = try await storeManager.purchase(product)
        checkPremiumStatus()
    }

    func restore() async {
        do {
            try await storeManager.restorePurchases()
            checkPremiumStatus()
        } catch {
            // Handle restore error gracefully
        }
    }

    private func checkPremiumStatus() {
        isPremiumUnlocked = storeManager.purchasedProductIDs.contains("com.krishidrishti.premium.advisory")
    }
}
