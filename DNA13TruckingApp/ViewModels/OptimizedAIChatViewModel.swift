//
//  OptimizedAIChatViewModel.swift
//  DNA13TruckingApp
//
//  ViewModel optimizado para la vista de chat con IA
//  Incluye: caching, debouncing, manejo de errores mejorado, procesamiento en background
//

import Foundation
import SwiftUI
import Combine

@MainActor
class OptimizedAIChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var currentMessage: String = ""
    @Published var isTyping: Bool = false
    @Published var conversationId: String = ""
    @Published var connectionStatus: ConnectionStatus = .connected
    @Published var errorMessage: String? = nil
    @Published var isRetrying: Bool = false
    @Published var messageCount: Int = 0
    @Published var canSendMessage: Bool = true
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let supabaseService = OptimizedSupabaseService.shared
    private let cacheManager = CacheManager.shared
    private let securityManager = SecurityManager.shared
    
    // Debouncing para envío de mensajes
    private let messageDebouncer = PassthroughSubject<String, Never>()
    private let typingDebouncer = PassthroughSubject<Void, Never>()
    
    // Rate limiting
    private var lastMessageTime: Date = Date.distantPast
    private let minMessageInterval: TimeInterval = 1.0 // 1 segundo entre mensajes
    
    // Retry logic
    private var retryAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    
    // Background processing
    private let backgroundQueue = DispatchQueue(label: "com.dna13.aichat", qos: .userInitiated)
    
    // MARK: - Initialization
    init() {
        setupConversation()
        setupDebouncing()
        loadConversationHistory()
        observeConnectionStatus()
    }
    
    // MARK: - Setup Methods
    private func setupConversation() {
        // Intentar recuperar conversación existente del cache
        if let cachedConversationId: String = cacheManager.get(forKey: "current_conversation_id") {
            conversationId = cachedConversationId
        } else {
            conversationId = UUID().uuidString
            cacheManager.set(conversationId, forKey: "current_conversation_id", duration: 86400) // 24 horas
        }
    }
    
    private func setupDebouncing() {
        // Debouncing para envío de mensajes
        messageDebouncer
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] message in
                Task { @MainActor in
                    await self?.processMessage(message)
                }
            }
            .store(in: &cancellables)
        
        // Debouncing para indicador de escritura
        typingDebouncer
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.isTyping = false
            }
            .store(in: &cancellables)
    }
    
    private func observeConnectionStatus() {
        // Simular observación del estado de conexión
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.checkConnectionStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func sendMessage() {
        let message = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        guard canSendMessage else { return }
        
        // Rate limiting
        let now = Date()
        guard now.timeIntervalSince(lastMessageTime) >= minMessageInterval else {
            showError("Por favor espera un momento antes de enviar otro mensaje")
            return
        }
        
        currentMessage = ""
        lastMessageTime = now
        clearError()
        
        // Usar debouncer
        messageDebouncer.send(message)
    }
    
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.isFromUser }) else { return }
        
        isRetrying = true
        clearError()
        
        Task {
            await processAIResponse(to: lastUserMessage.encryptedBodyJson)
            await MainActor.run {
                isRetrying = false
            }
        }
    }
    
    func clearConversation() {
        messages.removeAll()
        messageCount = 0
        retryAttempts.removeAll()
        cacheManager.remove(forKey: "conversation_\(conversationId)")
        setupConversation()
        clearError()
        
        // Añadir mensaje de bienvenida
        addWelcomeMessage()
    }
    
    func loadConversationHistory() {
        Task {
            await loadCachedMessages()
            
            if messages.isEmpty {
                await MainActor.run {
                    addWelcomeMessage()
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    func requestLoadRecommendation() {
        let message = "Busca cargas disponibles cerca de mi ubicación actual para los próximos días"
        currentMessage = message
        sendMessage()
    }
    
    func requestMaintenanceSchedule() {
        let message = "¿Qué mantenimiento necesita mi vehículo en los próximos 30 días?"
        currentMessage = message
        sendMessage()
    }
    
    func requestWeatherAlert() {
        let message = "¿Hay alertas meteorológicas en mi ruta actual?"
        currentMessage = message
        sendMessage()
    }
    
    func requestEfficiencyTips() {
        let message = "¿Cómo puedo mejorar mi eficiencia de combustible?"
        currentMessage = message
        sendMessage()
    }
    
    func requestComplianceCheck() {
        let message = "¿Tengo algún problema de cumplimiento pendiente?"
        currentMessage = message
        sendMessage()
    }
    
    // MARK: - Private Methods
    private func processMessage(_ message: String) async {
        // Crear mensaje del usuario
        let userMessage = createMessage(content: message, type: .text, isFromUser: true)
        
        await MainActor.run {
            messages.append(userMessage)
            messageCount += 1
            isTyping = true
        }
        
        // Guardar en cache
        await saveCachedMessages()
        
        // Procesar respuesta de IA
        await processAIResponse(to: message)
    }
    
    private func processAIResponse(to userMessage: String) async {
        do {
            // Verificar estado de conexión
            guard connectionStatus == .connected else {
                throw ChatError.noConnection
            }
            
            // Preparar contexto del chat
            let context = prepareContext()
            
            // Llamar al servicio de IA
            let response = try await supabaseService.sendChatMessage(
                message: userMessage,
                conversationId: conversationId,
                context: context
            )
            
            await MainActor.run {
                isTyping = false
                
                let aiMessage = createMessage(
                    content: response,
                    type: .text,
                    isFromUser: false
                )
                messages.append(aiMessage)
                messageCount += 1
                
                // Resetear contador de reintentos para este mensaje
                retryAttempts.removeValue(forKey: userMessage)
            }
            
            // Guardar en cache
            await saveCachedMessages()
            
        } catch {
            await handleChatError(error, for: userMessage)
        }
    }
    
    private func handleChatError(_ error: Error, for message: String) async {
        await MainActor.run {
            isTyping = false
            isLoading = false
        }
        
        // Determinar si debemos reintentar
        let attempts = retryAttempts[message, default: 0]
        
        if attempts < maxRetryAttempts && shouldRetry(error) {
            // Incrementar contador de reintentos
            retryAttempts[message] = attempts + 1
            
            // Esperar antes de reintentar
            try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            
            await processAIResponse(to: message)
        } else {
            // Máximo de reintentos alcanzado o error no recuperable
            let errorMessage = getErrorMessage(for: error)
            
            await MainActor.run {
                let errorChatMessage = createMessage(
                    content: errorMessage,
                    type: .error,
                    isFromUser: false
                )
                messages.append(errorChatMessage)
                messageCount += 1
                
                showError(errorMessage)
            }
            
            await saveCachedMessages()
        }
    }
    
    private func shouldRetry(_ error: Error) -> Bool {
        switch error {
        case ChatError.noConnection, ChatError.timeout, ChatError.serverError:
            return true
        case ChatError.invalidApiKey, ChatError.rateLimitExceeded, ChatError.invalidInput:
            return false
        default:
            return true
        }
    }
    
    private func getErrorMessage(for error: Error) -> String {
        switch error {
        case ChatError.noConnection:
            return "Sin conexión a internet. Verifica tu conexión y vuelve a intentar."
        case ChatError.timeout:
            return "La respuesta tardó demasiado. Vuelve a intentar."
        case ChatError.serverError:
            return "Error del servidor. Por favor inténtalo más tarde."
        case ChatError.invalidApiKey:
            return "Error de autenticación. Contacta al administrador."
        case ChatError.rateLimitExceeded:
            return "Has enviado demasiados mensajes. Espera un momento antes de continuar."
        case ChatError.invalidInput:
            return "Mensaje no válido. Verifica el contenido y vuelve a intentar."
        default:
            return "Error inesperado. Por favor inténtalo de nuevo."
        }
    }
    
    private func createMessage(content: String, type: MessageType, isFromUser: Bool) -> ChatMessage {
        let userId = isFromUser ? getCurrentUserId() : nil
        
        return ChatMessage(
            id: UUID(),
            conversationId: conversationId,
            senderUserId: userId,
            encryptedBodyJson: content,
            sentAt: Date(),
            messageType: type,
            isRead: !isFromUser, // Los mensajes del usuario se marcan como leídos automáticamente
            createdAt: Date()
        )
    }
    
    private func getCurrentUserId() -> UUID? {
        // TODO: Obtener ID real del usuario logueado
        return UUID()
    }
    
    private func prepareContext() -> String {
        // Preparar contexto basado en los últimos mensajes
        let recentMessages = messages.suffix(10)
        let context = recentMessages.map { message in
            let sender = message.isFromUser ? "Usuario" : "Asistente"
            return "\(sender): \(message.encryptedBodyJson)"
        }.joined(separator: "\n")
        
        return context
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = createMessage(
            content: "¡Hola! Soy tu asistente de IA para D.N.A 13 Trucking. ¿En qué puedo ayudarte hoy?",
            type: .text,
            isFromUser: false
        )
        messages.append(welcomeMessage)
        messageCount += 1
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        
        // Auto-clear error después de 5 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if self?.errorMessage == message {
                self?.errorMessage = nil
            }
        }
    }
    
    private func clearError() {
        errorMessage = nil
    }
    
    private func checkConnectionStatus() async {
        do {
            // Hacer un ping simple al servidor
            _ = try await supabaseService.checkHealth()
            connectionStatus = .connected
            canSendMessage = true
        } catch {
            connectionStatus = .disconnected
            canSendMessage = false
        }
    }
    
    // MARK: - Cache Management
    private func loadCachedMessages() async {
        let cacheKey = "conversation_\(conversationId)"
        
        if let cachedMessages: [ChatMessage] = cacheManager.get(forKey: cacheKey) {
            await MainActor.run {
                messages = cachedMessages
                messageCount = cachedMessages.count
            }
        }
    }
    
    private func saveCachedMessages() async {
        let cacheKey = "conversation_\(conversationId)"
        cacheManager.set(messages, forKey: cacheKey, duration: 86400) // 24 horas
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types
enum ConnectionStatus {
    case connected
    case disconnected
    case connecting
}

enum ChatError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverError
    case invalidApiKey
    case rateLimitExceeded
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Sin conexión a internet"
        case .timeout:
            return "Tiempo de espera agotado"
        case .serverError:
            return "Error del servidor"
        case .invalidApiKey:
            return "Clave de API inválida"
        case .rateLimitExceeded:
            return "Límite de velocidad excedido"
        case .invalidInput:
            return "Entrada inválida"
        }
    }
}

