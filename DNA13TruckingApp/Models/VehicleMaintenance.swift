//
//  VehicleMaintenance.swift
//  DNA13TruckingApp
//
//  Modelo para vehículos y mantenimiento del sistema D.N.A 13 Trucking Company
//

import Foundation

// MARK: - Vehicle Model
struct Vehicle: Codable, Identifiable {
    let id: UUID
    let unitNumber: String
    let vin: String
    let make: String
    let model: String
    let year: Int
    let status: VehicleStatus
    let currentMileage: Int
    let currentLocation: String?
    let lastServiceAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // Propiedades computadas para UI
    var displayName: String {
        return "\(unitNumber) - \(make) \(model) (\(year))"
    }
    
    var isActive: Bool {
        return status == .active
    }
    
    var isInMaintenance: Bool {
        return status == .in_maintenance
    }
    
    var isOutOfService: Bool {
        return status == .out_of_service
    }
    
    var daysSinceLastService: Int {
        guard let lastService = lastServiceAt else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastService, to: Date())
        return abs(components.day ?? 0)
    }
    
    var isServiceDue: Bool {
        return daysSinceLastService >= 90 // Servicio cada 90 días
    }
    
    var mileageStatus: MileageStatus {
        let currentYear = Calendar.current.component(.year, from: Date())
        let age = currentYear - year
        
        switch age {
        case 0...3:
            return .excellent
        case 4...7:
            return .good
        case 8...12:
            return .fair
        default:
            return .poor
        }
    }
}

// MARK: - Vehicle Status
enum VehicleStatus: String, Codable, CaseIterable {
    case active = "active"
    case in_maintenance = "in_maintenance"
    case out_of_service = "out_of_service"
    case loading = "loading"
    case unloading = "unloading"
    
    var displayName: String {
        switch self {
        case .active:
            return "Activo"
        case .in_maintenance:
            return "En Mantenimiento"
        case .out_of_service:
            return "Fuera de Servicio"
        case .loading:
            return "Cargando"
        case .unloading:
            return "Descargando"
        }
    }
    
    var color: String {
        switch self {
        case .active:
            return "#3D503C" // Verde corporativo
        case .in_maintenance:
            return "#FF9030" // Naranja corporativo
        case .out_of_service:
            return "#FF0000" // Rojo
        case .loading:
            return "#0066CC" // Azul
        case .unloading:
            return "#6600CC" // Púrpura
        }
    }
}

// MARK: - Mileage Status
enum MileageStatus: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent:
            return "Excelente"
        case .good:
            return "Bueno"
        case .fair:
            return "Regular"
        case .poor:
            return "Malo"
        }
    }
    
    var color: String {
        switch self {
        case .excellent:
            return "#3D503C" // Verde corporativo
        case .good:
            return "#66BB6A" // Verde claro
        case .fair:
            return "#FF9030" // Naranja corporativo
        case .poor:
            return "#FF0000" // Rojo
        }
    }
}

// MARK: - Vehicle Document Model
struct VehicleDocument: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let documentId: UUID
    let relationshipType: VehicleDocumentType
    let expiryDate: Date?
    let status: DocumentStatus
    let createdAt: Date
    let updatedAt: Date
    
    // Propiedades computadas
    var isExpiring: Bool {
        guard let expiry = expiryDate else { return false }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiry)
        return (components.day ?? 0) <= 30
    }
    
    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return expiry < Date()
    }
    
    var daysUntilExpiry: Int {
        guard let expiry = expiryDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiry)
        return max(0, components.day ?? 0)
    }
}

// MARK: - Vehicle Document Type
enum VehicleDocumentType: String, Codable, CaseIterable {
    case registration = "registration"
    case insurance = "insurance"
    case inspection = "inspection"
    case lease_contract = "lease_contract"
    case permit = "permit"
    case title = "title"
    case warranty = "warranty"
    case recall_notice = "recall_notice"
    
    var displayName: String {
        switch self {
        case .registration:
            return "Registro"
        case .insurance:
            return "Seguro"
        case .inspection:
            return "Inspección"
        case .lease_contract:
            return "Contrato de Arrendamiento"
        case .permit:
            return "Permiso"
        case .title:
            return "Título"
        case .warranty:
            return "Garantía"
        case .recall_notice:
            return "Aviso de Retirada"
        }
    }
    
    var isRegulatory: Bool {
        return [registration, insurance, inspection, permit].contains(self)
    }
}

// MARK: - Document Status
enum DocumentStatus: String, Codable, CaseIterable {
    case valid = "valid"
    case expired = "expired"
    case expiring_soon = "expiring_soon"
    case pending = "pending"
    case suspended = "suspended"
    
    var displayName: String {
        switch self {
        case .valid:
            return "Válido"
        case .expired:
            return "Expirado"
        case .expiring_soon:
            return "Por Expirar"
        case .pending:
            return "Pendiente"
        case .suspended:
            return "Suspendido"
        }
    }
    
