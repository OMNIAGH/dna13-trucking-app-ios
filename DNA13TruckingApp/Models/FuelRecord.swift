import Foundation
import SwiftData

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
    
    init(id: UUID = UUID(), vehicleId: UUID, tripId: UUID? = nil, date: Date, station: String? = nil, city: String, state: String, gallons: Double, amount: Double, unitPrice: Double? = nil) {
        self.id = id
        self.vehicleId = vehicleId
        self.tripId = tripId
        self.date = date
        self.station = station
        self.city = city
        self.state = state
        self.gallons = gallons
        self.amount = amount
        self.unitPrice = unitPrice
        self.createdAt = Date()
    }
}