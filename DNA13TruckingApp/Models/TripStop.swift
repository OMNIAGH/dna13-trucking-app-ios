import Foundation
import SwiftData

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
    
    init(id: UUID = UUID(), tripId: UUID, stopSequence: Int, stopType: String, city: String, state: String, timestamp: Date, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.tripId = tripId
        self.stopSequence = stopSequence
        self.stopType = stopType
        self.city = city
        self.state = state
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
    }
}