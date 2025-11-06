import Foundation
import SwiftData

@Model
final class Role {
    var id: UUID
    var code: String
    var name: String
    var description: String?
    var createdAt: Date
    
    init(id: UUID = UUID(), code: String, name: String, description: String? = nil) {
        self.id = id
        self.code = code
        self.name = name
        self.description = description
        self.createdAt = Date()
    }
}