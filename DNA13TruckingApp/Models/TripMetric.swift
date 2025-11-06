import Foundation
import SwiftData

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
    
    init(id: UUID = UUID(), tripId: UUID, totalMiles: Double = 0, driveTimeMinutes: Int = 0, idleTimeMinutes: Int = 0, fuelVolumeGal: Double = 0, fuelCost: Double = 0, mpg: Double? = nil) {
        self.id = id
        self.tripId = tripId
        self.totalMiles = totalMiles
        self.driveTimeMinutes = driveTimeMinutes
        self.idleTimeMinutes = idleTimeMinutes
        self.fuelVolumeGal = fuelVolumeGal
        self.fuelCost = fuelCost
        self.mpg = mpg
        self.createdAt = Date()
    }
}