    var color: String {
        switch self {
        case .valid:
            return "#3D503C" // Verde corporativo
        case .expired:
            return "#FF0000" // Rojo
        case .expiring_soon:
            return "#FF9030" // Naranja corporativo
        case .pending:
            return "#666666" // Gris
        case .suspended:
            return "#660000" // Rojo oscuro
        }
    }
}

// MARK: - Maintenance Record Model
struct MaintenanceRecord: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let date: Date
    let odometer: Int
    let description: String
    let cost: Double
    let vendor: String
    let partsJson: String?
    let maintenanceType: MaintenanceType
    let status: MaintenanceStatus
    let createdBy: UUID?
    let createdAt: Date
    
    // Propiedades computadas
    var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: cost)) ?? "$0.00"
    }
    
    var isPreventive: Bool {
        return maintenanceType == .preventive
    }
    
    var isCorrective: Bool {
        return maintenanceType == .corrective
    }
    
    var partsCount: Int {
        guard let partsData = partsJson?.data(using: .utf8),
              let parts = try? JSONSerialization.jsonObject(with: partsData) as? [String: Any] else {
            return 0
        }
        return parts.count
    }
}

// MARK: - Maintenance Type
enum MaintenanceType: String, Codable, CaseIterable {
    case preventive = "preventive"
    case corrective = "corrective"
    case emergency = "emergency"
    case warranty = "warranty"
    case inspection = "inspection"
    
    var displayName: String {
        switch self {
        case .preventive:
            return "Preventivo"
        case .corrective:
            return "Correctivo"
        case .emergency:
            return "Emergencia"
        case .warranty:
            return "Garantía"
        case .inspection:
            return "Inspección"
        }
    }
    
    var color: String {
        switch self {
        case .preventive:
            return "#3D503C" // Verde corporativo
        case .corrective:
            return "#FF9030" // Naranja corporativo
        case .emergency:
            return "#FF0000" // Rojo
        case .warranty:
            return "#0066CC" // Azul
        case .inspection:
            return "#6600CC" // Púrpura
        }
    }
}

// MARK: - Maintenance Status
enum MaintenanceStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case in_progress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .scheduled:
            return "Programado"
        case .in_progress:
            return "En Progreso"
        case .completed:
            return "Completado"
        case .cancelled:
            return "Cancelado"
        }
    }
}

// MARK: - Vehicle Assignment Model
struct VehicleAssignment: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let contractId: UUID?
    let driverUserId: UUID
    let startDate: Date
    let endDate: Date?
    let status: AssignmentStatus
    let notes: String?
    let createdAt: Date
    
    // Propiedades computadas
    var isActive: Bool {
        return status == .active && startDate <= Date() && (endDate == nil || endDate! >= Date())
    }
    
    var daysAssigned: Int {
        let end = endDate ?? Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: end)
        return abs(components.day ?? 0)
    }
    
    var isExpiringSoon: Bool {
        guard let end = endDate else { return false }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: end)
        return (components.day ?? 0) <= 7
    }
}

// MARK: - Assignment Status
enum AssignmentStatus: String, Codable, CaseIterable {
    case active = "active"
    case completed = "completed"
    case suspended = "suspended"
    case pending = "pending"
    
    var displayName: String {
        switch self {
        case .active:
            return "Activo"
        case .completed:
            return "Completado"
        case .suspended:
            return "Suspendido"
        case .pending:
            return "Pendiente"
        }
    }
}

// MARK: - Maintenance Reminder Model
struct MaintenanceReminder: Identifiable {
    let id: UUID
    let vehicleId: UUID
    let type: MaintenanceReminderType
    let title: String
    let description: String
    let dueDate: Date
    let priority: MaintenancePriority
    let isOverdue: Bool
    let createdAt: Date
    
    // Propiedades computadas
    var daysUntilDue: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return max(0, components.day ?? 0)
    }
    
    var isDue: Bool {
        return daysUntilDue == 0
    }
}

// MARK: - Maintenance Reminder Type
enum MaintenanceReminderType: String, CaseIterable {
    case oilChange = "oil_change"
    case tireRotation = "tire_rotation"
    case brakeInspection = "brake_inspection"
    case engineDiagnostic = "engine_diagnostic"
    case transmissionService = "transmission_service"
    case coolingSystem = "cooling_system"
    case annualInspection = "annual_inspection"
    
    var displayName: String {
        switch self {
        case .oilChange:
            return "Cambio de Aceite"
        case .tireRotation:
            return "Rotación de Llantas"
        case .brakeInspection:
            return "Inspección de Frenos"
        case .engineDiagnostic:
            return "Diagnóstico de Motor"
        case .transmissionService:
            return "Servicio de Transmisión"
        case .coolingSystem:
            return "Sistema de Enfriamiento"
        case .annualInspection:
            return "Inspección Anual"
        }
    }
}

// MARK: - Maintenance Priority
enum MaintenancePriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low:
            return "Baja"
        case .medium:
            return "Media"
        case .high:
            return "Alta"
        case .critical:
            return "Crítica"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "#3D503C" // Verde corporativo
        case .medium:
            return "#FF9030" // Naranja corporativo
        case .high:
            return "#FF6600" // Naranja oscuro
        case .critical:
            return "#FF0000" // Rojo
        }
    }
}