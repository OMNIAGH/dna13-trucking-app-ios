//
//  NetworkMonitor.swift
//  DNA13TruckingApp
//
//  Monitor de conectividad de red para la aplicación
//  Detecta cambios en la conexión y notifica a los componentes
//

import Foundation
import Network
import Combine

/// Estado de la conexión de red
enum NetworkStatus: Equatable {
    case connected(ConnectionType)
    case disconnected
    case unknown
    
    var isConnected: Bool {
        switch self {
        case .connected:
            return true
        case .disconnected, .unknown:
            return false
        }
    }
}

/// Tipo de conexión
enum ConnectionType: String, CaseIterable {
    case wifi = "WiFi"
    case cellular = "Cellular"
    case ethernet = "Ethernet"
    case other = "Other"
    
    var displayName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            return "cable.connector"
        case .other:
            return "network"
        }
    }
}

/// Monitor de conectividad de red
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    // MARK: - Published Properties
    @Published var status: NetworkStatus = .unknown
    @Published var isConnected: Bool = false
    @Published var connectionType: ConnectionType = .other
    @Published var connectionQuality: ConnectionQuality = .unknown
    @Published var latency: TimeInterval = 0
    @Published var bandwidth: Bandwidth = Bandwidth()
    
    // MARK: - Private Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .background)
    private var cancellables = Set<AnyCancellable>()
    private let errorHandler = ErrorHandler.shared
    private let cacheManager = CacheManager.shared
    
    // Historial de conectividad
    private var connectionHistory: [ConnectionEvent] = []
    private let maxHistorySize = 100
    
    // Métricas de rendimiento
    private var lastSpeedTest: Date?
    private let speedTestInterval: TimeInterval = 300 // 5 minutos
    
    private init() {
        setupNetworkMonitoring()
        loadConnectionHistory()
    }
    
    // MARK: - Public Methods
    
    /// Inicia el monitoreo de red
    func startMonitoring() {
        monitor.start(queue: queue)
    }
    
    /// Detiene el monitoreo de red
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Realiza un test de velocidad de la conexión
    func performSpeedTest() async -> SpeedTestResult {
        guard isConnected else {
            return SpeedTestResult(downloadSpeed: 0, uploadSpeed: 0, latency: 0, error: "Sin conexión")
        }
        
        let startTime = Date()
        
        do {
            // Test de latency con ping simple
            let latency = try await measureLatency()
            
            // Test de descarga básico
            let downloadSpeed = try await measureDownloadSpeed()
            
            // Test de subida básico
            let uploadSpeed = try await measureUploadSpeed()
            
            let result = SpeedTestResult(
                downloadSpeed: downloadSpeed,
                uploadSpeed: uploadSpeed,
                latency: latency,
                error: nil
            )
            
            // Actualizar métricas
            await MainActor.run {
                self.latency = latency
                self.bandwidth.download = downloadSpeed
                self.bandwidth.upload = uploadSpeed
                self.connectionQuality = determineQuality(from: result)
                self.lastSpeedTest = Date()
            }
            
            return result
            
        } catch {
            await MainActor.run {
                self.errorHandler.handle(error, context: "Network Speed Test")
            }
            
            return SpeedTestResult(downloadSpeed: 0, uploadSpeed: 0, latency: 0, error: error.localizedDescription)
        }
    }
    
    /// Obtiene estadísticas de conectividad
    func getConnectivityStats() -> ConnectivityStats {
        let last24Hours = connectionHistory.filter { 
            $0.timestamp > Date().addingTimeInterval(-86400) 
        }
        
        let connectionTime = calculateTotalConnectionTime(in: last24Hours)
        let disconnectionCount = last24Hours.filter { !$0.isConnected }.count
        let avgConnectionDuration = calculateAverageConnectionDuration(in: last24Hours)
        
        return ConnectivityStats(
            uptime: connectionTime,
            disconnectionCount: disconnectionCount,
            averageConnectionDuration: avgConnectionDuration,
            currentSessionDuration: getCurrentSessionDuration(),
            connectionType: connectionType,
            quality: connectionQuality
        )
    }
    
    /// Verifica si la conexión es estable
    func isConnectionStable() -> Bool {
        let recentEvents = connectionHistory.filter { 
            $0.timestamp > Date().addingTimeInterval(-300) // Últimos 5 minutos
        }
        
        let disconnections = recentEvents.filter { !$0.isConnected }.count
        return disconnections < 3 // Menos de 3 desconexiones en 5 minutos
    }
    
    /// Obtiene recomendaciones basadas en la conectividad
    func getConnectionRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if !isConnected {
            recommendations.append("Verifica tu conexión a internet")
            recommendations.append("Prueba cambiar de WiFi a datos móviles o viceversa")
        } else {
            switch connectionQuality {
            case .poor:
                recommendations.append("La conexión es lenta. Considera cambiar de red")
                if connectionType == .wifi {
                    recommendations.append("Acércate al router WiFi")
                } else {
                    recommendations.append("Busca mejor señal de datos móviles")
                }
            case .fair:
                recommendations.append("La conexión es regular. Algunas funciones pueden ser lentas")
            case .good, .excellent:
                break // Sin recomendaciones
            case .unknown:
                recommendations.append("Realizando análisis de conexión...")
            }
        }
        
        if !isConnectionStable() {
            recommendations.append("La conexión es inestable. Evita operaciones críticas")
        }
        
        return recommendations
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handlePathUpdate(path)
            }
        }
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        let newStatus = determineStatus(from: path)
        let wasConnected = isConnected
        
        status = newStatus
        isConnected = newStatus.isConnected
        connectionType = determineConnectionType(from: path)
        
        // Registrar evento de conectividad
        let event = ConnectionEvent(
            timestamp: Date(),
            isConnected: isConnected,
            connectionType: connectionType,
            previousType: wasConnected ? connectionType : nil
        )
        addConnectionEvent(event)
        
        // Notificar cambios significativos
        if wasConnected != isConnected {
            notifyConnectionChange(isConnected: isConnected)
        }
        
        // Realizar speed test automático si es necesario
        if isConnected && shouldPerformSpeedTest() {
            Task {
                _ = await performSpeedTest()
            }
        }
    }
    
    private func determineStatus(from path: NWPath) -> NetworkStatus {
        switch path.status {
        case .satisfied:
            let type = determineConnectionType(from: path)
            return .connected(type)
        case .unsatisfied, .requiresConnection:
            return .disconnected
        @unknown default:
            return .unknown
        }
    }
    
    private func determineConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .other
        }
    }
    
    private func determineQuality(from result: SpeedTestResult) -> ConnectionQuality {
        let downloadMbps = result.downloadSpeed / (1024 * 1024) * 8 // Convert to Mbps
        
        if downloadMbps >= 25 {
            return .excellent
        } else if downloadMbps >= 10 {
            return .good
        } else if downloadMbps >= 3 {
            return .fair
        } else {
            return .poor
        }
    }
    
    private func shouldPerformSpeedTest() -> Bool {
        guard let lastTest = lastSpeedTest else { return true }
        return Date().timeIntervalSince(lastTest) > speedTestInterval
    }
    
    private func measureLatency() async throws -> TimeInterval {
        let startTime = Date()
        
        // Realizar una solicitud HTTP simple para medir latency
        let url = URL(string: "https://www.google.com")!
        let request = URLRequest(url: url, timeoutInterval: 5.0)
        
        _ = try await URLSession.shared.data(for: request)
        
        return Date().timeIntervalSince(startTime)
    }
    
    private func measureDownloadSpeed() async throws -> Double {
        // URL de test de descarga (1MB)
        let url = URL(string: "https://httpbin.org/bytes/1048576")!
        let startTime = Date()
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let duration = Date().timeIntervalSince(startTime)
        
        return Double(data.count) / duration // bytes por segundo
    }
    
    private func measureUploadSpeed() async throws -> Double {
        // Simular upload con POST de datos
        let url = URL(string: "https://httpbin.org/post")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Crear datos de prueba (100KB)
        let testData = Data(repeating: 0, count: 102400)
        request.httpBody = testData
        
        let startTime = Date()
        _ = try await URLSession.shared.data(for: request)
        let duration = Date().timeIntervalSince(startTime)
        
        return Double(testData.count) / duration // bytes por segundo
    }
    
    private func notifyConnectionChange(isConnected: Bool) {
        let message = isConnected ? "Conexión restablecida" : "Sin conexión a internet"
        
        // Notificar a través del ErrorHandler si se perdió la conexión
        if !isConnected {
            let error = NetworkError(
                underlyingError: URLError(.notConnectedToInternet),
                context: "Connection lost"
            )
            errorHandler.handle(error, autoRetry: false)
        }
        
        // Notificación del sistema
        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: nil,
            userInfo: ["isConnected": isConnected, "message": message]
        )
    }
    
    private func addConnectionEvent(_ event: ConnectionEvent) {
        connectionHistory.insert(event, at: 0)
        
        // Limitar tamaño del historial
        if connectionHistory.count > maxHistorySize {
            connectionHistory = Array(connectionHistory.prefix(maxHistorySize))
        }
        
        saveConnectionHistory()
    }
    
    private func calculateTotalConnectionTime(in events: [ConnectionEvent]) -> TimeInterval {
        var totalTime: TimeInterval = 0
        var lastConnectedTime: Date?
        
        for event in events.sorted(by: { $0.timestamp < $1.timestamp }) {
            if event.isConnected {
                lastConnectedTime = event.timestamp
            } else if let connectedTime = lastConnectedTime {
                totalTime += event.timestamp.timeIntervalSince(connectedTime)
                lastConnectedTime = nil
            }
        }
        
        // Añadir tiempo hasta ahora si actualmente está conectado
        if isConnected, let connectedTime = lastConnectedTime {
            totalTime += Date().timeIntervalSince(connectedTime)
        }
        
        return totalTime
    }
    
    private func calculateAverageConnectionDuration(in events: [ConnectionEvent]) -> TimeInterval {
        let connectionPeriods = getConnectionPeriods(from: events)
        guard !connectionPeriods.isEmpty else { return 0 }
        
        let totalDuration = connectionPeriods.reduce(0, +)
        return totalDuration / Double(connectionPeriods.count)
    }
    
    private func getConnectionPeriods(from events: [ConnectionEvent]) -> [TimeInterval] {
        var periods: [TimeInterval] = []
        var lastConnectedTime: Date?
        
        for event in events.sorted(by: { $0.timestamp < $1.timestamp }) {
            if event.isConnected {
                lastConnectedTime = event.timestamp
            } else if let connectedTime = lastConnectedTime {
                periods.append(event.timestamp.timeIntervalSince(connectedTime))
                lastConnectedTime = nil
            }
        }
        
        return periods
    }
    
    private func getCurrentSessionDuration() -> TimeInterval {
        guard isConnected else { return 0 }
        
        // Buscar el último evento de conexión
        if let lastConnection = connectionHistory.first(where: { $0.isConnected }) {
            return Date().timeIntervalSince(lastConnection.timestamp)
        }
        
        return 0
    }
    
    // MARK: - Persistence
    private func loadConnectionHistory() {
        if let history: [ConnectionEvent] = cacheManager.get(forKey: "connection_history") {
            connectionHistory = history
        }
    }
    
    private func saveConnectionHistory() {
        cacheManager.set(connectionHistory, forKey: "connection_history", duration: 86400 * 7) // 7 días
    }
    
    deinit {
        stopMonitoring()
    }
}

