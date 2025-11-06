import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure app appearance
        configureAppAppearance()
        
        return true
    }
    
    // MARK: - App Appearance Configuration
    private func configureAppAppearance() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(.dnaBackground)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(.dnaTextSecondary),
            .font: UIFont(name: AppFont.montserratBold, size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(.dnaTextSecondary),
            .font: UIFont(name: AppFont.montserratBold, size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(.dnaBackground)
        tabBarAppearance.selectionIndicatorTintColor = UIColor(.dnaOrange)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure tab bar item appearance
        let tabBarItemAppearance = UITabBarItem.appearance()
        tabBarItemAppearance.setTitleTextAttributes([
            .foregroundColor: UIColor(.dnaTextSecondary.opacity(0.7)),
            .font: UIFont(name: AppFont.montserratRegular, size: 10) ?? UIFont.systemFont(ofSize: 10)
        ], for: .normal)
        
        tabBarItemAppearance.setTitleTextAttributes([
            .foregroundColor: UIColor(.dnaOrange),
            .font: UIFont(name: AppFont.montserratMedium, size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .medium)
        ], for: .selected)
        
        // Configure button appearance
        let buttonAppearance = UIButton.appearance()
        buttonAppearance.tintColor = UIColor(.dnaOrange)
        
        // Configure text field appearance
        let textFieldAppearance = UITextField.appearance()
        textFieldAppearance.keyboardAppearance = .dark
        
        // Configure table view appearance
        let tableViewAppearance = UITableView.appearance()
        tableViewAppearance.backgroundColor = UIColor.clear
        tableViewAppearance.separatorColor = UIColor(.dnaTextSecondary.opacity(0.2))
    }
    
    // MARK: - URL Handling
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle custom URL schemes
        if url.scheme == "dna13trucking" {
            handleDeepLink(url)
            return true
        }
        
        return false
    }
    
    private func handleDeepLink(_ url: URL) {
        let components = URLComponents(string: url.absoluteString)
        
        guard let host = components?.host else { return }
        
        switch host {
        case "trip":
            // Handle trip deep link
            if let queryItems = components?.queryItems,
               let tripId = queryItems.first(where: { $0.name == "id" })?.value {
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkTrip"),
                    object: tripId
                )
            }
        case "document":
            // Handle document deep link
            if let queryItems = components?.queryItems,
               let documentId = queryItems.first(where: { $0.name == "id" })?.value {
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkDocument"),
                    object: documentId
                )
            }
        default:
            break
        }
    }
    
    // MARK: - Background Processing
    func applicationWillResignActive(_ application: UIApplication) {
        // Called when the application is about to move from active to inactive state
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Called when the application enters the background
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called when the application is about to enter the foreground
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Called when the application becomes active
    }
    
    // MARK: - Location Services
    func applicationDidFinishLaunching(_ application: UIApplication) {
        // Request location permissions if needed
        requestLocationPermissionsIfNeeded()
    }
    
    private func requestLocationPermissionsIfNeeded() {
        // This would be handled by SwiftUI's LocationManager
        // but we can check permission status here if needed
    }
    
    // MARK: - Remote Notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Handle remote notification registration
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Remote notification token: \(tokenString)")
        
        // Send token to your backend for push notifications
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle remote notification
        print("Received remote notification: \(userInfo)")
        completionHandler(.newData)
    }
}

// MARK: - Scene Delegate
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Create the SwiftUI view that provides the window contents
        let contentView = ContentView()
        
        // Use a UIHostingController as window root view controller
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Handle URL contexts
        for context in URLContexts {
            let url = context.url
            if url.scheme == "dna13trucking" {
                // Handle deep link
                handleDeepLink(url)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Send notification to SwiftUI app to handle deep link
        NotificationCenter.default.post(
            name: NSNotification.Name("DeepLinkURL"),
            object: url
        )
    }
}

// MARK: - App Configuration
extension AppDelegate {
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    var rootViewController: UIViewController? {
        return window?.rootViewController
    }
}
