//
//  Models.swift
//  DNA13TruckingApp
//
//  Created by DNA13 Team
//

import Foundation
import SwiftData

// Modelos de usuarios y seguridad
@Model
final class Role {
    var id: UUID
    var code: String
    var name: String
    var description: String?
    var createdAt: Date
}

@Model
final class Permission {
    var id: UUID
    var code: String
    var name: String
    var description: String?
    var createdAt: Date
}

// Modelos de documentos
@Model
final class DocumentVersion {
    var id: UUID
    var documentId: UUID
    var version: Int
    var ocrText: String?
    var ocrConfidence: Double?
    var fileUri: String?
    var createdAt: Date
    var createdBy: UUID
}

// Modelos de cuentas y transacciones
@Model
final class EscrowAccount {
    var id: UUID
    var contractId: UUID
    var balance: Double
    var interestPolicy: String?
    var accountingStatus: String
    var createdAt: Date
    var updatedAt: Date
}

@Model
final class FuelRecord {
    var id: UUID
    var vehicleId: UUID
    var tripId: UUID?
    var date: Date
    var station: String?
    var city: String
    var state: String
    var gallons: Double
    var amount: Double
    var unitPrice: Double?
    var createdAt: Date
}

// Modelos de viajes
@Model
final class TripStop {
    var id: UUID
    var tripId: UUID
    var stopSequence: Int
    var stopType: String
    var city: String
    var state: String
    var timestamp: Date
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date
}

@Model
final class TripMetric {
    var id: UUID
    var tripId: UUID
    var totalMiles: Double
    var driveTimeMinutes: Int
    var idleTimeMinutes: Int
    var fuelVolumeGal: Double
    var fuelCost: Double
    var mpg: Double?
    var createdAt: Date
}

// Modelos de gestión financiera
@Model
final class Advance {
    var id: UUID
    var tripId: UUID
    var amount: Double
    var description: String
    var date: Date
    var createdAt: Date
}

@Model
final class Deduction {
    var id: UUID
    var tripId: UUID
    var amount: Double
    var category: String
    var description: String
    var date: Date
    var createdAt: Date
}

@Model
final class Settlement {
    var id: UUID
    var unitId: UUID
    var periodStart: Date
    var periodEnd: Date
    var totalGross: Double
    var totalDeductions: Double
    var totalFuel: Double
    var netAmount: Double
    var issuedAt: Date?
    var status: String
    var createdAt: Date
}