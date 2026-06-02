// Services/Purchase/StoreManager.swift
// KrishiDrishti — Manages Premium features, Product catalogs, and validation workflows via StoreKit 2

import StoreKit

protocol StoreManagerProtocol: Sendable {
    var purchasedProductIDs: Set<String> { get }
    func fetchProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> Transaction?
    func updatePurchaseStatus() async
    func restorePurchases() async throws
}

final class StoreManager: StoreManagerProtocol, @unchecked Sendable {
    static let shared = StoreManager()

    private(set) var purchasedProductIDs = Set<String>()
    private var transactionListener: Task<Void, Error>?

    private let productIDs = ["com.krishidrishti.premium.advisory"]

    private init() {
        // Start listening to StoreKit transaction updates in the background
        transactionListener = Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await self.handleVerifiedTransaction(transaction)
                case .unverified:
                    break
                }
            }
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func fetchProducts() async throws -> [Product] {
        try await Product.products(for: productIDs)
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                await handleVerifiedTransaction(transaction)
                await transaction.finish()
                return transaction
            case .unverified:
                throw NSError(domain: "StoreManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "Unverified purchase transaction"])
            }
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    func updatePurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                await handleVerifiedTransaction(transaction)
            case .unverified:
                break
            }
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchaseStatus()
    }

    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        if transaction.revocationDate == nil {
            purchasedProductIDs.insert(transaction.productID)
        } else {
            purchasedProductIDs.remove(transaction.productID)
        }
    }
}
