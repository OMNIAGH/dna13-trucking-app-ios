import SwiftUI

// MARK: - Typography (Montserrat Font Family)
struct AppFont {
    // Montserrat Font Weights
    static let montserratBold = "Montserrat-Bold"
    static let montserratRegular = "Montserrat-Regular"
    static let montserratMedium = "Montserrat-Medium"
    static let montserratLight = "Montserrat-Light"
}

struct Typography {
    // Headings
    static let h1 = Font.custom(AppFont.montserratBold, size: 24)
    static let h2 = Font.custom(AppFont.montserratBold, size: 20)
    static let h3 = Font.custom(AppFont.montserratBold, size: 18)
    static let h4 = Font.custom(AppFont.montserratBold, size: 16)
    
    // Body Text
    static let bodyLarge = Font.custom(AppFont.montserratRegular, size: 16)
    static let body = Font.custom(AppFont.montserratRegular, size: 14)
    static let bodySmall = Font.custom(AppFont.montserratRegular, size: 12)
    
    // UI Elements
    static let button = Font.custom(AppFont.montserratMedium, size: 16)
    static let buttonSmall = Font.custom(AppFont.montserratMedium, size: 14)
    static let caption = Font.custom(AppFont.montserratLight, size: 10)
    
    // Metrics
    static let metricLarge = Font.custom(AppFont.montserratBold, size: 32)
    static let metricMedium = Font.custom(AppFont.montserratBold, size: 24)
    static let metricSmall = Font.custom(AppFont.montserratBold, size: 18)
}

// MARK: - Text Modifiers
struct Heading1: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.h1)
            .foregroundColor(.dnaTextSecondary)
            .multilineTextAlignment(.leading)
    }
}

struct Heading2: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.h2)
            .foregroundColor(.dnaTextSecondary)
            .multilineTextAlignment(.leading)
    }
}

struct BodyText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.body)
            .foregroundColor(.dnaTextSecondary)
            .multilineTextAlignment(.leading)
    }
}

struct ButtonText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.button)
            .foregroundColor(.dnaTextSecondary)
            .multilineTextAlignment(.center)
    }
}

struct MetricText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.metricLarge)
            .foregroundColor(.dnaOrange)
            .fontWeight(.bold)
    }
}

extension View {
    func heading1() -> some View {
        self.modifier(Heading1())
    }
    
    func heading2() -> some View {
        self.modifier(Heading2())
    }
    
    func bodyText() -> some View {
        self.modifier(BodyText())
    }
    
    func buttonText() -> some View {
        self.modifier(ButtonText())
    }
    
    func metricText() -> some View {
        self.modifier(MetricText())
    }
}
