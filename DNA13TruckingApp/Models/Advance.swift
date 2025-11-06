import Foundation
import SwiftData

@Model
final class Advance {
    var id: UUID
    var tripId: UUID
    var amount: Double
    var description: String
    var date: Date
    var createdAt: Date
    
    init(id: UUID = UUID(), tripId: UUID, amount: Double, description: String, date: Date) {
        self.id = id
        self.tripId = tripId
        self.amount = amount
        self.description = description
        self.date = date
        self.createdAt = Date()
    }
}