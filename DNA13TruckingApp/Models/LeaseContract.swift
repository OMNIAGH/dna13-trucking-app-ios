//
//  LeaseContract.swift
//  DNA13TruckingApp
//
//  Modelo para contratos de arrendamiento del sistema D.N.A 13 Trucking Company
//

import Foundation

// MARK: - Lease Contract Model
struct LeaseContract: Codable, Identifiable {
    let id: UUID
    let lessorName: String
    let lesseeName: String
    let vehicleId: UUID
    let startDate: Date
    let endDate: Date
    let termsSummary: String
    let insuranceRequirements: String
    let status: ContractStatus
    let createdAt: Date
    let updatedAt: Date
    
    // Propiedades computadas para UI
    var isActive: Bool {
        return status == .active && Date() >= startDate && Date() <= endDate
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: endDate)
        return max(0, components.day ?? 0)
    }
    
    var isExpiringSoon: Bool {
        return daysRemaining <= 30
    }
}

// MARK: - Contract Status
enum ContractStatus: String, Codable, CaseIterable {
    case active = "active"
    case expired = "expired"
    case terminated = "terminated"
    case pending = "pending"
    case suspended = "suspended"
    
    var displayName: String {
        switch self {
        case .active:
            return "Activo"
        case .expired:
            return "Expirado"
        case .terminated:
            return "Terminado"
        case .pending:
            return "Pendiente"
        case .suspended:
            return "Suspendido"
        }
    }
    
    var color: String {
        switch self {
        case .active:
            return "#3D503C" // Verde corporativo
        case .expired:
            return "#FF0000" // Rojo
        case .terminated:
            return "#666666" // Gris
        case .pending:
            return "#FF9030" // Naranja corporativo
        case .suspended:
            return "#FF6600" // Naranja oscuro
        }
    }
}

// MARK: - Escrow Transaction Model
struct EscrowTransaction: Codable, Identifiable {
    let id: UUID
    let escrowAccountId: UUID
    let type: EscrowTransactionType
    let amount: Double
    let description: String
    let date: Date
    let createdAt: Date
    
    // Propiedades computadas
    var isPositive: Bool {
        return amount > 0
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Escrow Transaction Type
enum EscrowTransactionType: String, Codable, CaseIterable {
    case deposit = "deposit"
    case withdrawal = "withdrawal"
    case interest = "interest"
    case charge = "charge"
    case adjustment = "adjustment"
    
    var displayName: String {
        switch self {
        case .deposit:
            return "Depósito"
        case .withdrawal:
            return "Retiro"
        case .interest:
            return "Interés"
        case .charge:
            return "Cargo"
        case .adjustment:
            return "Ajuste"
        }
    }
}

// MARK: - Payment Schedule Model
struct PaymentSchedule: Codable, Identifiable {
    let id: UUID
    let contractId: UUID
    let frequency: PaymentFrequency
    let amount: Double
    let dueDay: Int
    let startDate: Date
    let endDate: Date?
    let status: PaymentScheduleStatus
    let createdAt: Date
    
    // Propiedades computadas
    var nextDueDate: Date {
        let calendar = Calendar.current
        let now = Date()
        var components = DateComponents()
        components.day = dueDay
        
        var nextDue = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTimePreservingSmallerComponents) ?? now
        if calendar.compare(nextDue, to: now, toGranularity: .day) == .orderedSame {
            // Si es el mismo día, usar el próximo mes
            nextDue = calendar.date(byAdding: .month, value: 1, to: nextDue) ?? nextDue
        }
        
        return nextDue
    }
    
    var daysUntilDue: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextDueDate)
        return max(0, components.day ?? 0)
    }
}

// MARK: - Payment Frequency
enum PaymentFrequency: String, Codable, CaseIterable {
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    
    var displayName: String {
        switch self {
        case .weekly:
            return "Semanal"
        case .biweekly:
            return "Quincenal"
        case .monthly:
            return "Mensual"
        case .quarterly:
            return "Trimestral"
        }
    }
}

// MARK: - Payment Schedule Status
enum PaymentScheduleStatus: String, Codable, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case completed = "completed"
    case suspended = "suspended"
    
    var displayName: String {
        switch self {
        case .active:
            return "Activo"
        case .inactive:
            return "Inactivo"
        case .completed:
            return "Completado"
        case .suspended:
            return "Suspendido"
        }
    }
}

// MARK: - Compliance Event Model
struct ComplianceEvent: Codable, Identifiable {
    let id: UUID
    let contractId: UUID
    let eventType: ComplianceEventType
    let date: Date
    let description: String
    let status: ComplianceEventStatus
    let createdBy: UUID?
    let createdAt: Date
    
    // Propiedades computadas
    var isOverdue: Bool {
        return status == .pending && date < Date()
    }
    
    var isUpcoming: Bool {
        return status == .pending && date > Date() && date <= Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }
}

// MARK: - Compliance Event Type
enum ComplianceEventType: String, Codable, CaseIterable {
    case insuranceRenewal = "insurance_renewal"
    case inspectionDue = "inspection_due"
    case registrationRenewal = "registration_renewal"
    case dotInspection = "dot_inspection"
    case permitsExpiration = "permits_expiration"
    case complianceCheck = "compliance_check"
    case auditRequired = "audit_required"
    
    var displayName: String {
        switch self {
        case .insuranceRenewal:
            return "Renovación de Seguro"
        case .inspectionDue:
            return "Inspección Pendiente"
        case .registrationRenewal:
            return "Renovación de Registro"
        case .dotInspection:
            return "Inspección DOT"
        case .permitsExpiration:
            return "Vencimiento de Permisos"
        case .complianceCheck:
            return "Verificación de Cumplimiento"
        case .auditRequired:
            return "Auditoría Requerida"
        }
    }
    
    var priority: CompliancePriority {
        switch self {
        case .insuranceRenewal, .inspectionDue, .dotInspection:
            return .high
        case .registrationRenewal, .permitsExpiration:
            return .medium
        case .complianceCheck, .auditRequired:
            return .low
        }
    }
}

// MARK: - Compliance Priority
enum CompliancePriority: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high:
            return "Alta"
        case .medium:
            return "Media"
        case .low:
            return "Baja"
        }
    }
    
    var color: String {
        switch self {
        case .high:
            return "#FF0000"
        case .medium:
            return "#FF9030"
        case .low:
            return "#3D503C"
        }
    }
}

// MARK: - Compliance Event Status
enum ComplianceEventStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case completed = "completed"
    case overdue = "overdue"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendiente"
        case .completed:
            return "Completado"
        case .overdue:
            return "Vencido"
        case .cancelled:
            return "Cancelado"
        }
    }
}