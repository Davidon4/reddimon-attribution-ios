import UIKit
import ReddimonAttribution

// MARK: - StoreKit Implementation
#if canImport(StoreKit)
import StoreKit

class SubscriptionViewController: UIViewController {
    
    // Your subscription products
    private let monthlyProductId = "com.yourapp.subscription.monthly"
    private let yearlyProductId = "com.yourapp.subscription.yearly"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup your subscription UI
    }
    
    // MARK: - Purchase Handling
    
    /// Handle subscription purchase
    /// - Parameter productId: The product identifier to purchase
    func purchaseSubscription(productId: String) {
        // Your StoreKit purchase logic here
        if let product = // fetch product {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
}

// MARK: - SKPaymentTransactionObserver
extension SubscriptionViewController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                if let product = // your product lookup logic {
                    // Track successful subscription with Reddimon
                    AttributionManager.shared.trackStoreKitPurchase(transaction, product)
                    
                    // Complete the transaction
                    queue.finishTransaction(transaction)
                    
                    // Update UI to show successful purchase
                    showSuccessUI()
                }
                
            case .failed:
                queue.finishTransaction(transaction)
                handleFailedPurchase(transaction.error)
                
            case .restored:
                queue.finishTransaction(transaction)
                handleRestoredPurchase()
                
            case .purchasing, .deferred:
                break
                
            @unknown default:
                break
            }
        }
    }
}
#endif

// MARK: - RevenueCat Implementation
#if canImport(RevenueCat)
import RevenueCat

class RevenueCatSubscriptionViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRevenueCat()
    }
    
    private func setupRevenueCat() {
        // Configure RevenueCat
        Purchases.configure(withAPIKey: "your_revenuecat_key")
    }
    
    /// Purchase a package using RevenueCat
    /// - Parameter package: The package to purchase
    func purchasePackage(_ package: Package) {
        Purchases.shared.purchase(package: package) { [weak self] (transaction, customerInfo, error, userCancelled) in
            if let transaction = transaction {
                // Track successful subscription with Reddimon
                AttributionManager.shared.trackRevenueCatPurchase(transaction)
                
                // Update UI
                self?.showSuccessUI()
            } else if let error = error {
                self?.handleError(error)
            }
        }
    }
}
#endif

// MARK: - Stripe Implementation
#if canImport(Stripe)
import Stripe

class StripeSubscriptionViewController: UIViewController {
    
    /// Handle successful Stripe subscription
    /// - Parameters:
    ///   - subscriptionId: The Stripe subscription ID
    ///   - planType: The type of plan (e.g., "premium", "pro")
    ///   - amount: The subscription amount
    ///   - interval: The billing interval ("monthly" or "yearly")
    func handleStripeSubscription(subscriptionId: String, planType: String, amount: Double, interval: String) {
        // Track successful subscription with Reddimon
        AttributionManager.shared.trackStripeSubscription(
            subscriptionId: subscriptionId,
            planType: planType,
            amount: amount,
            interval: interval
        )
        
        // Update UI
        showSuccessUI()
    }
    
    /// Create Stripe subscription on your backend
    /// - Parameters:
    ///   - paymentMethodId: The Stripe payment method ID
    ///   - planId: The plan to subscribe to
    func createSubscription(paymentMethodId: String, planId: String) {
        // Call your backend to create subscription
        let params = [
            "payment_method": paymentMethodId,
            "plan": planId
        ]
        
        // Your API call to create subscription
        APIClient.shared.createSubscription(params) { [weak self] result in
            switch result {
            case .success(let subscription):
                // Track with Reddimon
                self?.handleStripeSubscription(
                    subscriptionId: subscription.id,
                    planType: subscription.planType,
                    amount: subscription.amount,
                    interval: subscription.interval
                )
                
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
}
#endif

// MARK: - UI Helpers
extension UIViewController {
    func showSuccessUI() {
        // Show success message
        let alert = UIAlertController(
            title: "Success!",
            message: "Your subscription is now active",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func handleError(_ error: Error) {
        // Show error message
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}