// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DNA13TruckingApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "DNA13TruckingApp",
            targets: ["DNA13TruckingApp"]),
    ],
    dependencies: [
        // Supabase Swift SDK
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
        
        // Network and HTTP client
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),
        
        // Image handling
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.11.0"),
        
        // Charts and data visualization - CORREGIDO: Cambiado a DGCharts (ChartsOrg)
        .package(url: "https://github.com/ChartsOrg/Charts.git", from: "5.0.0"),
        
        // Date handling
        .package(url: "https://github.com/malcommac/SwiftDate.git", from: "6.3.0"),
        
        // Keychain access - CORREGIDO: Versión compatible
        .package(url: "https://github.com/jrendel/SwiftKeychainWrapper.git", from: "4.1.0"),
        
        // Analytics
        .package(url: "https://github.com/Firebase/FirebaseAnalytics.git", from: "10.0.0"),
        .package(url: "https://github.com/Firebase/FirebaseCrashlytics.git", from: "10.0.0"),
        
        // Push notifications - CORREGIDO: Usando XCFramework para compatibilidad Xcode 15
        .package(url: "https://github.com/OneSignal/OneSignal-XCFramework.git", from: "5.1.0"),
        
        // PDF generation - CORREGIDO: Reemplazado HTMLPDF con alternativa funcional
        .package(url: "https://github.com/coenttb/swift-html-to-pdf.git", from: "1.0.0"),
        
        // Core utilities
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "DNA13TruckingApp",
            dependencies: [
                // System frameworks
                .product(name: "SwiftUI", package: "swift"),
                .product(name: "UIKit", package: "swift"),
                .product(name: "MapKit", package: "swift"),
                .product(name: "VisionKit", package: "swift"),
                .product(name: "LocalAuthentication", package: "swift"),
                .product(name: "CoreLocation", package: "swift"),
                .product(name: "UserNotifications", package: "swift"),
                .product(name: "HealthKit", package: "swift"),
                .product(name: "AVFoundation", package: "swift"),
                
                // Third-party dependencies
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                // CORREGIDO: Cambiado import de Charts a DGCharts
                .product(name: "DGCharts", package: "Charts"),
                .product(name: "SwiftDate", package: "SwiftDate"),
                .product(name: "KeychainWrapper", package: "SwiftKeychainWrapper"),
                .product(name: "FirebaseAnalytics", package: "FirebaseAnalytics"),
                .product(name: "FirebaseCrashlytics", package: "FirebaseCrashlytics"),
                .product(name: "OneSignal", package: "OneSignal-XCFramework"),
                // CORREGIDO: Añadido producto para generación PDF
                .product(name: "SwiftHTMLToPDF", package: "swift-html-to-pdf"),
                
                // Logging
                .product(name: "Logging", package: "swift-log")
            ],
            resources: [
                .process("Assets.xcassets"),
                .process("Configuration"),
                .process("DesignSystem"),
                .process("Managers"),
                .process("Models"),
                .process("Services"),
                .process("ViewModels"),
                .process("Views")
            ]
        ),
        .testTarget(
            name: "DNA13TruckingAppTests",
            dependencies: ["DNA13TruckingApp"]
        ),
        .target(
            name: "DNA13TruckingAppPreview",
            dependencies: ["DNA13TruckingApp"]
        )
    ]
)