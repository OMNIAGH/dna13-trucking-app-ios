//
//  ErrorHandler.swift
//  DNA13TruckingApp
//
//  Manejador centralizado de errores para toda la aplicación
//  Proporciona manejo consistente, logging y recuperación de errores
//

import Foundation
import SwiftUI
import Combine

/// Protocolo para errores que pueden ser manejados por el sistema
protocol AppError: Error, LocalizedError {
    var category: ErrorCategory { get }
    var severity: ErrorSeverity { get }
    var isRecoverable: Bool { get }
    var userFriendlyMessage: String { get }
    var technicalDetails: String { get }
    var suggestedActions: [String] { get }
}

/// Categorías de errores en la aplicación
enum ErrorCategory: String, CaseIterable {
    case network = "network"
    case authentication = "authentication"
    case database = "database"
    case validation = "validation"
    case permission = "permission"
    case system = "system"
    case external = "external"
    case user = "user"
}

/// Severidad del error
enum ErrorSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var description: String {
        switch self {
        case .low: return "Bajo"
        case .medium: return "Medio"
        case .high: return "Alto"
        case .critical: return "Crítico"
        }
    }
}

/// Acciones de recuperación disponibles
enum RecoveryAction {
    case retry
    case login
    case refresh
    case settings
    case contact
    case ignore
    case restart
    
    var title: String {
        switch self {
        case .retry: return "Reintentar"
        case .login: return "Iniciar Sesión"
        case .refresh: return "Actualizar"
        case .settings: return "Configuración"
        case .contact: return "Contactar Soporte"
        case .ignore: return "Ignorar"
        case .restart: return "Reiniciar App"
        }
    }
}

