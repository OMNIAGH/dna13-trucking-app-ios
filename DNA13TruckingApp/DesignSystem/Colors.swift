import SwiftUI

// MARK: - Color Palette (D.N.A 13 Trucking Identity)
extension Color {
    // Primary Colors
    static let dnaGreenDark = Color(hex: "#3D503C") // Verde oliva oscuro
    static let dnaGreenDarker = Color(hex: "#313B002") // Verde más oscuro
    
    // Accent Colors  
    static let dnaOrange = Color(hex: "#FF9030") // Naranja principal
    static let dnaOrangeSecondary = Color(hex: "#FBA0002") // Naranja secundario
    
    // Text Colors
    static let dnaTextPrimary = Color(hex: "#333333") // Gris oscuro para texto
    static let dnaTextSecondary = Color.white // Blanco para texto sobre fondo oscuro
    
    // Supporting Colors
    static let dnaBackground = Color.black // Fondo principal
    static let dnaSurface = Color.dnaGreenDark.opacity(0.3) // Superficie de tarjetas
    static let dnaSurfaceLight = Color.dnaGreenDark.opacity(0.1) // Superficie más clara
    static let dnaError = Color.red
    static let dnaSuccess = Color.green
    static let dnaWarning = Color.yellow
    
    // Semantic Colors
    static let dnaFuel = Color.blue
    static let dnaMaintenance = Color.purple
    static let dnaPermit = Color.orange
    static let dnaTrip = Color.green
    static let dnaAlert = Color.red
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
