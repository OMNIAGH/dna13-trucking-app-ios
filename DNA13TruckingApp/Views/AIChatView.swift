import SwiftUI
import Speech

// MARK: - AI Chat View
struct AIChatView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    @State private var messages: [ChatMessageModel] = []
    @State private var currentMessage = ""
    @State private var isTyping = false
    @State private var isListening = false
    @State private var showingVoiceInput = false
    
    // Speech recognition
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    
    private let conversationId = UUID()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.dnaBackground, .dnaGreenDark.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(messages) { message in
                                    MessageBubbleView(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) { _ in
                            withAnimation(.easeInOut) {
                                if let lastMessage = messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Typing Indicator
                    if isTyping {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.dnaOrange)
                                .font(.system(size: 16))
                            
                            Text("La IA está escribiendo...")
                                .font(Typography.bodySmall)
                                .foregroundColor(.dnaTextSecondary.opacity(0.8))
                        }
                        .padding()
                        .background(Color.dnaSurface)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    // Message Input
                    messageInputView
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .background(Color.dnaBackground)
                }
            }
            .navigationTitle("Chat IA")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Limpiar") {
                        messages.removeAll()
                    }
                    .font(Typography.buttonSmall)
                    .foregroundColor(.dnaOrange)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleVoiceInput) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 20))
                            .foregroundColor(isListening ? .red : .dnaOrange)
                    }
                }
            }
            .onAppear {
                initializeChat()
            }
        }
    }
    
    // MARK: - Initialize Chat
    private func initializeChat() {
        let welcomeMessage = ChatMessageModel(
            text: "¡Hola! Soy tu asistente IA especializado en D.N.A 13 Trucking. Puedo ayudarte con:\n\n🚛 Información sobre rutas y vehículos\n⛽ Optimización de combustible\n📄 Gestión de documentos\n📊 Análisis de datos de operación\n🗺️ Navegación y logística\n\n¿En qué puedo ayudarte hoy?",
            isUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    // MARK: - Message Input View
    private var messageInputView: some View {
        HStack(spacing: 12) {
            // Voice Input Button
            Button(action: toggleVoiceInput) {
                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.system(size: 20))
                    .foregroundColor(isListening ? .red : .dnaTextSecondary.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .background(isListening ? Color.red.opacity(0.2) : Color.dnaSurface)
                    .cornerRadius(22)
            }
            
            // Text Input
            HStack {
                TextField("Escribe tu mensaje...", text: $currentMessage, axis: .vertical)
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary)
                    .lineLimit(1...4)
                    .textFieldStyle(PlainTextFieldStyle())
                
                // Send Button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.dnaBackground)
                        .frame(width: 32, height: 32)
                        .background(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.dnaTextSecondary.opacity(0.3) : Color.dnaOrange)
                        .cornerRadius(16)
                }
                .disabled(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color.dnaSurface)
            .cornerRadius(24)
        }
    }
    
    // MARK: - Send Message
    private func sendMessage() {
        let messageText = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessageModel(
            text: messageText,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        currentMessage = ""
        
        // Show typing indicator
        isTyping = true
        
        Task {
            await processUserMessage(messageText)
        }
    }
    
    // MARK: - Process User Message
    private func processUserMessage(_ message: String) async {
        guard let user = authManager.currentUser else { return }
        
        // Create conversation history
        let conversationMessages = messages.map { msg in
            ChatMessage(role: msg.isUser ? "user" : "assistant", content: msg.text)
        }
        
        do {
            let response = try await SupabaseService.shared.callOpenAI(
                messages: conversationMessages,
                userId: user.id,
                tripId: appState.currentTrip?.id,
                vehicleId: appState.selectedVehicle?.id
            )
            
            await MainActor.run {
                isTyping = false
                
                let aiMessage = ChatMessageModel(
                    text: response.data.message,
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(aiMessage)
            }
        } catch {
            await MainActor.run {
                isTyping = false
                
                let errorMessage = ChatMessageModel(
                    text: "Lo siento, hubo un error al procesar tu mensaje. Por favor, inténtalo de nuevo.",
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(errorMessage)
            }
        }
    }
    
    // MARK: - Toggle Voice Input
    private func toggleVoiceInput() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    // MARK: - Start Voice Recognition
    private func startListening() {
        guard SFSpeechRecognizer.isRecognitionAvailable() else { return }
        
        isListening = true
        currentMessage = "Escuchando..."
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                currentMessage = result.bestTranscription.formattedString
            }
            
            if error != nil || result?.isFinal == true {
                self.stopListening()
            }
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        try? audioEngine.start()
    }
    
    // MARK: - Stop Voice Recognition
    private func stopListening() {
        isListening = false
        currentMessage = currentMessage == "Escuchando..." ? "" : currentMessage
        currentMessage = currentMessage.replacingOccurrences(of: "Escuchando...", with: "")
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }
}

// MARK: - Message Model
struct ChatMessageModel: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: ChatMessageModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    messageText
                    timestamp
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        // AI Avatar
                        Circle()
                            .fill(Color.dnaOrange)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "brain")
                                    .font(.system(size: 16))
                                    .foregroundColor(.dnaBackground)
                            )
                        
                        messageText
                    }
                    
                    timestamp
                }
                
                Spacer(minLength: 60)
            }
        }
    }
    
    private var messageText: some View {
        Text(message.text)
            .font(Typography.body)
            .foregroundColor(message.isUser ? .dnaBackground : .dnaTextSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(message.isUser ? Color.dnaOrange : Color.dnaSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(message.isUser ? Color.dnaOrange : Color.dnaTextSecondary.opacity(0.1), lineWidth: 1)
            )
    }
    
    private var timestamp: some View {
        Text(message.timestamp, style: .time)
            .font(Typography.caption)
            .foregroundColor(.dnaTextSecondary.opacity(0.6))
    }
}

#Preview {
    AIChatView()
        .environmentObject(AuthManager())
        .environmentObject(AppState())
}