/// Manejador centralizado de errores
@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    // MARK: - Published Properties
    @Published var currentError: ErrorPresentation?
    @Published var errorHistory: [ErrorLog] = []
    @Published var isShowingError: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let cacheManager = CacheManager.shared
    private let maxErrorHistory = 100
    
    // Retry logic
    private var retryAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3
    
    private init() {
        loadErrorHistory()
        setupErrorCleanup()
    }
    
    // MARK: - Public Methods
    
    /// Maneja un error y determina la acción apropiada
    func handle(_ error: Error, context: String = "", autoRetry: Bool = true) {
        let appError = convertToAppError(error, context: context)
        let errorLog = createErrorLog(appError, context: context)
        
        // Añadir al historial
        addToHistory(errorLog)
        
        // Determinar si auto-retry
        if autoRetry && appError.isRecoverable && shouldRetry(errorLog) {
            performRetry(for: appError, context: context)
        } else {
            presentError(appError, context: context)
        }
        
        // Log para análisis
        logError(errorLog)
    }
    
    /// Presenta un error al usuario
    func presentError(_ error: AppError, context: String = "") {
        let presentation = ErrorPresentation(
            error: error,
            context: context,
            actions: getAvailableActions(for: error),
            timestamp: Date()
        )
        
        currentError = presentation
        isShowingError = true
        
        // Auto-dismiss para errores de baja severidad
        if error.severity == .low {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.dismissError()
            }
        }
    }
    
    /// Dismisses the current error
    func dismissError() {
        currentError = nil
        isShowingError = false
    }
    
    /// Ejecuta una acción de recuperación
    func executeRecoveryAction(_ action: RecoveryAction, for error: AppError, context: String = "") {
        dismissError()
        
        switch action {
        case .retry:
            performRetry(for: error, context: context)
        case .login:
            // Trigger login flow
            NotificationCenter.default.post(name: .userShouldLogin, object: nil)
        case .refresh:
            // Trigger data refresh
            NotificationCenter.default.post(name: .shouldRefreshData, object: context)
        case .settings:
            // Open settings
            NotificationCenter.default.post(name: .shouldOpenSettings, object: nil)
        case .contact:
            // Open support contact
            openSupportContact(error: error, context: context)
        case .restart:
            // Request app restart
            NotificationCenter.default.post(name: .shouldRestartApp, object: nil)
        case .ignore:
            // Do nothing, error is dismissed
            break
        }
    }
    
    /// Verifica si hay errores críticos pendientes
    func hasCriticalErrors() -> Bool {
        return errorHistory.contains { $0.severity == .critical && $0.timestamp > Date().addingTimeInterval(-300) }
    }
    
    /// Obtiene estadísticas de errores
    func getErrorStatistics() -> ErrorStatistics {
        let last24Hours = errorHistory.filter { $0.timestamp > Date().addingTimeInterval(-86400) }
        let byCategory = Dictionary(grouping: last24Hours, by: { $0.category })
        let bySeverity = Dictionary(grouping: last24Hours, by: { $0.severity })
        
        return ErrorStatistics(
            totalErrors: last24Hours.count,
            errorsByCategory: byCategory.mapValues { $0.count },
            errorsBySeverity: bySeverity.mapValues { $0.count },
            mostCommonError: getMostCommonError(in: last24Hours),
            criticalErrorCount: bySeverity[.critical]?.count ?? 0
        )
    }
    
    // MARK: - Private Methods
    
    private func convertToAppError(_ error: Error, context: String) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // Convertir errores conocidos
        switch error {
        case let urlError as URLError:
            return NetworkError.from(urlError)
        case let decodingError as DecodingError:
            return ValidationError.from(decodingError)
        default:
            return SystemError.unknown(error, context: context)
        }
    }
    
    private func createErrorLog(_ error: AppError, context: String) -> ErrorLog {
        return ErrorLog(
            id: UUID(),
            timestamp: Date(),
            category: error.category,
            severity: error.severity,
            message: error.userFriendlyMessage,
            technicalDetails: error.technicalDetails,
            context: context,
            isResolved: false
        )
    }
    
    private func shouldRetry(_ errorLog: ErrorLog) -> Bool {
        let errorKey = "\(errorLog.category.rawValue)_\(errorLog.context)"
        let attempts = retryAttempts[errorKey, default: 0]
        return attempts < maxRetryAttempts && errorLog.category == .network
    }
    
    private func performRetry(for error: AppError, context: String) {
        let errorKey = "\(error.category.rawValue)_\(context)"
        retryAttempts[errorKey] = retryAttempts[errorKey, default: 0] + 1
        
        // Delay antes de retry
        let delay = Double(retryAttempts[errorKey]!) * 2.0 // Exponential backoff
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            NotificationCenter.default.post(name: .shouldRetryOperation, object: context)
        }
    }
    
    private func getAvailableActions(for error: AppError) -> [RecoveryAction] {
        var actions: [RecoveryAction] = []
        
        if error.isRecoverable {
            actions.append(.retry)
        }
        
        switch error.category {
        case .authentication:
            actions.append(.login)
        case .network:
            actions.append(.refresh)
        case .system:
            actions.append(.restart)
        case .permission:
            actions.append(.settings)
        default:
            break
        }
        
        // Siempre ofrecer contactar soporte para errores críticos
        if error.severity >= .high {
            actions.append(.contact)
        }
        
        actions.append(.ignore)
        return actions
    }
    
    private func addToHistory(_ errorLog: ErrorLog) {
        errorHistory.insert(errorLog, at: 0)
        
        // Limitar historial
        if errorHistory.count > maxErrorHistory {
            errorHistory = Array(errorHistory.prefix(maxErrorHistory))
        }
        
        saveErrorHistory()
    }
    
    private func logError(_ errorLog: ErrorLog) {
        // Log a analytics/crash reporting
        print("🔥 ERROR: [\(errorLog.category.rawValue.uppercased())] \(errorLog.message)")
        print("   Context: \(errorLog.context)")
        print("   Severity: \(errorLog.severity.description)")
        print("   Details: \(errorLog.technicalDetails)")
    }
    
    private func openSupportContact(error: AppError, context: String) {
        let subject = "Error en D.N.A 13 Trucking App"
        let body = """
        Detalles del Error:
        - Categoría: \(error.category.rawValue)
        - Severidad: \(error.severity.description)
        - Mensaje: \(error.userFriendlyMessage)
        - Contexto: \(context)
        - Detalles técnicos: \(error.technicalDetails)
        - Timestamp: \(Date())
        
        Por favor describe qué estabas haciendo cuando ocurrió el error:
        """
        
        if let url = URL(string: "mailto:soporte@dna13trucking.com?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func getMostCommonError(in errors: [ErrorLog]) -> String? {
        let grouped = Dictionary(grouping: errors, by: { $0.message })
        return grouped.max(by: { $0.value.count < $1.value.count })?.key
    }
    
    private func setupErrorCleanup() {
        // Limpiar errores antiguos cada hora
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupOldErrors()
            }
            .store(in: &cancellables)
    }
    
    private func cleanupOldErrors() {
        let cutoffDate = Date().addingTimeInterval(-86400) // 24 horas
        errorHistory.removeAll { $0.timestamp < cutoffDate }
        saveErrorHistory()
    }
    
    // MARK: - Persistence
    private func loadErrorHistory() {
        if let history: [ErrorLog] = cacheManager.get(forKey: "error_history") {
            errorHistory = history
        }
    }
    
    private func saveErrorHistory() {
        cacheManager.set(errorHistory, forKey: "error_history", duration: 86400 * 7) // 7 días
    }
}

