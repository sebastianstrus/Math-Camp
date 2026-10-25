//
//  PremiumAccess.swift
//  Math Camp
//

import Foundation
import Observation
import StoreKit

/// Product identifiers. They must match the products created in App Store Connect
/// (and `Products.storekit` for local testing).
enum PremiumPlan: String, CaseIterable, Identifiable {
    case monthly = "com.sebastianstrus.mathcamp.premium.monthly"
    case yearly = "com.sebastianstrus.mathcamp.premium.yearly"
    case lifetime = "com.sebastianstrus.mathcamp.premium.lifetime"

    var id: String { rawValue }
}

/// Decides which tasks can be opened and runs the purchases (StoreKit 2).
///
/// Premium is on while the person owns the lifetime purchase or an active subscription.
/// Everything about the entitlement comes from StoreKit, nothing is stored by the app.
@Observable
final class PremiumAccess {
    enum LoadState: Equatable {
        case idle, loading, loaded
        case failed
    }

    private(set) var isPremium = false
    /// Monthly, yearly, lifetime (in this order; missing products are left out).
    private(set) var products: [Product] = []
    private(set) var loadState = LoadState.idle
    /// The product being bought right now.
    private(set) var purchasingID: String?
    /// A message for the paywall (failed purchase, failed restore).
    var errorMessage: String?

    #if DEBUG
    /// Debug switch that opens every task, stored between launches.
    var debugUnlockAll = UserDefaults.standard.bool(forKey: "debug.unlockAll") {
        didSet { UserDefaults.standard.set(debugUnlockAll, forKey: "debug.unlockAll") }
    }
    #endif

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        // Purchases that finish outside the app (Ask to Buy, renewals, other devices).
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: Access

    func isUnlocked(_ category: Category, taskNumber: Int) -> Bool {
        #if DEBUG
        if debugUnlockAll { return true }
        #endif
        return isPremium || category.isFree(taskNumber: taskNumber)
    }

    // MARK: Products

    func loadProducts() async {
        guard loadState != .loading else { return }
        loadState = .loading
        do {
            let loaded = try await Product.products(for: PremiumPlan.allCases.map(\.rawValue))
            products = PremiumPlan.allCases.compactMap { plan in loaded.first { $0.id == plan.rawValue } }
            loadState = products.isEmpty ? .failed : .loaded
        } catch {
            loadState = .failed
        }
    }

    // MARK: Buying

    func purchase(_ product: Product) async {
        guard purchasingID == nil else { return }
        purchasingID = product.id
        errorMessage = nil
        defer { purchasingID = nil }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                await handle(verification)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = L10n.string("paywall.error.purchase")
        }
    }

    /// "Restore purchases": asks the App Store to sync, then reads the entitlements again.
    func restorePurchases() async {
        errorMessage = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPremium { errorMessage = L10n.string("paywall.error.nothingToRestore") }
        } catch {
            errorMessage = L10n.string("paywall.error.restore")
        }
    }

    // MARK: Entitlements

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else {
            errorMessage = L10n.string("paywall.error.verification")
            return
        }
        await transaction.finish()
        await refreshEntitlements()
        // A just-verified purchase counts even if `currentEntitlements` has not caught up yet.
        if !isPremium, isEntitling(transaction) { isPremium = true }
    }

    private func isEntitling(_ transaction: Transaction) -> Bool {
        guard PremiumPlan(rawValue: transaction.productID) != nil,
              transaction.revocationDate == nil else { return false }
        if let expiration = transaction.expirationDate { return expiration > .now }
        return true
    }

    func refreshEntitlements() async {
        var premium = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil,
                  PremiumPlan(rawValue: transaction.productID) != nil else { continue }
            premium = true
        }
        // `currentEntitlements` can come back empty right after launch (and with local
        // StoreKit testing), so also look at the latest transaction of every plan.
        if !premium {
            for plan in PremiumPlan.allCases {
                if case .verified(let transaction) = await Transaction.latest(for: plan.rawValue),
                   isEntitling(transaction) {
                    premium = true
                    break
                }
            }
        }
        isPremium = premium
    }
}
