import Foundation
import StoreKit

@MainActor
class PurchaseManager: NSObject, ObservableObject {
    @Published var currentTier: AppTier = .free
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var purchaseSuccess: String?

    // DEV MODE – fjernes før lansering
    @Published var devModeActive: Bool = false
    func devModeUnlock() {
        devModeActive = true
        currentTier = .full
    }
    // END DEV MODE
    
    private let productIDs = ["com.pekkam.compass", "com.pekkam.full", "com.pekkam.upgrade_to_full"]
    private let tierKey = "pekkam_app_tier"
    
    override init() {
        super.init()
        loadTierFromDefaults()
        Task {
            await loadProducts()
            await setupTransactionListener()
        }
    }
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            self.products = try await Product.products(for: productIDs)
        } catch {
            self.error = "Failed to load products: \(error.localizedDescription)"
        }
    }
    
    func setupTransactionListener() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await handleVerifiedTransaction(transaction)
                await transaction.finish()
            }
        }
    }
    
    @MainActor
    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        switch transaction.productID {
        case "com.pekkam.compass":
            currentTier = .compass
        case "com.pekkam.full":
            currentTier = .full
        case "com.pekkam.upgrade_to_full":
            if currentTier == .compass {
                currentTier = .full
            }
        default:
            break
        }
        saveTierToDefaults()
    }
    
    func purchase(_ productID: String) async throws {
        error = nil
        purchaseSuccess = nil

        guard !products.isEmpty else {
            error = "Produkter ikke lastet ennå – prøv igjen om et øyeblikk."
            throw NSError(domain: "PurchaseManager", code: -2, userInfo: [NSLocalizedDescriptionKey: error!])
        }
        guard let product = products.first(where: { $0.id == productID }) else {
            error = "Produktet ble ikke funnet (ID: \(productID))."
            throw NSError(domain: "PurchaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: error!])
        }

        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await handleVerifiedTransaction(transaction)
                await transaction.finish()
                purchaseSuccess = "Kjøpet ble fullført 🎉"
            case .unverified:
                error = "Transaksjonen kunne ikke verifiseres."
            @unknown default:
                break
            }
        case .pending:
            error = "Kjøpet er til behandling – sjekk igjen snart."
        case .userCancelled:
            break  // stille avbrytelse, ingen feilmelding
        @unknown default:
            error = "Ukjent kjøpsresultat."
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            // Check purchased products
            var currentHighestTier = AppTier.free
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    switch transaction.productID {
                    case "com.pekkam.compass":
                        if currentHighestTier == .free {
                            currentHighestTier = .compass
                        }
                    case "com.pekkam.full":
                        currentHighestTier = .full
                    case "com.pekkam.upgrade_to_full":
                        currentHighestTier = .full
                    default:
                        break
                    }
                }
            }
            currentTier = currentHighestTier
            saveTierToDefaults()
        } catch {
            self.error = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }
    
    private func saveTierToDefaults() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: tierKey)
    }
    
    private func loadTierFromDefaults() {
        if let savedTierString = UserDefaults.standard.string(forKey: tierKey),
           let tier = AppTier(rawValue: savedTierString) {
            currentTier = tier
        }
    }
}