// MARK: - Supporting Types

struct ErrorPresentation {
    let error: AppError
    let context: String
    let actions: [RecoveryAction]
    let timestamp: Date
}

struct ErrorLog: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let category: ErrorCategory
    let severity: ErrorSeverity
    let message: String
    let technicalDetails: String
    let context: String
    var isResolved: Bool
}

struct ErrorStatistics {
    let totalErrors: Int
    let errorsByCategory: [ErrorCategory: Int]
    let errorsBySeverity: [ErrorSeverity: Int]
    let mostCommonError: String?
    let criticalErrorCount: Int
}

// MARK: - Concrete Error Types

struct NetworkError: AppError {
    let underlyingError: URLError
    let context: String
    
    var category: ErrorCategory { .network }
    var severity: ErrorSeverity {
        switch underlyingError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .high
        case .timedOut, .cannotFindHost:
            return .medium
        default:
            return .low
        }
    }
    var isRecoverable: Bool { true }
    
    var userFriendlyMessage: String {
        switch underlyingError.code {
        case .notConnectedToInternet:
            return "Sin conexión a internet. Verifica tu conexión."
        case .timedOut:
            return "La conexión tardó demasiado. Vuelve a intentar."
        case .cannotFindHost:
            return "No se pudo conectar al servidor."
        default:
            return "Error de red. Verifica tu conexión."
        }
    }
    
    var technicalDetails: String {
        return "URLError: \(underlyingError.localizedDescription) (\(underlyingError.code.rawValue))"
    }
    
    var suggestedActions: [String] {
        return [
            "Verifica tu conexión a internet",
            "Inténtalo de nuevo",
            "Cambia de red WiFi a datos móviles"
        ]
    }
    
    static func from(_ urlError: URLError) -> NetworkError {
        return NetworkError(underlyingError: urlError, context: "")
    }
}

struct ValidationError: AppError {
    let field: String
    let reason: String
    
    var category: ErrorCategory { .validation }
    var severity: ErrorSeverity { .medium }
    var isRecoverable: Bool { true }
    
    var userFriendlyMessage: String {
        return "Error en \(field): \(reason)"
    }
    
    var technicalDetails: String {
        return "Validation failed for field '\(field)': \(reason)"
    }
    
    var suggestedActions: [String] {
        return [
            "Verifica los datos ingresados",
            "Asegúrate de completar todos los campos requeridos"
        ]
    }
    
    static func from(_ decodingError: DecodingError) -> ValidationError {
        switch decodingError {
        case .keyNotFound(let key, _):
            return ValidationError(field: key.stringValue, reason: "Campo requerido faltante")
        case .typeMismatch(_, let context):
            return ValidationError(field: context.codingPath.last?.stringValue ?? "unknown", reason: "Tipo de dato incorrecto")
        case .valueNotFound(_, let context):
            return ValidationError(field: context.codingPath.last?.stringValue ?? "unknown", reason: "Valor faltante")
        case .dataCorrupted(let context):
            return ValidationError(field: "data", reason: context.debugDescription)
        @unknown default:
            return ValidationError(field: "unknown", reason: "Error de decodificación")
        }
    }
}

struct SystemError: AppError {
    let underlyingError: Error
    let context: String
    
    var category: ErrorCategory { .system }
    var severity: ErrorSeverity { .high }
    var isRecoverable: Bool { false }
    
    var userFriendlyMessage: String {
        return "Error del sistema. La aplicación puede necesitar reiniciarse."
    }
    
    var technicalDetails: String {
        return "System error in \(context): \(underlyingError.localizedDescription)"
    }
    
    var suggestedActions: [String] {
        return [
            "Reinicia la aplicación",
            "Contacta al soporte técnico"
        ]
    }
    
    static func unknown(_ error: Error, context: String) -> SystemError {
        return SystemError(underlyingError: error, context: context)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userShouldLogin = Notification.Name("userShouldLogin")
    static let shouldRefreshData = Notification.Name("shouldRefreshData")
    static let shouldOpenSettings = Notification.Name("shouldOpenSettings")
    static let shouldRestartApp = Notification.Name("shouldRestartApp")
    static let shouldRetryOperation = Notification.Name("shouldRetryOperation")
}