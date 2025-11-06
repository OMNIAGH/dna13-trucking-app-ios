import Foundation
import SwiftData

@Model
final class Deduction {
    var id: UUID
    var tripId: UUID
    var amount: Double
    var category: String
    var description: String
    var date: Date
    var createdAt: Date
    
    init(id: UUID = UUID(), tripId: UUID, amount: Double, category: String, description: String, date: Date) {
        self.id = id
        self.tripId = tripId
        self.amount = amount
        self.category = category
        self.description = description
        self.date = date
        self.createdAt = Date()
    }
}