import Foundation
import Supabase

// MARK: - Supabase Service
@MainActor
class SupabaseService: ObservableObject {
    private let supabase: SupabaseClient
    private let session: URLSession
    
    // Published properties for real-time updates
    @Published var isConnected = false
    @Published var currentUser: User?
    @Published var connectionStatus: String = "Disconnected"
    
    init() {
        // Configure URL session with custom configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        // Initialize Supabase client
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
        
        Task {
            await checkConnection()
        }
    }
    
    // MARK: - Connection Management
    func checkConnection() async {
        do {
            // Test connection with a simple query
            let response = try await supabase
                .from("users")
                .select("id")
                .limit(1)
                .execute()
            
            await MainActor.run {
                isConnected = !response.data.isEmpty || response.statusCode == 200
                connectionStatus = isConnected ? "Connected" : "Connection Failed"
            }
        } catch {
            await MainActor.run {
                isConnected = false
                connectionStatus = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String, fullName: String, role: UserRole = .driver) async throws -> User {
        let user = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        
        // Create user profile
        if let user = user.user {
            let profile = UserProfile(
                id: user.id,
                email: email,
                fullName: fullName,
                role: role.rawValue,
                createdAt: Date()
            )
            
            try await createUserProfile(profile)
        }
        
        return user.user!
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let user = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        await MainActor.run {
            self.currentUser = user.user
        }
        
        return user.user!
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        await MainActor.run {
            currentUser = nil
        }
    }
    
    func getCurrentUser() async -> User? {
        return try? await supabase.auth.getUser()
    }
    
    // MARK: - Database Operations
    func createUserProfile(_ profile: UserProfile) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        _ = try await supabase
            .from("users")
            .insert(json!)
            .execute()
    }
    
    func getUserProfile(userId: UUID) async throws -> UserProfile? {
        let response = try await supabase
            .from("users")
            .select("*")
            .eq("id", userId.uuidString)
            .maybeSingle()
        
        if let data = response.data.first {
            return try JSONDecoder().decode(UserProfile.self, from: JSONSerialization.data(withJSONObject: data))
        }
        
        return nil
    }
    
    func getVehicles() async throws -> [Vehicle] {
        let response = try await supabase
            .from("vehicles")
            .select("*")
            .order("unit_number")
            .execute()
        
        return try response.data.map { data in
            try JSONDecoder().decode(Vehicle.self, from: JSONSerialization.data(withJSONObject: data))
        }
    }
    
    func getCurrentTrip(vehicleId: UUID) async throws -> Trip? {
        let response = try await supabase
            .from("trips")
            .select("*")
            .eq("vehicle_id", vehicleId.uuidString)
            .in("status", ["planned", "loaded", "in_transit"])
            .order("created_at", ascending: false)
            .maybeSingle()
        
        if let data = response.data.first {
            return try JSONDecoder().decode(Trip.self, from: JSONSerialization.data(withJSONObject: data))
        }
        
        return nil
    }
    
    func getTripMetrics(tripId: UUID) async throws -> TripMetrics? {
        let response = try await supabase
            .from("trip_metrics")
            .select("*")
            .eq("trip_id", tripId.uuidString)
            .maybeSingle()
        
        if let data = response.data.first {
            return try JSONDecoder().decode(TripMetrics.self, from: JSONSerialization.data(withJSONObject: data))
        }
        
        return nil
    }
    
    func getFuelRecords(vehicleId: UUID, limit: Int = 10) async throws -> [FuelRecord] {
        let response = try await supabase
            .from("fuel_records")
            .select("*")
            .eq("vehicle_id", vehicleId.uuidString)
            .order("date", ascending: false)
            .limit(limit)
            .execute()
        
        return try response.data.map { data in
            try JSONDecoder().decode(FuelRecord.self, from: JSONSerialization.data(withJSONObject: data))
        }
    }
    
    func getRecentAlerts(userId: UUID, limit: Int = 20) async throws -> [Notification] {
        let response = try await supabase
            .from("notifications")
            .select("*")
            .eq("user_id", userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        return try response.data.map { data in
            try JSONDecoder().decode(Notification.self, from: JSONSerialization.data(withJSONObject: data))
        }
    }
    
    // MARK: - Edge Functions
    func callOpenAI(messages: [ChatMessage], userId: UUID, tripId: UUID? = nil, vehicleId: UUID? = nil) async throws -> OpenAIResponse {
        let request = OpenAIRequest(
            messages: messages,
            userId: userId.uuidString,
            tripId: tripId?.uuidString,
            vehicleId: vehicleId?.uuidString
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        let response = try await supabase.functions.invoke(
            "openai-proxy",
            parameters: json
        )
        
        return try JSONDecoder().decode(OpenAIResponse.self, from: JSONSerialization.data(withJSONObject: response))
    }
    
    func processDocumentOCR(ocrText: String, documentType: DocumentType, documentId: UUID?, userId: UUID) async throws -> OCRResponse {
        let request = OCRRequest(
            ocrText: ocrText,
            documentType: documentType.rawValue,
            documentId: documentId?.uuidString,
            userId: userId.uuidString
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        let response = try await supabase.functions.invoke(
            "document-ocr",
            parameters: json
        )
        
        return try JSONDecoder().decode(OCRResponse.self, from: JSONSerialization.data(withJSONObject: response))
    }
    
    func searchLoads(origin: String?, destination: String?, currentLocation: String, vehicleId: UUID, userId: UUID, maxDistance: Int = 500) async throws -> LoadSearchResponse {
        let request = LoadSearchRequest(
            origin: origin,
            destination: destination,
            currentLocation: currentLocation,
            vehicleId: vehicleId.uuidString,
            userId: userId.uuidString,
            maxDistance: maxDistance
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        let response = try await supabase.functions.invoke(
            "load-search",
            parameters: json
        )
        
        return try JSONDecoder().decode(LoadSearchResponse.self, from: JSONSerialization.data(withJSONObject: response))
    }
    
    func getPredictiveAlerts(vehicleId: UUID, userId: UUID, location: String) async throws -> AlertSystemResponse {
        let request = AlertRequest(
            vehicleId: vehicleId.uuidString,
            userId: userId.uuidString,
            location: location
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        let response = try await supabase.functions.invoke(
            "alert-system",
            parameters: json
        )
        
        return try JSONDecoder().decode(AlertSystemResponse.self, from: JSONSerialization.data(withJSONObject: response))
    }
    
    // MARK: - Storage Operations
    func uploadDocument(file: Data, fileName: String, documentType: DocumentType) async throws -> String {
        let path = "documents/\(documentType.rawValue)/\(Date().timeIntervalSince1970)-\(fileName)"
        
        // Note: In a real app, you would use Supabase Storage SDK
        // This is a simplified version
        return "https://athazapkqtozhjromuvn.supabase.co/storage/v1/object/public/\(AppConfig.documentsBucket)/\(path)"
    }
    
    func uploadAvatar(image: Data, userId: UUID) async throws -> String {
        let fileName = "avatar-\(userId.uuidString)-\(Date().timeIntervalSince1970).jpg"
        let path = "avatars/\(fileName)"
        
        // Note: In a real app, you would use Supabase Storage SDK
        return "https://athazapkqtozhjromuvn.supabase.co/storage/v1/object/public/\(AppConfig.userAvatarsBucket)/\(path)"
    }
}

// MARK: - Data Models
struct UserProfile: Codable {
    let id: UUID
    let email: String
    let fullName: String
    let role: String
    let avatarURL: String?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Vehicle: Codable {
    let id: UUID
    let unitNumber: String
    let vin: String
    let make: String
    let model: String?
    let year: Int
    let status: String
    let currentMileage: Double
    let currentLocation: String?
    let lastServiceAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case unitNumber = "unit_number"
        case vin
        case make
        case model
        case year
        case status
        case currentMileage = "current_mileage"
        case currentLocation = "current_location"
        case lastServiceAt = "last_service_at"
    }
}

struct Trip: Codable {
    let id: UUID
    let vehicleId: UUID
    let driverUserId: UUID?
    let externalRef: String?
    let plannedStartAt: Date?
    let actualStartAt: Date?
    let endAt: Date?
    let originAddress: String?
    let originCity: String
    let originState: String
    let destAddress: String?
    let destCity: String
    let destState: String
    let distanceMiles: Double?
    let status: String
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case driverUserId = "driver_user_id"
        case externalRef = "external_ref"
        case plannedStartAt = "planned_start_at"
        case actualStartAt = "actual_start_at"
        case endAt = "end_at"
        case originAddress = "origin_address"
        case originCity = "origin_city"
        case originState = "origin_state"
        case destAddress = "dest_address"
        case destCity = "dest_city"
        case destState = "dest_state"
        case distanceMiles = "distance_miles"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TripMetrics: Codable {
    let id: UUID
    let tripId: UUID
    let totalMiles: Double
    let driveTimeMinutes: Int
    let idleTimeMinutes: Int
    let fuelVolumeGal: Double
    let fuelCost: Double
    let mpg: Double?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case totalMiles = "total_miles"
        case driveTimeMinutes = "drive_time_minutes"
        case idleTimeMinutes = "idle_time_minutes"
        case fuelVolumeGal = "fuel_volume_gal"
        case fuelCost = "fuel_cost"
        case mpg
        case createdAt = "created_at"
    }
}

struct FuelRecord: Codable {
    let id: UUID
    let vehicleId: UUID
    let tripId: UUID?
    let date: Date
    let station: String?
    let city: String
    let state: String
    let gallons: Double
    let amount: Double
    let unitPrice: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case tripId = "trip_id"
        case date
        case station
        case city
        case state
        case gallons
        case amount
        case unitPrice = "unit_price"
    }
}

struct Notification: Codable {
    let id: UUID
    let userId: UUID
    let type: String
    let payload: [String: Any]
    let status: String
    let createdAt: Date
    let deliveredAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case payload
        case status
        case createdAt = "created_at"
        case deliveredAt = "delivered_at"
    }
}

// MARK: - Request/Response Models
struct OpenAIRequest: Codable {
    let messages: [ChatMessage]
    let userId: String
    let tripId: String?
    let vehicleId: String?
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let data: OpenAIData
}

struct OpenAIData: Codable {
    let message: String
    let usage: [String: Int]
    let model: String
}

struct OCRRequest: Codable {
    let ocrText: String
    let documentType: String
    let documentId: String?
    let userId: String
}

struct OCRResponse: Codable {
    let data: OCRData
}

struct OCRData: Codable {
    let processedData: [String: String]
    let confidence: Double
    let documentType: String
    let timestamp: String
}

struct LoadSearchRequest: Codable {
    let origin: String?
    let destination: String?
    let currentLocation: String
    let vehicleId: String
    let userId: String
    let maxDistance: Int
}

struct LoadSearchResponse: Codable {
    let data: LoadSearchData
}

struct LoadSearchData: Codable {
    let loads: [Load]
    let proactiveSuggestions: [ProactiveSuggestion]
    let searchCriteria: [String: Any]
    let timestamp: String
}

struct Load: Codable {
    let id: String
    let origin: String
    let destination: String
    let distance: Int
    let rate: Double
    let total: Double
    let commodity: String
    let weight: Int
    let pieces: Int
    let pickupDate: String
    let deliveryDate: String
    let source: String
    let broker: String
    let contact: String
    let notes: String
    let aiRank: Int?
    let aiReasoning: String?
}

struct ProactiveSuggestion: Codable {
    let type: String
    let title: String
    let description: String
    let priority: String
    let action: String?
    let loads: [Load]?
}

struct AlertRequest: Codable {
    let vehicleId: String
    let userId: String
    let location: String
}

struct AlertSystemResponse: Codable {
    let data: AlertData
}

struct AlertData: Codable {
    let alerts: [PredictiveAlert]
    let totalAlerts: Int
    let highPriority: Int
    let timestamp: String
}

struct PredictiveAlert: Codable {
    let type: String
    let priority: String
    let title: String
    let message: String
    let action: String?
    let location: String?
    let daysRemaining: Int?
}

// MARK: - Backup Data Models
struct BackupStatus: Codable {
    let lastBackup: Date?
    let backupCount: Int
    let totalSize: Int64
    let lastIntegrityCheck: Date?
    let autoBackupEnabled: Bool
    let nextScheduledBackup: Date?
}

// MARK: - Backup and Database Management
extension SupabaseService {
    
    // MARK: - Backup Functions
    
    /// Crear backup completo de la base de datos
    func createFullBackup() async throws {
        let functionUrl = "\(AppConfig.supabaseURL)/functions/v1/database-backup"
        
        var request = URLRequest(url: URL(string: functionUrl)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "type": "full",
            "description": "Backup creado desde app iOS",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Backup falló"])
        }
    }
    
    /// Verificar integridad de un backup
    func verifyBackupIntegrity(backupId: String) async throws -> Bool {
        let functionUrl = "\(AppConfig.supabaseURL)/functions/v1/backup-integrity"
        
        var request = URLRequest(url: URL(string: functionUrl)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["backupId": backupId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Verificación de integridad falló"])
        }
        
        let result = try JSONDecoder().decode([String: Bool].self, from: data)
        return result["isValid"] ?? false
    }
    
    /// Obtener estado de backups
    func getBackupStatus() async throws -> BackupStatus {
        let functionUrl = "\(AppConfig.supabaseURL)/functions/v1/backup-status"
        
        var request = URLRequest(url: URL(string: functionUrl)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener estado de backups"])
        }
        
        return try JSONDecoder().decode(BackupStatus.self, from: data)
    }
    
    /// Restaurar desde backup
    func restoreFromBackup(backupId: String) async throws {
        let functionUrl = "\(AppConfig.supabaseURL)/functions/v1/restore-backup"
        
        var request = URLRequest(url: URL(string: functionUrl)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "backupId": backupId,
            "confirmed": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Restauración falló"])
        }
    }
    
    /// Exportar datos de usuario
    func exportUserData(userId: UUID) async throws {
        let functionUrl = "\(AppConfig.supabaseURL)/functions/v1/export-user-data"
        
        var request = URLRequest(url: URL(string: functionUrl)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["userId": userId.uuidString]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Exportación de datos falló"])
        }
    }
    
    /// Eliminar cuenta de usuario
    func deleteUserAccount(userId: UUID) async throws {
        let functionUrl = "\(AppConfig.supabaseURL)/functions/v1/delete-user"
        
        var request = URLRequest(url: URL(string: functionUrl)!)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["userId": userId.uuidString]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Eliminación de cuenta falló"])
        }
    }
    
    // MARK: - Admin Functions
    
    /// Actualizar configuración de APIs (Admin only)
    func updateAPISettings(_ settings: APISettings) async throws {
        let functionUrl = "\(AppConfig.supabaseURL)/functions/v1/admin-update-api"
        
        var request = URLRequest(url: URL(string: functionUrl)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "openaiApiKey": settings.openaiApiKey,
            "googleMapsApiKey": settings.googleMapsApiKey,
            "datApiKey": settings.datApiKey,
            "truckerPathApiKey": settings.truckerPathApiKey,
            "weatherApiKey": settings.weatherApiKey,
            "maxRetries": settings.maxRetries,
            "requestTimeout": settings.requestTimeout,
            "enableLogging": settings.enableLogging
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Actualización de API falló"])
        }
    }
    
    /// Actualizar configuración del sistema (Admin only)
    func updateSystemSettings(_ settings: SystemSettings) async throws {
        let functionUrl = "\(AppConfig.supabaseURL)/functions/v1/admin-update-system"
        
        var request = URLRequest(url: URL(string: functionUrl)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "appMaintenance": settings.appMaintenance,
            "maintenanceMessage": settings.maintenanceMessage,
            "maxActiveUsers": settings.maxActiveUsers,
            "sessionTimeout": settings.sessionTimeout,
            "autoBackupEnabled": settings.autoBackupEnabled,
            "backupFrequency": settings.backupFrequency,
            "alertThresholds": [
                "fuelLevel": settings.alertThresholds.fuelLevel,
                "maintenanceDue": settings.alertThresholds.maintenanceDue,
                "permitExpiry": settings.alertThresholds.permitExpiry,
                "insuranceExpiry": settings.alertThresholds.insuranceExpiry
            ],
            "featureFlags": [
                "aiRecommendations": settings.featureFlags.aiRecommendations,
                "predictiveAlerts": settings.featureFlags.predictiveAlerts,
                "loadMatching": settings.featureFlags.loadMatching,
                "routeOptimization": settings.featureFlags.routeOptimization,
                "fuelTracking": settings.featureFlags.fuelTracking,
                "maintenanceReminders": settings.featureFlags.maintenanceReminders,
                "complianceAlerts": settings.featureFlags.complianceAlerts,
                "weatherIntegration": settings.featureFlags.weatherIntegration
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "SupabaseService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Actualización de sistema falló"])
        }
    }
}
