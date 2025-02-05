import UIKit
import StoreKit
import WebKit
import ReddimonAttribution

// MARK: - StoreKit Implementation
class SubscriptionViewController: UIViewController, SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                if let product = // your product lookup logic {
                    AttributionManager.shared.trackStoreKitPurchase(transaction, product)
                }
                queue.finishTransaction(transaction)
                
            case .failed, .restored, .deferred:
                queue.finishTransaction(transaction)
                
            case .purchasing: break
            @unknown default: break
            }
        }
    }

// MARK: - Web Implementation
class WebSubscriptionViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        view.addSubview(webView)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        // Example: your-app-scheme://subscription/success?subscription_id=sub_123&plan=premium&amount=9.99&interval=monthly
        if url.scheme == "your-app-scheme" && url.path == "/subscription/success" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            let queryItems = components?.queryItems ?? []
            
            let subscriptionId = queryItems.first(where: { $0.name == "subscription_id" })?.value ?? ""
            let planType = queryItems.first(where: { $0.name == "plan" })?.value ?? ""
            let amount = Double(queryItems.first(where: { $0.name == "amount" })?.value ?? "0") ?? 0
            let interval = queryItems.first(where: { $0.name == "interval" })?.value ?? "monthly"
            
            AttributionManager.shared.trackWebPurchase(
                subscriptionId: subscriptionId,
                planType: planType,
                amount: amount,
                interval: interval
            )
            
            decisionHandler(.cancel)
            dismiss(animated: true)
            return
        }
        
        decisionHandler(.allow)
    }
}