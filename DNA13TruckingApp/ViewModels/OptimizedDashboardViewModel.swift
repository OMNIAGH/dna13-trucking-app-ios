//
//  OptimizedDashboardViewModel.swift
//  DNA13TruckingApp
//
//  ViewModel optimizado para el dashboard principal con mejores prácticas de performance,
//  manejo de errores y consultas eficientes de base de datos
//

import Foundation
import Combine
import SwiftUI
import OSLog

@MainActor
class OptimizedDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var dashboardData: DashboardData = DashboardData()
    @Published var isLoading: Bool = false
    @Published var errorState: ErrorState?
    @Published var refreshProgress: Double = 0.0
    
    // MARK: - Cache Management
    @Published var lastRefresh: Date?
    @Published var dataFreshness: DataFreshness = .stale
    
    // MARK: - Private Properties
    private let authManager: AuthManager
    private let supabaseService: OptimizedSupabaseService
    private let cacheManager: CacheManager
    private let logger = Logger(subsystem: "com.dna13trucking.app", category: "DashboardViewModel")
    
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 300 // 5 minutos
    
    // MARK: - Initialization
    init(
        authManager: AuthManager = AuthManager.shared,
        supabaseService: OptimizedSupabaseService = OptimizedSupabaseService.shared,
        cacheManager: CacheManager = CacheManager.shared
    ) {
        self.authManager = authManager
        self.supabaseService = supabaseService
        self.cacheManager = cacheManager
        
        setupObservers()
        startPeriodicRefresh()
        loadInitialData()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Refresca todos los datos del dashboard
    func refreshData(force: Bool = false) async {
        // Evitar múltiples refreshes simultáneos
        guard !isLoading else { return }
        
        // Check if data is fresh enough (unless forced)
        if !force && shouldUseCachedData() {
            logger.info("Using cached data - still fresh")
            return
        }
        
        await performDataRefresh()
    }
    
    /// Marca una notificación como leída
    func markNotificationAsRead(_ alert: AlertItem) async {
        do {
            // Optimistic update
            dashboardData.alerts.removeAll { $0.id == alert.id }
            dashboardData.unreadNotifications = max(0, dashboardData.unreadNotifications - 1)
            
            // Persist change
            try await supabaseService.markAlertAsRead(alertId: alert.id)
            
        } catch {
            logger.error("Failed to mark notification as read: \(error)")
            // Revert optimistic update
            await loadAlertsData()
        }
    }
    
    /// Obtiene el estado actual del conductor/vehículo
    func getCurrentOperationalStatus() -> OperationalStatus {
        let activeLoads = dashboardData.activeLoads
        let vehicleStatus = dashboardData.vehicleStatus
        
        if vehicleStatus == .maintenance {
            return .maintenance
        } else if activeLoads > 0 {
            return .active(loads: activeLoads)
        } else {
            return .available
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observar cambios en la autenticación
        authManager.$currentUser
            .removeDuplicates()
            .sink { [weak self] user in
                if user != nil {
                    Task { await self?.refreshData(force: true) }
                } else {
                    self?.clearData()
                }
            }
            .store(in: &cancellables)
        
        // Observar cambios en la conectividad
        supabaseService.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                if isConnected && self?.dataFreshness == .stale {
                    Task { await self?.refreshData() }
                }
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshData()
            }
        }
    }
    
    private func loadInitialData() {
        Task {
            // Try to load from cache first
            if let cachedData = await loadCachedData() {
                self.dashboardData = cachedData
                self.dataFreshness = .cached
                self.lastRefresh = cacheManager.getLastCacheTime(for: "dashboard")
            }
            
            // Then refresh with real data
            await refreshData()
        }
    }
    
    private func shouldUseCachedData() -> Bool {
        guard let lastRefresh = lastRefresh else { return false }
        let timeSinceRefresh = Date().timeIntervalSince(lastRefresh)
        return timeSinceRefresh < 60 // Datos frescos por 1 minuto
    }
    
    private func performDataRefresh() async {
        isLoading = true
        refreshProgress = 0.0
        errorState = nil
        
        do {
            // Load data in parallel for better performance
            async let statisticsData = loadStatisticsData()
            async let deliveryData = loadNextDeliveryData()
            async let alertsData = loadAlertsData()
            async let earningsData = loadEarningsData()
            async let vehicleData = loadVehicleStatusData()
            
            // Update progress as tasks complete
            refreshProgress = 0.2
            
            let (stats, delivery, alerts, earnings, vehicle) = try await (
                statisticsData,
                deliveryData, 
                alertsData,
                earningsData,
                vehicleData
            )
            
            refreshProgress = 0.8
            
            // Update dashboard data
            updateDashboardData(
                statistics: stats,
                nextDelivery: delivery,
                alerts: alerts,
                earnings: earnings,
                vehicleStatus: vehicle
            )
            
            // Cache the new data
            await cacheDashboardData()
            
            refreshProgress = 1.0
            dataFreshness = .fresh
            lastRefresh = Date()
            
            logger.info("Dashboard data refreshed successfully")
            
        } catch {
            await handleDataLoadError(error)
        }
        
        isLoading = false
    }
    
    private func loadStatisticsData() async throws -> StatisticsData {
        guard let currentUser = authManager.currentUser else {
            throw DashboardError.userNotAuthenticated
        }
        
        return try await supabaseService.getDashboardStatistics(userId: currentUser.id)
    }
    
    private func loadNextDeliveryData() async throws -> DeliveryInfo? {
        guard let currentUser = authManager.currentUser else { return nil }
        
        return try await supabaseService.getNextDelivery(userId: currentUser.id)
    }
    
    private func loadAlertsData() async throws -> [AlertItem] {
        guard let currentUser = authManager.currentUser else { return [] }
        
        return try await supabaseService.getRecentAlerts(
            userId: currentUser.id,
            limit: 10,
            onlyUnread: true
        )
    }
    
    private func loadEarningsData() async throws -> EarningsData {
        guard let currentUser = authManager.currentUser else {
            throw DashboardError.userNotAuthenticated
        }
        
        return try await supabaseService.getEarningsData(userId: currentUser.id)
    }
    
    private func loadVehicleStatusData() async throws -> VehicleStatus {
        guard let currentUser = authManager.currentUser else {
            return .unknown
        }
        
        return try await supabaseService.getCurrentVehicleStatus(userId: currentUser.id)
    }
    
    private func updateDashboardData(
        statistics: StatisticsData,
        nextDelivery: DeliveryInfo?,
        alerts: [AlertItem],
        earnings: EarningsData,
        vehicleStatus: VehicleStatus
    ) {
        dashboardData = DashboardData(
            totalLoads: statistics.totalLoads,
            activeLoads: statistics.activeLoads,
            completedLoadsToday: statistics.completedLoadsToday,
            pendingLoads: statistics.pendingLoads,
            currentLocation: statistics.currentLocation,
            nextDelivery: nextDelivery,
            weeklyEarnings: earnings.weekly,
            monthlyEarnings: earnings.monthly,
            yearlyEarnings: earnings.yearly,
            alerts: alerts,
            unreadNotifications: alerts.count,
            vehicleStatus: vehicleStatus,
            fuelLevel: statistics.fuelLevel,
            maintenanceAlerts: statistics.maintenanceAlerts
        )
    }
    
    private func handleDataLoadError(_ error: Error) async {
        logger.error("Failed to load dashboard data: \(error)")
        
        let errorDescription: String
        let suggestion: String
        
        switch error {
        case DashboardError.userNotAuthenticated:
            errorDescription = "Usuario no autenticado"
            suggestion = "Por favor, inicia sesión nuevamente"
            
        case DashboardError.networkError:
            errorDescription = "Error de conectividad"
            suggestion = "Verifica tu conexión a internet"
            
        case DashboardError.serverError:
            errorDescription = "Error del servidor"
            suggestion = "Intenta nuevamente en unos momentos"
            
        default:
            errorDescription = "Error inesperado"
            suggestion = "Contacta con soporte si el problema persiste"
        }
        
        errorState = ErrorState(
            message: errorDescription,
            suggestion: suggestion,
            canRetry: true,
            retryAction: { [weak self] in
                Task { await self?.refreshData(force: true) }
            }
        )
    }
    
    private func loadCachedData() async -> DashboardData? {
        return await cacheManager.getCachedObject(
            for: "dashboard",
            type: DashboardData.self
        )
    }
    
    private func cacheDashboardData() async {
        await cacheManager.setCachedObject(
            dashboardData,
            for: "dashboard",
            expiration: .minutes(5)
        )
    }
    
    private func clearData() {
        dashboardData = DashboardData()
        errorState = nil
        dataFreshness = .stale
        lastRefresh = nil
    }
}

