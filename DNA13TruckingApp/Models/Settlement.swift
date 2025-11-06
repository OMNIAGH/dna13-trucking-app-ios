import Foundation
import SwiftData

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
    
    init(id: UUID = UUID(), unitId: UUID, periodStart: Date, periodEnd: Date, totalGross: Double = 0, totalDeductions: Double = 0, totalFuel: Double = 0, netAmount: Double, issuedAt: Date? = nil, status: String = "draft") {
        self.id = id
        self.unitId = unitId
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.totalGross = totalGross
        self.totalDeductions = totalDeductions
        self.totalFuel = totalFuel
        self.netAmount = netAmount
        self.issuedAt = issuedAt
        self.status = status
        self.createdAt = Date()
    }
}