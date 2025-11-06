//
//  ViewModelErrorHandling.swift
//  DNA13TruckingApp
//
//  Protocolo y extensiones para manejo de errores en ViewModels
//  Proporciona funcionalidad común de manejo de errores y recuperación
//

import Foundation
import SwiftUI
import Combine

/// Protocolo para ViewModels que necesitan manejo de errores robusto
protocol ErrorHandlingViewModel: ObservableObject {
    var errorHandler: ErrorHandler { get }
    var networkMonitor: NetworkMonitor { get }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var cancellables: Set<AnyCancellable> { get set }
}

/// Extensión con funcionalidad común de manejo de errores
extension ErrorHandlingViewModel {
    
    // MARK: - Error Handling
    
    /// Ejecuta una operación async con manejo de errores automático
    func performOperation<T>(
        _ operation: @escaping () async throws -> T,
        context: String = "",
        showLoading: Bool = true,
        onSuccess: ((T) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        Task { @MainActor in
            if showLoading {
                isLoading = true
                clearError()
            }
            
            do {
                let result = try await operation()
                
                if showLoading {
                    isLoading = false
                }
                
                onSuccess?(result)
                
            } catch {
                if showLoading {
                    isLoading = false
                }
                
                handleError(error, context: context)
                onError?(error)
            }
        }
    }
    
    /// Ejecuta una operación con retry automático
    func performOperationWithRetry<T>(
        _ operation: @escaping () async throws -> T,
        context: String = "",
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 2.0,
        onSuccess: ((T) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        Task { @MainActor in
            isLoading = true
            clearError()
            
            var lastError: Error?
            
            for attempt in 1...maxRetries {
                do {
                    let result = try await operation()
                    isLoading = false
                    onSuccess?(result)
                    return
                    
                } catch {
                    lastError = error
                    
                    // Si no es el último intento, esperar antes de reintentar
                    if attempt < maxRetries {
                        try? await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attempt) * 1_000_000_000))
                    }
                }
            }
            
            // Todos los intentos fallaron
            isLoading = false
            if let error = lastError {
                handleError(error, context: "\(context) (after \(maxRetries) attempts)")
                onError?(error)
            }
        }
    }
    
    /// Maneja un error usando el ErrorHandler centralizado
    func handleError(_ error: Error, context: String = "") {
        errorHandler.handle(error, context: context, autoRetry: false)
        
        // También mostrar en UI local si es necesario
        if let appError = error as? AppError {
            errorMessage = appError.userFriendlyMessage
        } else {
            errorMessage = "Ha ocurrido un error inesperado"
        }
        
        // Auto-clear después de 5 segundos
        clearErrorAfterDelay()
    }
    
    /// Limpia el mensaje de error
    func clearError() {
        errorMessage = nil
    }
    
    /// Limpia el error después de un delay
    private func clearErrorAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.clearError()
        }
    }
    
    // MARK: - Network Monitoring
    
    /// Configura observadores de conectividad
    func setupNetworkObservers() {
        networkMonitor.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.onNetworkReconnected()
                } else {
                    self?.onNetworkDisconnected()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Se llama cuando se restablece la conexión
    func onNetworkReconnected() {
        // Override en ViewModels específicos si es necesario
    }
    
    /// Se llama cuando se pierde la conexión
    func onNetworkDisconnected() {
        // Override en ViewModels específicos si es necesario
    }
    
    /// Verifica conectividad antes de una operación
    func requiresConnection() -> Bool {
        guard networkMonitor.isConnected else {
            let error = NetworkError(
                underlyingError: URLError(.notConnectedToInternet),
                context: "Operation requires network connection"
            )
            handleError(error)
            return false
        }
        return true
    }
    
    // MARK: - Loading States
    
    /// Ejecuta múltiples operaciones en paralelo con estado de carga
    func performParallelOperations<T>(
        _ operations: [() async throws -> T],
        context: String = "",
        onSuccess: (([T]) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        Task { @MainActor in
            isLoading = true
            clearError()
            
            do {
                let results = try await withThrowingTaskGroup(of: T.self) { group in
                    for operation in operations {
                        group.addTask {
                            try await operation()
                        }
                    }
                    
                    var results: [T] = []
                    for try await result in group {
                        results.append(result)
                    }
                    return results
                }
                
                isLoading = false
                onSuccess?(results)
                
            } catch {
                isLoading = false
                handleError(error, context: context)
                onError?(error)
            }
        }
    }
    
    // MARK: - Validation
    
    /// Valida datos antes de una operación
    func validate<T>(
        _ data: T,
        using validators: [Validator<T>],
        onSuccess: (() -> Void)? = nil,
        onError: ((ValidationError) -> Void)? = nil
    ) -> Bool {
        for validator in validators {
            if let error = validator.validate(data) {
                let validationError = ValidationError(
                    field: validator.fieldName,
                    reason: error
                )
                handleError(validationError)
                onError?(validationError)
                return false
            }
        }
        
        onSuccess?()
        return true
    }
}

// MARK: - Validator Protocol

/// Protocolo para validadores de datos
protocol Validator<T> {
    associatedtype T
    var fieldName: String { get }
    func validate(_ value: T) -> String?
}

/// Validador para strings
struct StringValidator: Validator {
    let fieldName: String
    let minLength: Int?
    let maxLength: Int?
    let pattern: String?
    let isRequired: Bool
    
    init(
        fieldName: String,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil,
        isRequired: Bool = true
    ) {
        self.fieldName = fieldName
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.isRequired = isRequired
    }
    
    func validate(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isRequired && trimmed.isEmpty {
            return "Este campo es requerido"
        }
        
        if !trimmed.isEmpty {
            if let min = minLength, trimmed.count < min {
                return "Debe tener al menos \(min) caracteres"
            }
            
            if let max = maxLength, trimmed.count > max {
                return "No puede exceder \(max) caracteres"
            }
            
            if let pattern = pattern {
                let regex = try? NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: trimmed.utf16.count)
                if regex?.firstMatch(in: trimmed, options: [], range: range) == nil {
                    return "Formato no válido"
                }
            }
        }
        
        return nil
    }
}