// MARK: - Preset Prompts Extension
extension OptimizedAIChatViewModel {
    struct PresetPrompt: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let icon: String
        let category: PromptCategory
    }
    
    enum PromptCategory {
        case loads
        case maintenance
        case weather
        case efficiency
        case compliance
        case navigation
    }
    
    static let presetPrompts = [
        PresetPrompt(
            title: "Buscar Cargas",
            message: "Busca cargas disponibles cerca de mi ubicación actual",
            icon: "truck",
            category: .loads
        ),
        PresetPrompt(
            title: "Mantenimiento",
            message: "¿Qué mantenimiento necesita mi vehículo?",
            icon: "wrench",
            category: .maintenance
        ),
        PresetPrompt(
            title: "Clima",
            message: "¿Hay alertas meteorológicas en mi ruta?",
            icon: "cloud.sun",
            category: .weather
        ),
        PresetPrompt(
            title: "Eficiencia",
            message: "¿Cómo puedo mejorar mi eficiencia de combustible?",
            icon: "fuelpump",
            category: .efficiency
        ),
        PresetPrompt(
            title: "Cumplimiento",
            message: "¿Tengo algún problema de cumplimiento pendiente?",
            icon: "exclamationmark.triangle",
            category: .compliance
        ),
        PresetPrompt(
            title: "Ruta Óptima",
            message: "¿Cuál es la mejor ruta para mi próxima entrega?",
            icon: "map",
            category: .navigation
        )
    ]
    
    func getPromptsByCategory(_ category: PromptCategory) -> [PresetPrompt] {
        return Self.presetPrompts.filter { $0.category == category }
    }
}

// MARK: - ChatMessage Extension
extension ChatMessage {
    var isFromUser: Bool {
        return senderUserId != nil
    }
    
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: sentAt)
    }
    
    var isError: Bool {
        return messageType == .error
    }
}