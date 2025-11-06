import Foundation
import SwiftData

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
    
    init(id: UUID = UUID(), documentId: UUID, version: Int, ocrText: String? = nil, ocrConfidence: Double? = nil, fileUri: String? = nil, createdBy: UUID) {
        self.id = id
        self.documentId = documentId
        self.version = version
        self.ocrText = ocrText
        self.ocrConfidence = ocrConfidence
        self.fileUri = fileUri
        self.createdAt = Date()
        self.createdBy = createdBy
    }
}