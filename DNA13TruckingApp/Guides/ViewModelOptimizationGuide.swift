//
//  ViewModelOptimizationGuide.swift
//  DNA13TruckingApp
//
//  Guía y ejemplos de cómo integrar las optimizaciones en ViewModels existentes
//  Incluye patrones de migración y mejores prácticas
//

import Foundation
import SwiftUI
import Combine

/*
 GUÍA DE OPTIMIZACIÓN DE VIEWMODELS
 
 Esta guía muestra cómo migrar ViewModels existentes para usar las nuevas
 optimizaciones de rendimiento, manejo de errores y monitoreo de red.
 
 COMPONENTES CREADOS:
 1. OptimizedSupabaseService - Service optimizado con caching y retry logic
 2. CacheManager - Sistema de caching centralizado
 3. SecurityManager - Manejo seguro de credenciales
 4. QueryOptimizer - Optimización de consultas a base de datos
 5. ErrorHandler - Manejo centralizado de errores
 6. NetworkMonitor - Monitoreo de conectividad
 7. ViewModelErrorHandling - Protocol para ViewModels
 
 PASOS DE MIGRACIÓN:
 
 1. Hacer que el ViewModel implemente ErrorHandlingViewModel
 2. Reemplazar SupabaseService con OptimizedSupabaseService
 3. Usar performOperation() para operaciones async
 4. Implementar caching para datos frecuentemente accedidos
 5. Añadir validación de datos de entrada
 6. Configurar observadores de red
*/

// MARK: - EJEMPLO 1: Migración de DashboardViewModel

// ANTES (ViewModel original):
/*
class DashboardViewModel: ObservableObject {
    @Published var loads: [Load] = []
    @Published var statistics: DashboardStatistics?
    @Published var isLoading: Bool = false
    
    private let supabaseService = SupabaseService.shared
    
    func loadDashboardData() {
        isLoading = true
        
        Task {
            do {
                let loads = try await supabaseService.getLoads()
                let stats = try await supabaseService.getDashboardStatistics()
                
                DispatchQueue.main.async {
                    self.loads = loads
                    self.statistics = stats
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    // Error handling básico
                    print("Error: \(error)")
                }
            }
        }
    }
}
*/

// DESPUÉS (ViewModel optimizado):
class MigratedDashboardViewModel: ObservableObject, ErrorHandlingViewModel {
    // MARK: - ErrorHandlingViewModel Requirements
    let errorHandler = ErrorHandler.shared
    let networkMonitor = NetworkMonitor.shared
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var loads: [Load] = []
    @Published var statistics: DashboardStatistics?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Private Properties
    private let supabaseService = OptimizedSupabaseService.shared
    private let cacheManager = CacheManager.shared
    private var loadingState = LoadingState()
    private let refreshOperation = CancellableOperation()
    
    // MARK: - Initialization
    init() {
        setupNetworkObservers() // Del protocolo ErrorHandlingViewModel
        loadCachedData()
        loadDashboardData()
    }
    
    // MARK: - Public Methods
    func loadDashboardData() {
        // Verificar conectividad antes de la operación
        guard requiresConnection() else { return }
        
        // Usar performOperation del protocolo para manejo automático de errores
        performOperation({
            // Operaciones en paralelo para mejor rendimiento
            async let loads = self.supabaseService.getLoads(useCache: true)
            async let stats = self.supabaseService.getDashboardStatistics(useCache: true)
            
            let (loadResults, statsResult) = try await (loads, stats)
            
            return (loadResults, statsResult)
        }, 
        context: "Dashboard Data Load",
        onSuccess: { [weak self] results in
            self?.loads = results.0
            self?.statistics = results.1
            self?.lastUpdateTime = Date()
            self?.saveCachedData()
        })
    }
    
    func refreshData() {
        // Cancelar operación anterior si existe
        refreshOperation.execute({
            // Forzar actualización sin cache
            async let loads = self.supabaseService.getLoads(useCache: false)
            async let stats = self.supabaseService.getDashboardStatistics(useCache: false)
            
            return try await (loads, stats)
        },
        onSuccess: { [weak self] results in
            self?.loads = results.0
            self?.statistics = results.1
            self?.lastUpdateTime = Date()
            self?.saveCachedData()
            self?.clearCache() // Limpiar cache para próxima carga
        },
        onError: { [weak self] error in
            self?.handleError(error, context: "Data Refresh")
        })
    }
    
