import UIKit
import ReddimonAttribution

// MARK: - Example Implementation
class ExampleViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAttribution()
    }
    
    private func setupAttribution() {
        // Initialize the SDK in AppDelegate.swift
        // AttributionManager.initialize(
        //     apiKey: "your_api_key_here",
        //     baseURL: "https://reddimon.com",
        //     appId: "1234567890"
        // )
    }
}

// MARK: - Deep Linking Example
extension ExampleViewController {
    // Handle deep links in AppDelegate.swift or SceneDelegate.swift
    func handleDeepLink(url: URL) {
        // Example URL: reddimon://attribution/c/creator_name/app_name/j44igo
        AttributionManager.shared.handleAttributionLink(url)
    }
}

// MARK: - URL Configuration
extension ExampleViewController {
    // Add to Info.plist:
    /*
     <key>CFBundleURLTypes</key>
     <array>
         <dict>
             <key>CFBundleURLSchemes</key>
             <array>
                 <string>reddimon</string>
             </array>
         </dict>
     </array>
     */
}

// MARK: - Installation Tracking
extension ExampleViewController {
    // Check for pending attribution on app launch
    func checkInitialAttribution() {
        AttributionManager.shared.checkInitialAttribution()
    }
}

// MARK: - UI Helpers
extension ExampleViewController {
    func showAttributionSuccess() {
        let alert = UIAlertController(
            title: "Success",
            message: "Installation tracked successfully",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func handleError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}