//
//  Trip.swift
//  DNA13TruckingApp
//
//  Modelo de datos para viajes y seguimiento de D.N.A 13 Trucking Company
//

import Foundation

// MARK: - Trip Model
struct Trip: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let driverUserId: UUID
    let externalRef: String?
    let plannedStartAt: Date
    var actualStartAt: Date?
    var endAt: Date?
    let originAddress: String?
    let originCity: String?
    let originState: String?
    let destAddress: String?
    let destCity: String?
    let destState: String?
    let distanceMiles: Double?
    var status: TripStatus
    let createdAt: Date
    let updatedAt: Date
    
    // Propiedades específicas basadas en evidencia del estado de cuenta
    var routeDescription: String {
        guard let originCity = originCity, let originState = originState,
              let destCity = destCity, let destState = destState else {
            return "Ruta no definida"
        }
        return "\(originCity), \(originState) → \(destCity), \(destState)"
    }
    
    var isCompleted: Bool {
        return status == .completed
    }
    
    var inProgress: Bool {
        return status == .inTransit || status == .loaded
    }
}

// MARK: - Trip Status
enum TripStatus: String, Codable, CaseIterable {
    case planned = "planned"
    case loaded = "loaded"
    case inTransit = "in_transit"
    case delivered = "delivered"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .planned:
            return "Planificado"
        case .loaded:
            return "Cargado"
        case .inTransit:
            return "En Tránsito"
        case .delivered:
            return "Entregado"
        case .completed:
            return "Completado"
        case .cancelled:
            return "Cancelado"
        }
    }
}

// MARK: - Trip Stop Model
struct TripStop: Codable, Identifiable {
    let id: UUID
    let tripId: UUID
    let stopSequence: Int
    let stopType: TripStopType
    let city: String?
    let state: String?
    var timestamp: Date?
    let latitude: Double?
    let longitude: Double?
    let address: String?
    let notes: String?
    
    var isCompleted: Bool {
        return timestamp != nil
    }
    
    var locationDescription: String {
        if let address = address {
            return address
        } else if let city = city, let state = state {
            return "\(city), \(state)"
        } else {
            return "Ubicación no definida"
        }
    }
}

// MARK: - Trip Stop Type
enum TripStopType: String, Codable, CaseIterable {
    case pickup = "pickup"
    case drop = "drop"
    case fuel = "fuel"
    case rest = "rest"
    case inspection = "inspection"
    case breakdown = "breakdown"
    
    var displayName: String {
        switch self {
        case .pickup:
            return "Recogida"
        case .drop:
            return "Entrega"
        case .fuel:
            return "Combustible"
        case .rest:
            return "Descanso"
        case .inspection:
            return "Inspección"
        case .breakdown:
            return "Descompostura"
        }
    }
    
    var requiresCompletion: Bool {
        return self == .pickup || self == .drop || self == .fuel
    }
}

// MARK: - Trip Metrics Model
struct TripMetrics: Codable, Identifiable {
    let id: UUID
    let tripId: UUID
    var totalMiles: Double
    var driveTimeMinutes: Int
    var idleTimeMinutes: Int
    var fuelVolumeGal: Double
    var fuelCost: Double
    var mpg: Double?
    let createdAt: Date
    
    var totalTimeMinutes: Int {
        return driveTimeMinutes + idleTimeMinutes
    }
    
    var driveTimeHours: Double {
        return Double(driveTimeMinutes) / 60.0
    }
    
    var fuelCostPerGallon: Double {
        return fuelVolumeGal > 0 ? fuelCost / fuelVolumeGal : 0
    }
    
    var efficiencyRating: TripEfficiency {
        guard let mpg = mpg else { return .unknown }
        
        switch mpg {
        case 0..<4:
            return .poor
        case 4..<6:
            return .fair
        case 6..<8:
            return .good
        case 8..<10:
            return .excellent
        default:
            return .unknown
        }
    }
}

// MARK: - Trip Efficiency Rating
enum TripEfficiency: String, CaseIterable {
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

// MARK: - Trip with Stops (Composite Model)
struct TripWithStops: Codable, Identifiable {
    let trip: Trip
    let stops: [TripStop]
    let metrics: TripMetrics?
    
    var originStop: TripStop? {
        return stops.first { $0.stopType == .pickup }
    }
    
    var destinationStop: TripStop? {
        return stops.reversed().first { $0.stopType == .drop }
    }
    
    var fuelStops: [TripStop] {
        return stops.filter { $0.stopType == .fuel }
    }
    
    var completedStops: Int {
        return stops.filter { $0.isCompleted }.count
    }
    
    var totalStops: Int {
        return stops.count
    }
    
    var completionPercentage: Double {
        return totalStops > 0 ? Double(completedStops) / Double(totalStops) * 100 : 0
    }
}

// MARK: - Real Trip Examples (Based on Statement Evidence)
extension Trip {
    static let exampleMedleyToSmyrna: Trip = Trip(
        id: UUID(),
        vehicleId: UUID(), // Unit 305
        driverUserId: UUID(),
        externalRef: nil,
        plannedStartAt: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29))!,
        actualStartAt: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29))!,
        endAt: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29))!,
        originAddress: nil,
        originCity: "MEDLEY",
        originState: "FL",
        destAddress: nil,
        destCity: "SMYRNA",
        destState: "GA",
        distanceMiles: nil,
        status: .completed,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let exampleAtlantaToBurnside: Trip = Trip(
        id: UUID(),
        vehicleId: UUID(), // Unit 305
        driverUserId: UUID(),
        externalRef: nil,
        plannedStartAt: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30))!,
        actualStartAt: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30))!,
        endAt: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30))!,
        originAddress: nil,
        originCity: "ATLANTA",
        originState: "GA",
        destAddress: nil,
        destCity: "BURNSIDE",
        destState: "KY",
        distanceMiles: nil,
        status: .completed,
        createdAt: Date(),
        updatedAt: Date()
    )
}

// MARK: - Trip Statistics
struct TripStatistics: Codable {
    let totalTrips: Int
    let completedTrips: Int
    let totalMiles: Double
    let averageMPG: Double
    let totalFuelCost: Double
    let totalDriveTime: TimeInterval
    let averageTripDuration: TimeInterval
    
    var completionRate: Double {
        return totalTrips > 0 ? Double(completedTrips) / Double(totalTrips) * 100 : 0
    }
    
    var efficiencyTrend: EfficiencyTrend {
        // TODO: Calcular tendencia basado en datos históricos
        return .stable
    }
}

// MARK: - Efficiency Trend
enum EfficiencyTrend: String, CaseIterable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    
    var displayName: String {
        switch self {
        case .improving:
            return "Mejorando"
        case .declining:
            return "Empeorando"
        case .stable:
            return "Estable"
        }
    }
}