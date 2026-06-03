import StoreKit
import Combine

// Product ID must match exactly what you create in App Store Connect.
private let removeAdsProductID = "removeads"

@MainActor
class PurchaseManager: ObservableObject {
    @Published private(set) var isAdFree = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private(set) var product: Product?
    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = Task { await listenForTransactions() }
        Task {
            await loadProduct()
            await refreshStatus()
        }
    }

    deinit { transactionListener?.cancel() }

    // MARK: - Public

    func purchase() async {
        isLoading = true
        defer { isLoading = false }

        if product == nil {
            await loadProduct()
        }

        guard let product else {
            errorMessage = "Product unavailable. StoreKit could not load product ID '\(removeAdsProductID)'. Check the product ID, bundle ID, In-App Purchase capability, Paid Apps Agreement, and scheme StoreKit configuration."
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let tx) = verification else { return }
                await tx.finish()
                await refreshStatus()
            case .pending:
                errorMessage = "Purchase is pending parental approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshStatus()
            if !isAdFree { errorMessage = "No previous purchase found for this Apple ID." }
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Private

    private func refreshStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == removeAdsProductID,
               tx.revocationDate == nil {
                isAdFree = true
                return
            }
        }
        isAdFree = false
    }

    private func loadProduct() async {
        do {
            let products = try await Product.products(for: [removeAdsProductID])
            product = products.first
            print("StoreKit requested product ID: \(removeAdsProductID), loaded count: \(products.count)")
        } catch {
            product = nil
            errorMessage = "StoreKit product load failed: \(error.localizedDescription)"
            print("StoreKit product load failed for \(removeAdsProductID): \(error)")
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let tx) = result else { continue }
            await tx.finish()
            await refreshStatus()
        }
    }
}
