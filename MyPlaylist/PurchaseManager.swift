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
        guard let product else {
            errorMessage = "Product unavailable. Check your internet connection and try again."
            return
        }
        isLoading = true
        defer { isLoading = false }
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
        product = try? await Product.products(for: [removeAdsProductID]).first
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let tx) = result else { continue }
            await tx.finish()
            await refreshStatus()
        }
    }
}