// MARK: - Supporting Types

/// Calidad de la conexión
enum ConnectionQuality: String, CaseIterable {
    case excellent = "excellent"
    case good = "good" 
    case fair = "fair"
    case poor = "poor"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excelente"
        case .good: return "Buena"
        case .fair: return "Regular"
        case .poor: return "Pobre"
        case .unknown: return "Desconocida"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        case .unknown: return "gray"
        }
    }
}

/// Evento de conectividad
struct ConnectionEvent: Codable {
    let timestamp: Date
    let isConnected: Bool
    let connectionType: ConnectionType
    let previousType: ConnectionType?
}

/// Resultado del test de velocidad
struct SpeedTestResult {
    let downloadSpeed: Double // bytes por segundo
    let uploadSpeed: Double // bytes por segundo
    let latency: TimeInterval // segundos
    let error: String?
    
    var downloadSpeedMbps: Double {
        return downloadSpeed / (1024 * 1024) * 8
    }
    
    var uploadSpeedMbps: Double {
        return uploadSpeed / (1024 * 1024) * 8
    }
    
    var latencyMs: Double {
        return latency * 1000
    }
}

/// Ancho de banda
struct Bandwidth {
    var download: Double = 0 // bytes por segundo
    var upload: Double = 0 // bytes por segundo
    
    var downloadMbps: Double {
        return download / (1024 * 1024) * 8
    }
    
    var uploadMbps: Double {
        return upload / (1024 * 1024) * 8
    }
}

/// Estadísticas de conectividad
struct ConnectivityStats {
    let uptime: TimeInterval
    let disconnectionCount: Int
    let averageConnectionDuration: TimeInterval
    let currentSessionDuration: TimeInterval
    let connectionType: ConnectionType
    let quality: ConnectionQuality
    
    var uptimePercentage: Double {
        let totalTime: TimeInterval = 86400 // 24 horas
        return min(uptime / totalTime * 100, 100)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}