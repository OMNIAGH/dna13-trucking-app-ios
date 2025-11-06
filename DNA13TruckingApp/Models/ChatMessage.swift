//
//  ChatMessage.swift
//  DNA13TruckingApp
//
//  Modelo para sistema de chat y comunicaciones del sistema D.N.A 13 Trucking Company
//

import Foundation

// MARK: - Chat Message Model
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let conversationId: String
    let senderUserId: UUID
    let encryptedBodyJson: String
    let sentAt: Date
    let messageType: MessageType
    let isRead: Bool
    let createdAt: Date
    
    // Propiedades computadas para UI
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: sentAt)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: sentAt)
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(sentAt)
    }
    
    var isFromCurrentUser: Bool {
        // Esta propiedad se usará en el ViewModel para determinar si el mensaje es del usuario actual
        return false // Placeholder
    }
}

// MARK: - Message Type
enum MessageType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case document = "document"
    case location = "location"
    case alert = "alert"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .text:
            return "Texto"
        case .image:
            return "Imagen"
        case .document:
            return "Documento"
        case .location:
            return "Ubicación"
        case .alert:
            return "Alerta"
        case .system:
            return "Sistema"
        }
    }
    
    var icon: String {
        switch self {
        case .text:
            return "message"
        case .image:
            return "photo"
        case .document:
            return "doc"
        case .location:
            return "location"
        case .alert:
            return "exclamationmark.triangle"
        case .system:
            return "info.circle"
        }
    }
}

// MARK: - Message Attachment Model
struct MessageAttachment: Codable, Identifiable {
    let id: UUID
    let messageId: UUID
    let documentId: UUID?
    let fileUri: String
    let hashIntegrity: String
    let fileName: String
    let fileSize: Int
    let mimeType: String
    let createdAt: Date
    
    // Propiedades computadas
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.style = .memory
        return formatter.string(fromByteCount: Int64(fileSize))
    }
    
    var isImage: Bool {
        return mimeType.hasPrefix("image/")
    }
    
    var isPDF: Bool {
        return mimeType == "application/pdf"
    }
    
    var isDocument: Bool {
        return mimeType.hasPrefix("application/") || mimeType.hasPrefix("text/")
    }
}

// MARK: - Notification Model
struct Notification: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let type: NotificationType
    let title: String
    let body: String
    let payloadJson: String
    let status: NotificationStatus
    let priority: NotificationPriority
    let createdAt: Date
    let deliveredAt: Date?
    let readAt: Date?
    
    // Propiedades computadas
    var isRead: Bool {
        return readAt != nil
    }
    
    var isDelivered: Bool {
        return deliveredAt != nil
    }
    
    var timeAgo: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear], from: createdAt, to: now)
        
        if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks) semana\(weeks == 1 ? "" : "s")"
        } else if let days = components.day, days > 0 {
            return "\(days) día\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hora\(hours == 1 ? "" : "s")"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minuto\(minutes == 1 ? "" : "s")"
        } else {
            return "Ahora mismo"
        }
    }
}

// MARK: - Notification Type
enum NotificationType: String, Codable, CaseIterable {
    case tripCreated = "trip_created"
    case tripUpdated = "trip_updated"
    case stopUpdate = "stop_update"
    case documentUploaded = "document_uploaded"
    case settlementIssued = "settlement_issued"
    case escrowDeposit = "escrow_deposit"
    case escrowInterest = "escrow_interest"
    case complianceAlert = "compliance_alert"
    case maintenanceReminder = "maintenance_reminder"
    case fuelAlert = "fuel_alert"
    case weatherAlert = "weather_alert"
    case trafficAlert = "traffic_alert"
    case aiRecommendation = "ai_recommendation"
    case systemUpdate = "system_update"
    
    var displayName: String {
        switch self {
        case .tripCreated:
            return "Viaje Creado"
        case .tripUpdated:
            return "Viaje Actualizado"
        case .stopUpdate:
            return "Actualización de Parada"
        case .documentUploaded:
            return "Documento Subido"
        case .settlementIssued:
            return "Liquidación Emitida"
        case .escrowDeposit:
            return "Depósito Escrow"
        case .escrowInterest:
            return "Interés Escrow"
        case .complianceAlert:
            return "Alerta de Cumplimiento"
        case .maintenanceReminder:
            return "Recordatorio de Mantenimiento"
        case .fuelAlert:
            return "Alerta de Combustible"
        case .weatherAlert:
            return "Alerta Meteorológica"
        case .trafficAlert:
            return "Alerta de Tráfico"
        case .aiRecommendation:
            return "Recomendación IA"
        case .systemUpdate:
            return "Actualización del Sistema"
        }
    }
    
    var icon: String {
        switch self {
        case .tripCreated, .tripUpdated:
            return "truck"
        case .stopUpdate:
            return "location"
        case .documentUploaded:
            return "doc"
        case .settlementIssued:
            return "dollarsign.circle"
        case .escrowDeposit, .escrowInterest:
            return "banknote"
        case .complianceAlert:
            return "exclamationmark.triangle"
        case .maintenanceReminder:
            return "wrench"
        case .fuelAlert:
            return "fuelpump"
        case .weatherAlert:
            return "cloud.sun"
        case .trafficAlert:
            return "car"
        case .aiRecommendation:
            return "brain"
        case .systemUpdate:
            return "arrow.clockwise"
        }
    }
}

// MARK: - Notification Status
enum NotificationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case sent = "sent"
    case delivered = "delivered"
    case read = "read"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pendiente"
        case .sent:
            return "Enviado"
        case .delivered:
            return "Entregado"
        case .read:
            return "Leído"
        case .failed:
            return "Fallido"
        case .cancelled:
            return "Cancelado"
        }
    }
}

// MARK: - Notification Priority
enum NotificationPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low:
            return "Baja"
        case .normal:
            return "Normal"
        case .high:
            return "Alta"
        case .urgent:
            return "Urgente"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "#3D503C" // Verde corporativo
        case .normal:
            return "#666666" // Gris
        case .high:
            return "#FF9030" // Naranja corporativo
        case .urgent:
            return "#FF0000" // Rojo
        }
    }
}

// MARK: - Conversation Model
struct Conversation: Identifiable, Codable {
    let id: String
    let vehicleId: UUID?
    let tripId: UUID?
    let type: ConversationType
    let title: String
    let participants: [UUID]
    let lastMessageAt: Date?
    let isActive: Bool
    let createdAt: Date
    
    // Propiedades computadas
    var isVehicleBased: Bool {
        return vehicleId != nil
    }
    
    var isTripBased: Bool {
        return tripId != nil
    }
    
    var participantCount: Int {
        return participants.count
    }
}

// MARK: - Conversation Type
enum ConversationType: String, Codable, CaseIterable {
    case vehicle = "vehicle"
    case trip = "trip"
    case group = "group"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .vehicle:
            return "Vehículo"
        case .trip:
            return "Viaje"
        case .group:
            return "Grupo"
        case .system:
            return "Sistema"
        }
    }
}