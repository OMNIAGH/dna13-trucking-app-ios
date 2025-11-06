import Foundation

// MARK: - App Configuration
struct AppConfig {
    static let appName = "D.N.A 13 Trucking"
    static let bundleIdentifier = "com.dna13.trucking"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // Company Info
    static let companyDOT = "4058976"
    static let companyName = "D.N.A 13 Trucking Company"
    
    // Supabase Configuration
    static let supabaseURL = "https://athazapkqtozhjromuvn.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0aGF6YXBrcXRvenhqcmlvbXV2biIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzI2MzQ1NDU0LCJleHAiOjIwNDE5MjE0NTR9.gKaLLAcOY_FnSmM_T6Wc3FU9lUJcPhkRCFHqbGKHhP8"
    
    // Edge Function URLs
    static let openaiProxyURL = "https://athazapkqtozhjromuvn.supabase.co/functions/v1/openai-proxy"
    static let documentOCRURL = "https://athazapkqtozhjromuvn.supabase.co/functions/v1/document-ocr"
    static let loadSearchURL = "https://athazapkqtozhjromuvn.supabase.co/functions/v1/load-search"
    static let alertSystemURL = "https://athazapkqtozhjromuvn.supabase.co/functions/v1/alert-system"
    
    // Storage Buckets
    static let documentsBucket = "documents"
    static let vehicleImagesBucket = "vehicle_images"
    static let userAvatarsBucket = "user_avatars"
    static let ocrExtractedBucket = "ocr_extracted"
    
    // Default Values
    static let defaultUnits = ["115A", "305"]
    static let defaultVehicleMakes = ["Volvo", "Kenworth", "Freightliner", "Peterbilt", "International"]
    
    // Permissions
    static let locationRequestDescription = "Necesitamos acceso a tu ubicación para navegación y tracking de viajes."
    static let cameraRequestDescription = "Necesitamos acceso a la cámara para escanear documentos como BOL, facturas y permisos."
    static let photoLibraryRequestDescription = "Necesitamos acceso a la galería de fotos para subir documentos."
}

// MARK: - User Roles
enum UserRole: String, CaseIterable {
    case driver = "driver"
    case dispatcher = "dispatcher"
    case manager = "manager"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .driver: return "Conductor"
        case .dispatcher: return "Despachador"
        case .manager: return "Gerente"
        case .admin: return "Administrador"
        }
    }
}

// MARK: - Document Types
enum DocumentType: String, CaseIterable {
    case bol = "BOL" // Bill of Lading
    case contract = "contract"
    case permit = "permit"
    case insurance = "insurance"
    case eld = "ELD"
    case receipt = "receipt"
    case invoice = "invoice"
    case maintenance = "maintenance"
    
    var displayName: String {
        switch self {
        case .bol: return "BOL (Carta de Porte)"
        case .contract: return "Contrato de Arrendamiento"
        case .permit: return "Permiso"
        case .insurance: return "Seguro"
        case .eld: return "ELD (Registro Electrónico)"
        case .receipt: return "Recibo"
        case .invoice: return "Factura"
        case .maintenance: return "Mantenimiento"
        }
    }
}

// MARK: - Trip Status
enum TripStatus: String, CaseIterable {
    case planned = "planned"
    case loaded = "loaded"
    case inTransit = "in_transit"
    case delivered = "delivered"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .planned: return "Planificado"
        case .loaded: return "Cargado"
        case .inTransit: return "En Tránsito"
        case .delivered: return "Entregado"
        case .completed: return "Completado"
        case .cancelled: return "Cancelado"
        }
    }
    
    var color: Color {
        switch self {
        case .planned: return .blue
        case .loaded: return .yellow
        case .inTransit: return .orange
        case .delivered, .completed: return .green
        case .cancelled: return .red
        }
    }
}

// MARK: - Stop Types
enum StopType: String, CaseIterable {
    case pickup = "pickup"
    case drop = "drop"
    case fuel = "fuel"
    case rest = "rest"
    case maintenance = "maintenance"
    case weighStation = "weigh_station"
    
    var displayName: String {
        switch self {
        case .pickup: return "Recogida"
        case .drop: return "Entrega"
        case .fuel: return "Combustible"
        case .rest: return "Descanso"
        case .maintenance: return "Mantenimiento"
        case .weighStation: return "Estación de Pesaje"
        }
    }
    
    var icon: String {
        switch self {
        case .pickup: return "arrow.down.circle"
        case .drop: return "arrow.up.circle"
        case .fuel: return "fuelpump"
        case .rest: return "bed.double"
        case .maintenance: return "wrench"
        case .weighStation: return "scalefor.horizontal"
        }
    }
}

// MARK: - Alert Types
enum AlertType: String, CaseIterable {
    case weather = "weather"
    case traffic = "traffic"
    case permit = "permit"
    case maintenance = "maintenance"
    case fuel = "fuel"
    case compliance = "compliance"
    
    var displayName: String {
        switch self {
        case .weather: return "Clima"
        case .traffic: return "Tráfico"
        case .permit: return "Permiso"
        case .maintenance: return "Mantenimiento"
        case .fuel: return "Combustible"
        case .compliance: return "Compliance"
        }
    }
    
    var icon: String {
        switch self {
        case .weather: return "cloud.sun"
        case .traffic: return "car"
        case .permit: return "doc.text"
        case .maintenance: return "wrench.and.screwdriver"
        case .fuel: return "fuelpump"
        case .compliance: return "checkmark.shield"
        }
    }
}
