import Foundation
import SwiftData

@Model
final class EscrowAccount {
    var id: UUID
    var contractId: UUID
    var balance: Double
    var interestPolicy: String?
    var accountingStatus: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), contractId: UUID, balance: Double = 0, interestPolicy: String? = nil, accountingStatus: String = "active") {
        self.id = id
        self.contractId = contractId
        self.balance = balance
        self.interestPolicy = interestPolicy
        self.accountingStatus = accountingStatus
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}