    // MARK: - Network Observer Overrides
    override func onNetworkReconnected() {
        // Auto-refresh cuando se restablece la conexión
        refreshData()
    }
    
    // MARK: - Private Methods
    private func loadCachedData() {
        if let cachedLoads: [Load] = cacheManager.get(forKey: "dashboard_loads") {
            loads = cachedLoads
        }
        
        if let cachedStats: DashboardStatistics = cacheManager.get(forKey: "dashboard_stats") {
            statistics = cachedStats
        }
    }
    
    private func saveCachedData() {
        cacheManager.set(loads, forKey: "dashboard_loads", duration: 300) // 5 minutos
        cacheManager.set(statistics, forKey: "dashboard_stats", duration: 300)
    }
    
    private func clearCache() {
        cacheManager.remove(forKey: "dashboard_loads")
        cacheManager.remove(forKey: "dashboard_stats")
    }
}

// MARK: - EJEMPLO 2: Migración de LoadManagementViewModel

class MigratedLoadManagementViewModel: ObservableObject, ErrorHandlingViewModel {
    // MARK: - ErrorHandlingViewModel Requirements
    let errorHandler = ErrorHandler.shared
    let networkMonitor = NetworkMonitor.shared
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var loads: [Load] = []
    @Published var selectedLoad: Load?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var filterStatus: LoadStatus?
    
    // MARK: - Private Properties
    private let supabaseService = OptimizedSupabaseService.shared
    private let securityManager = SecurityManager.shared
    private var searchDebouncer = PassthroughSubject<String, Never>()
    
    // Validadores
    private let loadValidators: [Validator<LoadData>] = [
        LoadDataValidator()
    ]
    
    init() {
        setupNetworkObservers()
        setupSearchDebouncing()
        loadLoads()
    }
    
    // MARK: - Public Methods
    func createLoad(_ loadData: LoadData) {
        // Validar datos antes de enviar
        guard validate(loadData, using: loadValidators) else {
            return
        }
        
        performOperation({
            try await self.supabaseService.createLoad(loadData)
        },
        context: "Create Load",
        onSuccess: { [weak self] newLoad in
            self?.loads.append(newLoad)
            self?.clearError()
        })
    }
    
    func updateLoad(_ load: Load, with data: LoadData) {
        // Validar datos
        guard validate(data, using: loadValidators) else {
            return
        }
        
        // Optimistic update
        if let index = loads.firstIndex(where: { $0.id == load.id }) {
            loads[index] = load.copy(with: data)
        }
        
        performOperation({
            try await self.supabaseService.updateLoad(load.id, data: data)
        },
        context: "Update Load",
        onError: { [weak self] _ in
            // Revertir cambio optimista en caso de error
            self?.loadLoads()
        })
    }
    
    func deleteLoad(_ load: Load) {
        // Optimistic update
        loads.removeAll { $0.id == load.id }
        
        performOperation({
            try await self.supabaseService.deleteLoad(load.id)
        },
        context: "Delete Load",
        onError: { [weak self] _ in
            // Revertir eliminación en caso de error
            self?.loadLoads()
        })
    }
    
    func searchLoads() {
        searchDebouncer.send(searchText)
    }
    
    // MARK: - Private Methods
    private func loadLoads() {
        performOperation({
            try await self.supabaseService.getLoads(
                search: self.searchText.isEmpty ? nil : self.searchText,
                status: self.filterStatus
            )
        },
        context: "Load Loads",
        onSuccess: { [weak self] loads in
            self?.loads = loads
        })
    }
    
    private func setupSearchDebouncing() {
        searchDebouncer
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadLoads()
            }
            .store(in: &cancellables)
    }
}

// MARK: - EJEMPLO 3: Validador personalizado

struct LoadDataValidator: Validator {
    let fieldName = "Load Data"
    
    func validate(_ value: LoadData) -> String? {
        if value.pickupLocation.isEmpty {
            return "La ubicación de recogida es requerida"
        }
        
        if value.deliveryLocation.isEmpty {
            return "La ubicación de entrega es requerida"
        }
        
        if value.weight <= 0 {
            return "El peso debe ser mayor a 0"
        }
        
        if value.rate <= 0 {
            return "La tarifa debe ser mayor a 0"
        }
        
        if value.pickupDate < Date() {
            return "La fecha de recogida no puede ser en el pasado"
        }
        
        return nil
    }
}

// MARK: - EJEMPLO 4: ViewModel con múltiples operaciones

