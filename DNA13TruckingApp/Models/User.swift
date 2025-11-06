//
//  User.swift
//  DNA13TruckingApp
//
//  Modelo de datos para usuarios del sistema D.N.A 13 Trucking Company
//

import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: UUID
    let username: String
    let email: String
    let phone: String?
    var status: UserStatus
    let passwordHash: String
    let biometricIdRef: String?
    var lastLoginAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // Propiedades computadas para UI
    var fullName: String {
        // TODO: Implementar cuando se defina estructura de nombres
        return username
    }
    
    var isActive: Bool {
        return status == .active
    }
}

// MARK: - User Status
enum UserStatus: String, Codable, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case suspended = "suspended"
    case pending = "pending"
    
    var displayName: String {
        switch self {
        case .active:
            return "Activo"
        case .inactive:
            return "Inactivo"
        case .suspended:
            return "Suspendido"
        case .pending:
            return "Pendiente"
        }
    }
}

// MARK: - Role Model
struct Role: Codable, Identifiable {
    let id: UUID
    let code: String
    let name: String
    let description: String?
    
    enum RoleCode: String, CaseIterable {
        case driver = "driver"
        case dispatcher = "dispatcher"
        case manager = "manager"
        case admin = "admin"
    }
}

// MARK: - UserRole (Junction Table)
struct UserRole: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let roleId: UUID
    let assignedAt: Date
}

// MARK: - Permission Model
struct Permission: Codable, Identifiable {
    let id: UUID
    let code: String
    let name: String
    let description: String?
    
    enum PermissionCode: String, CaseIterable {
        // Viajes
        case tripsCreate = "trips.create"
        case tripsRead = "trips.read"
        case tripsUpdate = "trips.update"
        case tripsDelete = "trips.delete"
        case tripsApprove = "trips.approve"
        
        // Vehículos
        case vehiclesCreate = "vehicles.create"
        case vehiclesRead = "vehicles.read"
        case vehiclesUpdate = "vehicles.update"
        case vehiclesDelete = "vehicles.delete"
        
        // Documentos
        case documentsCreate = "documents.create"
        case documentsRead = "documents.read"
        case documentsUpdate = "documents.update"
        case documentsDelete = "documents.delete"
        case documentsApprove = "documents.approve"
        
        // Combustible
        case fuelCreate = "fuel.create"
        case fuelRead = "fuel.read"
        case fuelUpdate = "fuel.update"
        case fuelApprove = "fuel.approve"
        
        // Costos
        case costsCreate = "costs.create"
        case costsRead = "costs.read"
        case costsUpdate = "costs.update"
        case costsDelete = "costs.delete"
        case costsApprove = "costs.approve"
        
        // Escrow
        case escrowRead = "escrow.read"
        case escrowUpdate = "escrow.update"
        case escrowApprove = "escrow.approve"
        
        // Reportes
        case reportsRead = "reports.read"
        case reportsCreate = "reports.create"
        case reportsApprove = "reports.approve"
    }
}

// MARK: - RolePermission (Junction Table)
struct RolePermission: Codable, Identifiable {
    let id: UUID
    let roleId: UUID
    let permissionId: UUID
}

// MARK: - UserBiometrics
struct UserBiometric: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let biometricType: BiometricType
    let templateRef: String
    let qualityScore: Double
    let enrolledAt: Date
    var revokedAt: Date?
    
    var isActive: Bool {
        return revokedAt == nil
    }
}

// MARK: - Biometric Type
enum BiometricType: String, Codable, CaseIterable {
    case touchId = "touch_id"
    case faceId = "face_id"
    case voiceId = "voice_id"
    
    var displayName: String {
        switch self {
        case .touchId:
            return "Touch ID"
        case .faceId:
            return "Face ID"
        case .voiceId:
            return "Voice ID"
        }
    }
}

// MARK: - Session Model
struct Session: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let tokenHash: String
    let createdAt: Date
    let expiresAt: Date
    let deviceInfo: String?
    
    var isValid: Bool {
        return Date() < expiresAt
    }
    
    var timeUntilExpiry: TimeInterval {
        return expiresAt.timeIntervalSinceNow
    }
}

// MARK: - User Profile Extension
extension User {
    func hasPermission(_ permission: Permission.PermissionCode, rolePermissions: [RolePermission], userRoles: [UserRole], roles: [Role], permissions: [Permission]) -> Bool {
        // Verificar si el usuario tiene el permiso a través de sus roles
        return true // TODO: Implementar lógica de verificación de permisos
    }
}