/// Validador para emails
struct EmailValidator: Validator {
    let fieldName: String
    let isRequired: Bool
    
    init(fieldName: String = "Email", isRequired: Bool = true) {
        self.fieldName = fieldName
        self.isRequired = isRequired
    }
    
    func validate(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isRequired && trimmed.isEmpty {
            return "El email es requerido"
        }
        
        if !trimmed.isEmpty {
            let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !predicate.evaluate(with: trimmed) {
                return "Formato de email inválido"
            }
        }
        
        return nil
    }
}

/// Validador para números
struct NumberValidator: Validator {
    let fieldName: String
    let minValue: Double?
    let maxValue: Double?
    let isRequired: Bool
    
    init(
        fieldName: String,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        isRequired: Bool = true
    ) {
        self.fieldName = fieldName
        self.minValue = minValue
        self.maxValue = maxValue
        self.isRequired = isRequired
    }
    
    func validate(_ value: Double?) -> String? {
        if isRequired && value == nil {
            return "Este campo es requerido"
        }
        
        if let val = value {
            if let min = minValue, val < min {
                return "El valor debe ser mayor o igual a \(min)"
            }
            
            if let max = maxValue, val > max {
                return "El valor debe ser menor o igual a \(max)"
            }
        }
        
        return nil
    }
}

// MARK: - Common Validators

extension StringValidator {
    static func required(_ fieldName: String) -> StringValidator {
        return StringValidator(fieldName: fieldName, isRequired: true)
    }
    
    static func optional(_ fieldName: String) -> StringValidator {
        return StringValidator(fieldName: fieldName, isRequired: false)
    }
    
    static func phone(_ fieldName: String = "Teléfono") -> StringValidator {
        return StringValidator(
            fieldName: fieldName,
            minLength: 10,
            maxLength: 15,
            pattern: "^[+]?[0-9\\s\\-\\(\\)]+$"
        )
    }
    
    static func password(_ fieldName: String = "Contraseña") -> StringValidator {
        return StringValidator(
            fieldName: fieldName,
            minLength: 8,
            maxLength: 128,
            pattern: "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).+$"
        )
    }
}

// MARK: - ViewModelState

/// Enum para estados comunes de ViewModels
enum ViewModelState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
    case empty
    
    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .error(let message):
            return message
        default:
            return nil
        }
    }
}

// MARK: - LoadingState para operaciones específicas

/// Estado de carga para operaciones específicas
struct LoadingState {
    private var operations: Set<String> = []
    
    var isLoading: Bool {
        return !operations.isEmpty
    }
    
    mutating func start(_ operation: String) {
        operations.insert(operation)
    }
    
    mutating func finish(_ operation: String) {
        operations.remove(operation)
    }
    
    mutating func finishAll() {
        operations.removeAll()
    }
    
    func isOperationLoading(_ operation: String) -> Bool {
        return operations.contains(operation)
    }
}

// MARK: - CancellableOperation

/// Wrapper para operaciones que pueden ser canceladas
class CancellableOperation {
    private var task: Task<Void, Never>?
    
    func execute<T>(
        _ operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        cancel() // Cancelar operación anterior
        
        task = Task {
            do {
                let result = try await operation()
                if !Task.isCancelled {
                    await MainActor.run {
                        onSuccess(result)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        onError(error)
                    }
                }
            }
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
    
    deinit {
        cancel()
    }
}