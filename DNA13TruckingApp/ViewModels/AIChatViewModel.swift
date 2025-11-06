//
//  AIChatViewModel.swift
//  DNA13TruckingApp
//
//  ViewModel para la vista de chat con IA
//

import Foundation
import SwiftUI
import Combine

class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var currentMessage: String = ""
    @Published var isTyping: Bool = false
    @Published var conversationId: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let supabaseService = SupabaseService.shared
    
    init() {
        setupConversation()
        loadConversationHistory()
    }
    
    private func setupConversation() {
        // Crear o obtener ID de conversación
        conversationId = UUID().uuidString
    }
    
    func loadConversationHistory() {
        // Cargar historial de mensajes
        // TODO: Implementar carga desde Supabase
        loadSampleMessages()
    }
    
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = currentMessage
        currentMessage = ""
        
        // Crear mensaje del usuario
        let userMessage = createMessage(content: message, type: .text, isFromUser: true)
        messages.append(userMessage)
        
        // Mostrar indicador de escritura
        isTyping = true
        
        // Enviar a IA
        Task {
            await processAIResponse(to: message)
        }
    }
    
    private func processAIResponse(to userMessage: String) async {
        do {
            let response = try await supabaseService.sendChatMessage(
                message: userMessage,
                conversationId: conversationId
            )
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isTyping = false
                
                let aiMessage = self.createMessage(
                    content: response,
                    type: .text,
                    isFromUser: false
                )
                self.messages.append(aiMessage)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isTyping = false
                self.isLoading = false
                
                let errorMessage = self.createMessage(
                    content: "Lo siento, hubo un error al procesar tu mensaje. Por favor inténtalo de nuevo.",
                    type: .text,
                    isFromUser: false
                )
                self.messages.append(errorMessage)
            }
        }
    }
    
    private func createMessage(content: String, type: MessageType, isFromUser: Bool) -> ChatMessage {
        return ChatMessage(
            id: UUID(),
            conversationId: conversationId,
            senderUserId: isFromUser ? UUID() : UUID(), // TODO: Usar ID real del usuario
            encryptedBodyJson: content, // TODO: Encriptar en producción
            sentAt: Date(),
            messageType: type,
            isRead: true,
            createdAt: Date()
        )
    }
    
    func clearConversation() {
        messages.removeAll()
        setupConversation()
    }
    
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
    
    private func loadSampleMessages() {
        let welcomeMessage = createMessage(
            content: "¡Hola! Soy tu asistente de IA para D.N.A 13 Trucking. ¿En qué puedo ayudarte hoy?",
            type: .text,
            isFromUser: false
        )
        messages.append(welcomeMessage)
    }
}

// MARK: - Preset Prompts
extension AIChatViewModel {
    struct PresetPrompt: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let icon: String
    }
    
    static let presetPrompts = [
        PresetPrompt(
            title: "Buscar Cargas",
            message: "Busca cargas disponibles cerca de mi ubicación actual",
            icon: "truck"
        ),
        PresetPrompt(
            title: "Mantenimiento",
            message: "¿Qué mantenimiento necesita mi vehículo?",
            icon: "wrench"
        ),
        PresetPrompt(
            title: "Clima",
            message: "¿Hay alertas meteorológicas en mi ruta?",
            icon: "cloud.sun"
        ),
        PresetPrompt(
            title: "Eficiencia",
            message: "¿Cómo puedo mejorar mi eficiencia de combustible?",
            icon: "fuelpump"
        ),
        PresetPrompt(
            title: "Cumplimiento",
            message: "¿Tengo algún problema de cumplimiento pendiente?",
            icon: "exclamationmark.triangle"
        )
    ]
}