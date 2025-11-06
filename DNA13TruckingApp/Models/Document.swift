//
//  Document.swift
//  DNA13TruckingApp
//
//  Modelo de datos para documentos, OCR y versionado de D.N.A 13 Trucking Company
//

import Foundation

// MARK: - Document Model
struct Document: Codable, Identifiable {
    let id: UUID
    let typeCode: DocumentType
    let title: String
    let issuer: String?
    let issueDate: Date?
    let expiryDate: Date?
    let hashIntegrity: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Metadata adicional
    var fileUrl: String?
    var fileSize: Int64?
    var mimeType: String?
    var tags: [String]?
    var notes: String?
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return Date() > expiryDate
    }
    
    var isExpiringSoon: Bool {
        guard let expiryDate = expiryDate else { return false }
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return expiryDate <= thirtyDaysFromNow
    }
}

// MARK: - Document Type
enum DocumentType: String, Codable, CaseIterable {
    case bol = "bol"                    // Bill of Lading
    case eld = "eld"                    // Electronic Logging Device
    case leaseContract = "lease_contract" // Contrato de Arrendamiento
    case insurance = "insurance"        // Seguro
    case inspection = "inspection"      // Inspección
    case registration = "registration"  // Registro del vehículo
    case permits = "permits"            // Permisos
    case maintenance = "maintenance"    // Mantenimiento
    case fuelReceipt = "fuel_receipt"   // Recibo de combustible
    case invoice = "invoice"            // Factura
    case receipt = "receipt"            // Recibo
    case taxForm = "tax_form"           // Formulario fiscal
    case other = "other"                // Otro
    
    var displayName: String {
        switch self {
        case .bol:
            return "BOL (Bill of Lading)"
        case .eld:
            return "ELD (Registro Electrónico)"
        case .leaseContract:
            return "Contrato de Arrendamiento"
        case .insurance:
            return "Seguro"
        case .inspection:
            return "Inspección"
        case .registration:
            return "Registro"
        case .permits:
            return "Permisos"
        case .maintenance:
            return "Mantenimiento"
        case .fuelReceipt:
            return "Recibo de Combustible"
        case .invoice:
            return "Factura"
        case .receipt:
            return "Recibo"
        case .taxForm:
            return "Formulario Fiscal"
        case .other:
            return "Otro"
        }
    }
    
    var requiresOCR: Bool {
        switch self {
        case .bol, .eld, .fuelReceipt, .invoice, .receipt:
            return true
        default:
            return false
        }
    }
}

// MARK: - Document Version Model
struct DocumentVersion: Codable, Identifiable {
    let id: UUID
    let documentId: UUID
    let version: Int
    let ocrText: String?
    let ocrConfidence: Double?
    let createdAt: Date
    let createdBy: UUID
    let changes: String?
    let fileUrl: String?
    
    var isLatestVersion: Bool {
        return true // TODO: Implementar lógica para determinar la última versión
    }
    
    var ocrQualityRating: OCRQuality {
        guard let confidence = ocrConfidence else { return .unknown }
        
        switch confidence {
        case 0.9...1.0:
            return .excellent
        case 0.7..<0.9:
            return .good
        case 0.5..<0.7:
            return .fair
        case 0.3..<0.5:
            return .poor
        default:
            return .unknown
        }
    }
}

// MARK: - OCR Quality Rating
enum OCRQuality: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .excellent:
            return "Excelente"
        case .good:
            return "Buena"
        case .fair:
            return "Regular"
        case .poor:
            return "Mala"
        case .unknown:
            return "Desconocida"
        }
    }
    
    var colorCode: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "orange"
        case .poor:
            return "red"
        case .unknown:
            return "gray"
        }
    }
}

// MARK: - Document Link Model
struct DocumentLink: Codable, Identifiable {
    let id: UUID
    let entity: LinkableEntity
    let entityId: UUID
    let documentId: UUID
    let relationshipType: DocumentRelationshipType
    let status: LinkStatus
    let createdAt: Date
    
    var isActive: Bool {
        return status == .active
    }
}

// MARK: - Linkable Entity
enum LinkableEntity: String, Codable, CaseIterable {
    case vehicle = "vehicle"
    case trip = "trip"
    case user = "user"
    case contract = "contract"
    case maintenance = "maintenance"
    case fuelRecord = "fuel_record"
}

// MARK: - Document Relationship Type
enum DocumentRelationshipType: String, Codable, CaseIterable {
    case primary = "primary"
    case supporting = "supporting"
    case required = "required"
    case optional = "optional"
    case reference = "reference"
    