class MigratedVehicleViewModel: ObservableObject, ErrorHandlingViewModel {
    let errorHandler = ErrorHandler.shared
    let networkMonitor = NetworkMonitor.shared
    var cancellables = Set<AnyCancellable>()
    
    @Published var vehicles: [Vehicle] = []
    @Published var selectedVehicle: Vehicle?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var maintenanceAlerts: [MaintenanceAlert] = []
    
    private let supabaseService = OptimizedSupabaseService.shared
    private var loadingState = LoadingState()
    
    init() {
        setupNetworkObservers()
        loadAllData()
    }
    
    func loadAllData() {
        // Usar performParallelOperations para cargar múltiples tipos de datos
        performParallelOperations([
            { try await self.supabaseService.getVehicles() },
            { try await self.supabaseService.getMaintenanceAlerts() }
        ],
        context: "Load Vehicle Data",
        onSuccess: { [weak self] results in
            if let vehicles = results[0] as? [Vehicle] {
                self?.vehicles = vehicles
            }
            if let alerts = results[1] as? [MaintenanceAlert] {
                self?.maintenanceAlerts = alerts
            }
        })
    }
    
    func performMaintenance(for vehicle: Vehicle, type: MaintenanceType) {
        loadingState.start("maintenance_\(vehicle.id)")
        
        performOperation({
            try await self.supabaseService.recordMaintenance(
                vehicleId: vehicle.id,
                type: type,
                date: Date()
            )
        },
        context: "Record Maintenance",
        onSuccess: { [weak self] _ in
            self?.loadingState.finish("maintenance_\(vehicle.id)")
            self?.loadAllData() // Refresh data
        },
        onError: { [weak self] _ in
            self?.loadingState.finish("maintenance_\(vehicle.id)")
        })
    }
    
    func isMaintenanceLoading(for vehicle: Vehicle) -> Bool {
        return loadingState.isOperationLoading("maintenance_\(vehicle.id)")
    }
}

// MARK: - PATRONES DE MEJORES PRÁCTICAS

/*
 MEJORES PRÁCTICAS IMPLEMENTADAS:
 
 1. MANEJO DE ERRORES:
    - Usar performOperation() para manejo automático
    - Implementar ErrorHandlingViewModel protocol
    - Usar validadores para datos de entrada
    
 2. RENDIMIENTO:
    - Caching automático con CacheManager
    - Operaciones paralelas con performParallelOperations()
    - Debouncing para búsquedas
    - Optimistic updates para mejor UX
    
 3. CONECTIVIDAD:
    - Verificar conexión antes de operaciones críticas
    - Auto-refresh cuando se restablece conexión
    - Graceful degradation sin conexión
    
 4. SEGURIDAD:
    - Usar SecurityManager para datos sensibles
    - Validación robusta de datos de entrada
    - Manejo seguro de tokens y credenciales
    
 5. UX:
    - Estados de carga granulares con LoadingState
    - Operaciones cancelables con CancellableOperation
    - Mensajes de error user-friendly
    - Auto-clear de errores temporales
    
 6. MANTENIBILIDAD:
    - Separación clara de responsabilidades
    - Reutilización de patrones comunes
    - Logging y analytics integrados
    - Testing-friendly architecture
 
 MIGRACIÓN PASO A PASO:
 
 1. Añadir conformance a ErrorHandlingViewModel
 2. Reemplazar service calls con performOperation()
 3. Implementar caching para datos frecuentes
 4. Añadir validación de entrada
 5. Configurar observadores de red
 6. Testing y ajustes finales
*/

// MARK: - EXTENSIÓN PARA TODOS LOS VIEWMODELS

extension ErrorHandlingViewModel {
    /// Configuración estándar para todos los ViewModels
    func standardSetup() {
        setupNetworkObservers()
        
        // Observer para cambios de autenticación
        NotificationCenter.default.publisher(for: .userDidLogin)
            .sink { [weak self] _ in
                self?.onUserLogin()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .userDidLogout)
            .sink { [weak self] _ in
                self?.onUserLogout()
            }
            .store(in: &cancellables)
    }
    
    /// Se llama cuando el usuario inicia sesión
    func onUserLogin() {
        // Override en ViewModels específicos
    }
    
    /// Se llama cuando el usuario cierra sesión
    func onUserLogout() {
        // Limpiar datos sensibles
        clearSensitiveData()
    }
    
    /// Limpia datos sensibles del ViewModel
    func clearSensitiveData() {
        // Override en ViewModels específicos
    }
}

// MARK: - Notification Names para autenticación

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
}