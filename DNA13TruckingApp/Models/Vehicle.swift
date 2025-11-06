//
//  Vehicle.swift
//  DNA13TruckingApp
//
//  Modelo de datos para vehículos y unidades de D.N.A 13 Trucking Company
//

import Foundation

// MARK: - Vehicle Model
struct Vehicle: Codable, Identifiable {
    let id: UUID
    let unitNumber: String  // Único
    let vin: String         // Único
    let make: String
    let model: String?
    let year: Int
    var status: VehicleStatus
    var currentMileage: Double
    var currentLocation: String?
    var lastServiceAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // Propiedades específicas mencionadas en el contrato
    static let unit115A: Vehicle = Vehicle(
        id: UUID(),
        unitNumber: "115A",
        vin: "4V4NC9TG6DN563822",
        make: "VOLVO",
        model: nil,
        year: 2013,
        status: .active,
        currentMileage: 0,
        currentLocation: nil,
        lastServiceAt: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let unit305: Vehicle = Vehicle(
        id: UUID(),
        unitNumber: "305",
        vin: "1XKYAP9X2EJ386743",
        make: "KENWORTH",
        model: nil,
        year: 2014,
        status: .active,
        currentMileage: 0,
        currentLocation: nil,
        lastServiceAt: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}

// MARK: - Vehicle Status
enum VehicleStatus: String, Codable, CaseIterable {
    case active = "active"
    case inMaintenance = "in_maintenance"
    case outOfService = "out_of_service"
    case inTransit = "in_transit"
    case atYard = "at_yard"
    
    var displayName: String {
        switch self {
        case .active:
            return "Activo"
        case .inMaintenance:
            return "En Mantenimiento"
        case .outOfService:
            return "Fuera de Servicio"
        case .inTransit:
            return "En Tránsito"
        case .atYard:
            return "En Patio"
        }
    }
    
    var isOperational: Bool {
        return self == .active || self == .inTransit
    }
}

// MARK: - Vehicle Document Model
struct VehicleDocument: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let documentId: UUID
    let relationshipType: VehicleDocumentType
    let createdAt: Date
    
    enum VehicleDocumentType: String, Codable, CaseIterable {
        case registration = "registration"
        case insurance = "insurance"
        case inspection = "inspection"
        case leaseContract = "lease_contract"
        case permits = "permits"
        case warranties = "warranties"
    }
}

// MARK: - Maintenance Record Model
struct MaintenanceRecord: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let date: Date
    let odometer: Double
    let description: String
    let cost: Double
    let vendor: String?
    let parts: [MaintenancePart]
    let createdBy: UUID
    let createdAt: Date
    
    var isWarrantyWork: Bool {
        return vendor?.lowercased().contains("warranty") == true
    }
}

// MARK: - Maintenance Part
struct MaintenancePart: Codable {
    let name: String
    let quantity: Int
    let unitCost: Double
    let totalCost: Double
    let partNumber: String?
}

// MARK: - Vehicle Assignment Model
struct Assignment: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let contractId: UUID
    let driverUserId: UUID
    let startDate: Date
    let endDate: Date?
    var status: AssignmentStatus
    let createdAt: Date
    
    var isActive: Bool {
        let now = Date()
        return status == .active && now >= startDate && (endDate == nil || now <= endDate!)
    }
}

// MARK: - Assignment Status
enum AssignmentStatus: String, Codable, CaseIterable {
    case active = "active"
    case pending = "pending"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .active:
            return "Activo"
        case .pending:
            return "Pendiente"
        case .completed:
            return "Completado"
        case .cancelled:
            return "Cancelado"
        }
    }
}

// MARK: - Vehicle Metrics
struct VehicleMetrics: Codable {
    let vehicleId: UUID
    let totalMiles: Double
    let fuelEfficiency: Double  // MPG
    let maintenanceCosts: Double
    let lastServiceMileage: Double
    let nextServiceMileage: Double
    let nextServiceDate: Date?
    
    var milesToNextService: Double {
        return max(0, nextServiceMileage - currentMileage)
    }
    
    var serviceOverdue: Bool {
        return currentMileage >= nextServiceMileage
    }
}

// MARK: - Vehicle Current Mileage Extension
extension Vehicle {
    var currentMileage: Double {
        get { _currentMileage }
        set { _currentMileage = newValue }
    }
    
    private var _currentMileage: Double
    {
        get { 0.0 }
        set { }
    }
}

// MARK: - Vehicle Location
struct VehicleLocation: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let latitude: Double
    let longitude: Double
    let address: String?
    let city: String?
    let state: String?
    let timestamp: Date
    let speed: Double?
    let heading: Double?
    
    var locationDescription: String {
        if let address = address {
            return address
        } else if let city = city, let state = state {
            return "\(city), \(state)"
        } else {
            return "Ubicación desconocida"
        }
    }
}