    var displayName: String {
        switch self {
        case .primary:
            return "Principal"
        case .supporting:
            return "Apoyo"
        case .required:
            return "Requerido"
        case .optional:
            return "Opcional"
        case .reference:
            return "Referencia"
        }
    }
}

// MARK: - Link Status
enum LinkStatus: String, Codable, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case expired = "expired"
    case pending = "pending"
    
    var displayName: String {
        switch self {
        case .active:
            return "Activo"
        case .inactive:
            return "Inactivo"
        case .expired:
            return "Expirado"
        case .pending:
            return "Pendiente"
        }
    }
}

// MARK: - OCR Extracted Data
struct OCRExtractedData: Codable {
    let text: String
    let confidence: Double
    let fields: [String: String]? // Campo -> Valor extraído
    let rawData: [String: Any]?   // Datos completos del OCR
    
    var invoiceNumber: String? {
        return fields?["invoice_number"] ?? fields?["factura"]
    }
    
    var totalAmount: Double? {
        guard let amountString = fields?["total"] ?? fields?["monto"] else { return nil }
        return Double(amountString.replacingOccurrences(of: "$", with: ""))
    }
    
    var date: Date? {
        guard let dateString = fields?["date"] ?? fields?["fecha"] else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.date(from: dateString)
    }
}

// MARK: - Document with Versions
struct DocumentWithVersions: Codable, Identifiable {
    let document: Document
    let versions: [DocumentVersion]
    
    var latestVersion: DocumentVersion? {
        return versions.max(by: { $0.version < $1.version })
    }
    
    var latestOCRData: DocumentVersion? {
        return versions.compactMap { $0.ocrText != nil ? $0 : nil }.max(by: { $0.version < $1.version })
    }
    
    var hasValidOCR: Bool {
        return versions.contains { $0.ocrText != nil }
    }
}

// MARK: - Document Summary for Lists
struct DocumentSummary: Codable, Identifiable {
    let id: UUID
    let title: String
    let type: DocumentType
    let issuer: String?
    let issueDate: Date?
    let expiryDate: Date?
    let status: String
    let tags: [String]?
    
    var displayTitle: String {
        return title.isEmpty ? type.displayName : title
    }
    
    var statusColor: String {
        if isExpired { return "red" }
        if isExpiringSoon { return "orange" }
        return "green"
    }
}

// MARK: - Document Storage Info
struct DocumentStorage: Codable {
    let id: UUID
    let documentId: UUID
    let fileName: String
    let fileSize: Int64
    let mimeType: String
    let storageUrl: String
    let uploadedAt: Date
    let uploadedBy: UUID
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.style = .default
        return formatter.string(fromByteCount: fileSize)
    }
    
    var isImageFile: Bool {
        return mimeType.hasPrefix("image/")
    }
    
    var isPDFFile: Bool {
        return mimeType == "application/pdf"
    }
}

// MARK: - Contract Document Examples (Based on Evidence)
extension Document {
    static let contract115A: Document = Document(
        id: UUID(),
        typeCode: .leaseContract,
        title: "Contrato de Arrendamiento - Unidad 115A",
        issuer: "BUSINESS CARGO INC",
        issueDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 12))!,
        expiryDate: Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 12))!,
        hashIntegrity: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let contract305: Document = Document(
        id: UUID(),
        typeCode: .leaseContract,
        title: "Contrato de Arrendamiento - Unidad 305",
        issuer: "CHRISTIAN TUR GARCIA",
        issueDate: Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 12))!,
        expiryDate: Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 12))!,
        hashIntegrity: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}

// MARK: - Document Validation Result
struct DocumentValidationResult: Codable {
    let isValid: Bool
    let issues: [ValidationIssue]
    let suggestions: [String]
    let confidence: Double
    
    var validationScore: Double {
        if issues.isEmpty { return 1.0 }
        if issues.count <= 2 { return 0.8 }
        if issues.count <= 4 { return 0.6 }
        return 0.3
    }
}

// MARK: - Validation Issue
struct ValidationIssue: Codable {
    let severity: IssueSeverity
    let code: String
    let message: String
    let field: String?
    
    var displayMessage: String {
        return "[\(severity.displayName)] \(message)"
    }
}

// MARK: - Issue Severity
enum IssueSeverity: String, Codable, CaseIterable {
    case error = "error"
    case warning = "warning"
    case info = "info"
    
    var displayName: String {
        switch self {
        case .error:
            return "Error"
        case .warning:
            return "Advertencia"
        case .info:
            return "Info"
        }
    }
    
    var colorCode: String {
        switch self {
        case .error:
            return "red"
        case .warning:
            return "orange"
        case .info:
            return "blue"
        }
    }
}