// MARK: - Data Models

struct DashboardData: Codable {
    var totalLoads: Int = 0
    var activeLoads: Int = 0
    var completedLoadsToday: Int = 0
    var pendingLoads: Int = 0
    var currentLocation: String = "Ubicación no disponible"
    var nextDelivery: DeliveryInfo?
    var weeklyEarnings: Double = 0.0
    var monthlyEarnings: Double = 0.0
    var yearlyEarnings: Double = 0.0
    var alerts: [AlertItem] = []
    var unreadNotifications: Int = 0
    var vehicleStatus: VehicleStatus = .unknown
    var fuelLevel: Double = 0.0
    var maintenanceAlerts: Int = 0
}

struct StatisticsData: Codable {
    let totalLoads: Int
    let activeLoads: Int
    let completedLoadsToday: Int
    let pendingLoads: Int
    let currentLocation: String
    let fuelLevel: Double
    let maintenanceAlerts: Int
}

struct EarningsData: Codable {
    let weekly: Double
    let monthly: Double
    let yearly: Double
}

struct AlertItem: Identifiable, Codable {
    let id: String
    let title: String
    let message: String
    let type: AlertType
    let priority: AlertPriority
    let timestamp: Date
    let isRead: Bool
}

enum AlertType: String, Codable, CaseIterable {
    case maintenance = "maintenance"
    case delivery = "delivery"
    case traffic = "traffic"
    case weather = "weather"
    case fuel = "fuel"
    case safety = "safety"
    case compliance = "compliance"
    case system = "system"
}

enum AlertPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

enum VehicleStatus: String, Codable, CaseIterable {
    case active = "active"
    case idle = "idle"
    case maintenance = "maintenance"
    case outOfService = "out_of_service"
    case unknown = "unknown"
}

enum OperationalStatus {
    case available
    case active(loads: Int)
    case maintenance
    
    var description: String {
        switch self {
        case .available:
            return "Disponible"
        case .active(let loads):
            return "En ruta - \(loads) entregas activas"
        case .maintenance:
            return "En mantenimiento"
        }
    }
}

enum DataFreshness {
    case fresh
    case cached
    case stale
}

struct ErrorState {
    let message: String
    let suggestion: String
    let canRetry: Bool
    let retryAction: (() -> Void)?
}

enum DashboardError: Error, LocalizedError {
    case userNotAuthenticated
    case networkError
    case serverError
    case dataParsingError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "Usuario no autenticado"
        case .networkError:
            return "Error de red"
        case .serverError:
            return "Error del servidor"
        case .dataParsingError:
            return "Error al procesar datos"
        }
    }
}