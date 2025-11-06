//
//  OptimizedSupabaseService.swift
//  DNA13TruckingApp
//
//  Servicio optimizado para Supabase con mejores prácticas de performance,
//  manejo de errores, seguridad y gestión de consultas eficientes
//

import Foundation
import Supabase
import OSLog
import Combine

@MainActor
class OptimizedSupabaseService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = OptimizedSupabaseService()
    
    // MARK: - Published Properties
    @Published var isConnected: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var currentUser: User?
    
    // MARK: - Private Properties
    private let supabase: SupabaseClient
    private let session: URLSession
    private let logger = Logger(subsystem: "com.dna13trucking.app", category: "SupabaseService")
    private let securityManager: SecurityManager
    private let queryOptimizer: QueryOptimizer
    
    private var connectionCheckTimer: Timer?
    private var retryQueue: [RetryableOperation] = []
    private let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 1.0
    
    // MARK: - Initialization
    private init() {
        // Enhanced URL session configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,    // 10MB memory
            diskCapacity: 50 * 1024 * 1024,      // 50MB disk
            diskPath: "supabase_cache"
        )
        
        self.session = URLSession(configuration: config)
        self.securityManager = SecurityManager.shared
        self.queryOptimizer = QueryOptimizer()
        
        // Initialize Supabase with enhanced configuration
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: securityManager.getSecureValue(.supabaseURL))!,
            supabaseKey: securityManager.getSecureValue(.supabaseAnonKey),
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    schema: "public"
                ),
                auth: SupabaseClientOptions.AuthOptions(
                    storage: .userDefaults,
                    autoRefreshToken: true
                ),
                global: SupabaseClientOptions.GlobalOptions(
                    headers: [
                        "X-Client-Info": "dna13-trucking-ios/1.0.0"
                    ]
                )
            )
        )
        
        setupConnectionMonitoring()
        checkConnection()
    }
    
    deinit {
        connectionCheckTimer?.invalidate()
    }
    
    // MARK: - Connection Management
    
    private func setupConnectionMonitoring() {
        connectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { await self?.checkConnection() }
        }
    }
    
    func checkConnection() async {
        do {
            connectionStatus = .connecting
            
            // Lightweight health check
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let response = try await supabase
                .from("health_check")
                .select("status")
                .limit(1)
                .execute()
            
            let latency = CFAbsoluteTimeGetCurrent() - startTime
            
            let isHealthy = response.statusCode == 200
            
            await MainActor.run {
                self.isConnected = isHealthy
                self.connectionStatus = isHealthy ? 
                    .connected(latency: latency) : 
                    .error("Health check failed")
            }
            
            // Process retry queue if connection restored
            if isHealthy && !retryQueue.isEmpty {
                await processRetryQueue()
            }
            
        } catch {
            await MainActor.run {
                self.isConnected = false
                self.connectionStatus = .error(error.localizedDescription)
            }
            logger.error("Connection check failed: \(error)")
        }
    }
    
    // MARK: - Enhanced Authentication
    
    func signUp(email: String, password: String, fullName: String, role: UserRole = .driver) async throws -> User {
        let operation = AuthOperation.signUp(email: email, password: password, fullName: fullName, role: role)
        return try await executeAuthOperation(operation)
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let operation = AuthOperation.signIn(email: email, password: password)
        return try await executeAuthOperation(operation)
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        await MainActor.run {
            currentUser = nil
        }
        logger.info("User signed out successfully")
    }
    
    func refreshSession() async throws {
        let session = try await supabase.auth.refreshSession()
        await MainActor.run {
            currentUser = session.user
        }
    }
    
    // MARK: - Optimized Database Operations
    
    func getDashboardStatistics(userId: UUID) async throws -> StatisticsData {
        let query = queryOptimizer.buildDashboardStatsQuery(userId: userId)
        
        return try await executeWithRetry {
            let response = try await self.supabase
                .from("dashboard_statistics_view") // Materialized view for performance
                .select(query.selectClause)
                .eq("user_id", userId.uuidString)
                .maybeSingle()
            
            guard let data = response.data,
                  let statisticsData = try? JSONDecoder().decode(StatisticsData.self, from: JSONSerialization.data(withJSONObject: data)) else {
                throw SupabaseError.dataParsingError
            }
            
            return statisticsData
        }
    }
    
    func getNextDelivery(userId: UUID) async throws -> DeliveryInfo? {
        return try await executeWithRetry {
            let response = try await self.supabase
                .from("loads")
                .select("""
                    id, customer_name, destination_address, 
                    delivery_date, priority, rate,
                    vehicles!inner(assigned_driver_id)
                """)
                .eq("vehicles.assigned_driver_id", userId.uuidString)
                .in("status", ["assigned", "picked_up", "in_transit"])
                .order("delivery_date", ascending: true)
                .limit(1)
                .maybeSingle()
            
            guard let data = response.data else { return nil }
            
            return try JSONDecoder().decode(DeliveryInfo.self, from: JSONSerialization.data(withJSONObject: data))
        }
    }
    
    func getRecentAlerts(userId: UUID, limit: Int = 10, onlyUnread: Bool = false) async throws -> [AlertItem] {
        return try await executeWithRetry {
            var query = self.supabase
                .from("notifications")
                .select("id, title, message, type, priority, created_at, is_read")
                .eq("user_id", userId.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
            
            if onlyUnread {
                query = query.eq("is_read", false)
            }
            
            let response = try await query.execute()
            
            return try response.data.map { data in
                try JSONDecoder().decode(AlertItem.self, from: JSONSerialization.data(withJSONObject: data))
            }
        }
    }
    
    func getEarningsData(userId: UUID) async throws -> EarningsData {
        return try await executeWithRetry {
            let response = try await self.supabase
                .from("earnings_summary_view") // Materialized view with pre-calculated earnings
                .select("weekly_earnings, monthly_earnings, yearly_earnings")
                .eq("user_id", userId.uuidString)
                .maybeSingle()
            
            guard let data = response.data,
                  let earningsData = try? JSONDecoder().decode(EarningsData.self, from: JSONSerialization.data(withJSONObject: data)) else {
                // Fallback to real-time calculation if view is not available
                return try await calculateEarningsRealTime(userId: userId)
            }
            
            return earningsData
        }
    }
    
    func getCurrentVehicleStatus(userId: UUID) async throws -> VehicleStatus {
        return try await executeWithRetry {
            let response = try await self.supabase
                .from("vehicles")
                .select("status")
                .eq("assigned_driver_id", userId.uuidString)
                .maybeSingle()
            
            guard let data = response.data,
                  let statusString = data["status"] as? String,
                  let status = VehicleStatus(rawValue: statusString) else {
                return .unknown
            }
            
            return status
        }
    }
    
    func markAlertAsRead(alertId: String) async throws {
        try await executeWithRetry {
            _ = try await self.supabase
                .from("notifications")
                .update(["is_read": true, "read_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", alertId)
                .execute()
        }
    }
    
    // MARK: - Batch Operations for Performance
    
    func batchUpdateLocations(_ locations: [LocationUpdate]) async throws {
        guard !locations.isEmpty else { return }
        
        try await executeWithRetry {
            let locationData = try locations.map { location in
                try JSONSerialization.jsonObject(with: JSONEncoder().encode(location))
            }
            
            _ = try await self.supabase
                .from("vehicle_locations")
                .insert(locationData)
                .execute()
        }
    }
    
    func batchInsertFuelRecords(_ records: [FuelRecord]) async throws {
        guard !records.isEmpty else { return }
        
        try await executeWithRetry {
            let fuelData = try records.map { record in
                try JSONSerialization.jsonObject(with: JSONEncoder().encode(record))
            }
            
            _ = try await self.supabase
                .from("fuel_records")
                .insert(fuelData)
                .execute()
        }
    }
    
    // MARK: - Real-time Subscriptions
    
    func subscribeToNotifications(userId: UUID, callback: @escaping (AlertItem) -> Void) -> RealtimeSubscription {
        return supabase.channel("notifications")
            .on(
                .postgresChanges(
                    event: .insert,
                    schema: "public",
                    table: "notifications",
                    filter: PostgresChangeFilter(column: "user_id", value: userId.uuidString)
                )
            ) { payload in
                if let data = payload.new,
                   let alertData = try? JSONSerialization.data(withJSONObject: data),
                   let alert = try? JSONDecoder().decode(AlertItem.self, from: alertData) {
                    callback(alert)
                }
            }
            .subscribe()
    }
    
    func subscribeToVehicleUpdates(vehicleId: UUID, callback: @escaping (VehicleUpdate) -> Void) -> RealtimeSubscription {
        return supabase.channel("vehicle_updates")
            .on(
                .postgresChanges(
                    event: .update,
                    schema: "public", 
                    table: "vehicles",
                    filter: PostgresChangeFilter(column: "id", value: vehicleId.uuidString)
                )
            ) { payload in
                if let data = payload.new,
                   let updateData = try? JSONSerialization.data(withJSONObject: data),
                   let update = try? JSONDecoder().decode(VehicleUpdate.self, from: updateData) {
                    callback(update)
                }
            }
            .subscribe()
    }
    
    // MARK: - Error Handling & Retry Logic
    
    private func executeWithRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                logger.warning("Operation failed (attempt \(attempt + 1)/\(maxRetries)): \(error)")
                
                // Don't retry on authentication or client errors
                if let supabaseError = error as? SupabaseError,
                   supabaseError.isClientError {
                    throw error
                }
                
                // Exponential backoff
                if attempt < maxRetries - 1 {
                    let delay = baseRetryDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // If we get here, all retries failed
        throw lastError ?? SupabaseError.unknownError
    }
    
    private func executeAuthOperation(_ operation: AuthOperation) async throws -> User {
        return try await executeWithRetry {
            let authResponse: AuthResponse
            
            switch operation {
            case .signUp(let email, let password, let fullName, let role):
                authResponse = try await self.supabase.auth.signUp(email: email, password: password)
                
                // Create user profile if signup successful
                if let user = authResponse.user {
                    let profile = UserProfile(
                        id: user.id,
                        email: email,
                        fullName: fullName,
                        role: role.rawValue,
                        createdAt: Date()
                    )
                    try await self.createUserProfile(profile)
                }
                
            case .signIn(let email, let password):
                authResponse = try await self.supabase.auth.signIn(email: email, password: password)
            }
            
            guard let user = authResponse.user else {
                throw SupabaseError.authenticationFailed
            }
            
            await MainActor.run {
                self.currentUser = user
            }
            
            return user
        }
    }
    
    private func createUserProfile(_ profile: UserProfile) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(profile)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SupabaseError.dataEncodingError
        }
        
        _ = try await supabase
            .from("users")
            .insert(json)
            .execute()
    }
    
    private func calculateEarningsRealTime(userId: UUID) async throws -> EarningsData {
        // Fallback calculation when materialized view is not available
        let now = Date()
        let calendar = Calendar.current
        
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let yearStart = calendar.dateInterval(of: .year, for: now)?.start ?? now
        
        let response = try await supabase
            .from("loads")
            .select("rate, delivery_date, vehicles!inner(assigned_driver_id)")
            .eq("vehicles.assigned_driver_id", userId.uuidString)
            .eq("status", "completed")
            .gte("delivery_date", ISO8601DateFormatter().string(from: yearStart))
            .execute()
        
        let loads = try response.data.compactMap { data -> (rate: Double, date: Date)? in
            guard let rate = data["rate"] as? Double,
                  let dateString = data["delivery_date"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString) else {
                return nil
            }
            return (rate: rate, date: date)
        }
        
        let weeklyEarnings = loads
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.rate }
        
        let monthlyEarnings = loads
            .filter { $0.date >= monthStart }
            .reduce(0) { $0 + $1.rate }
        
        let yearlyEarnings = loads
            .reduce(0) { $0 + $1.rate }
        
        return EarningsData(
            weekly: weeklyEarnings,
            monthly: monthlyEarnings,
            yearly: yearlyEarnings
        )
    }
    
    private func processRetryQueue() async {
        let pendingOperations = retryQueue
        retryQueue.removeAll()
        
        for operation in pendingOperations {
            do {
                try await operation.execute()
                logger.info("Retry operation succeeded: \(operation.id)")
            } catch {
                logger.error("Retry operation failed: \(operation.id) - \(error)")
                
                // Re-queue if still has retries
                if operation.retriesLeft > 0 {
                    var updatedOperation = operation
                    updatedOperation.retriesLeft -= 1
                    retryQueue.append(updatedOperation)
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected(latency: TimeInterval)
    case error(String)
    
    var description: String {
        switch self {
        case .disconnected:
            return "Desconectado"
        case .connecting:
            return "Conectando..."
        case .connected(let latency):
            return "Conectado (\(Int(latency * 1000))ms)"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

enum AuthOperation {
    case signUp(email: String, password: String, fullName: String, role: UserRole)
    case signIn(email: String, password: String)
}

struct RetryableOperation {
    let id: String
    let execute: () async throws -> Void
    var retriesLeft: Int
    
    init(id: String, retriesLeft: Int = 2, execute: @escaping () async throws -> Void) {
        self.id = id
        self.retriesLeft = retriesLeft
        self.execute = execute
    }
}

enum SupabaseError: Error, LocalizedError {
    case authenticationFailed
    case dataParsingError
    case dataEncodingError
    case networkError
    case serverError(Int)
    case unknownError
    
    var isClientError: Bool {
        switch self {
        case .authenticationFailed, .dataParsingError, .dataEncodingError:
            return true
        case .serverError(let code):
            return code >= 400 && code < 500
        case .networkError, .unknownError:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Error de autenticación"
        case .dataParsingError:
            return "Error al procesar datos"
        case .dataEncodingError:
            return "Error al codificar datos"
        case .networkError:
            return "Error de conexión"
        case .serverError(let code):
            return "Error del servidor (\(code))"
        case .unknownError:
            return "Error desconocido"
        }
    }
}

struct LocationUpdate: Codable {
    let vehicleId: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double?
    let heading: Double?
}

struct VehicleUpdate: Codable {
    let id: UUID
    let status: VehicleStatus
    let currentLocation: String?
    let fuelLevel: Double?
    let lastUpdated: Date
}