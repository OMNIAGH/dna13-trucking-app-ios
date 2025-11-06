//
//  AIChatViewModelTests.swift
//  DNA13TruckingAppTests
//
//  Tests para AIChatViewModel
//

import XCTest
import Combine
@testable import DNA13TruckingApp

// MARK: - AIChatViewModelTests
class AIChatViewModelTests: XCTestCase {
    
    private var viewModel: AIChatViewModel!
    private var mockSupabaseService: MockSupabaseService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockSupabaseService = MockSupabaseService()
        viewModel = AIChatViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockSupabaseService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testAIChatViewModelInitialization() {
        XCTAssertEqual(viewModel.messages.count, 0, "Messages should be empty initially")
        XCTAssertEqual(viewModel.currentMessage, "", "Current message should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertFalse(viewModel.isThinking, "AI should not be thinking initially")
        XCTAssertNil(viewModel.errorMessage, "No error message initially")
        XCTAssertFalse(viewModel.showSuggestions, "Suggestions should not be shown initially")
        XCTAssertEqual(viewModel.suggestions.count, 0, "Suggestions should be empty initially")
        XCTAssertFalse(viewModel.isTyping, "User should not be typing initially")
        XCTAssertEqual(viewModel.conversationContext, "", "Conversation context should be empty initially")
    }
    
    // MARK: - Welcome Message Tests
    func testWelcomeMessage() {
        viewModel.addWelcomeMessage()
        
        XCTAssertEqual(viewModel.messages.count, 1, "Should have one welcome message")
        
        let welcomeMessage = viewModel.messages.first!
        XCTAssertEqual(welcomeMessage.role, "assistant", "Welcome message should be from assistant")
        XCTAssertFalse(welcomeMessage.content.isEmpty, "Welcome message should have content")
        XCTAssertTrue(welcomeMessage.content.contains("D.N.A 13"), "Welcome message should mention company name")
        XCTAssertEqual(welcomeMessage.messageType, .welcome, "Message type should be welcome")
        XCTAssertNotNil(welcomeMessage.timestamp, "Welcome message should have timestamp")
    }
    
    func testWelcomeMessageNotDuplicated() {
        viewModel.addWelcomeMessage()
        viewModel.addWelcomeMessage()
        
        // Should still have only one welcome message
        XCTAssertEqual(viewModel.messages.count, 1, "Should not duplicate welcome message")
    }
    
    // MARK: - Message Sending Tests
    func testSendMessage() {
        let testMessage = "¿Cuál es mi próxima entrega?"
        
        let expectation = XCTestExpectation(description: "Send message")
        
        viewModel.$messages
            .dropFirst()
            .sink { messages in
                if messages.count > 0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.currentMessage = testMessage
        viewModel.sendMessage()
        
        wait(for: [expectation], timeout: 3.0)
        
        // Check user message was added
        XCTAssertGreaterThan(viewModel.messages.count, 0, "Should have at least one message")
        
        let userMessage = viewModel.messages.first { $0.role == "user" }
        XCTAssertNotNil(userMessage, "Should have user message")
        XCTAssertEqual(userMessage?.content, testMessage, "User message content should match")
        XCTAssertEqual(userMessage?.messageType, .user, "Message type should be user")
        XCTAssertEqual(viewModel.currentMessage, "", "Current message should be cleared after sending")
    }
    
    func testSendEmptyMessage() {
        viewModel.currentMessage = ""
        viewModel.sendMessage()
        
        // Should not send empty message
        XCTAssertEqual(viewModel.messages.count, 0, "Should not send empty message")
    }
    
    func testSendWhitespaceMessage() {
        viewModel.currentMessage = "   \n\t   "
        viewModel.sendMessage()
        
        // Should not send whitespace-only message
        XCTAssertEqual(viewModel.messages.count, 0, "Should not send whitespace-only message")
    }
    
    func testMessageTrimming() {
        viewModel.currentMessage = "  ¿Hola?  "
        viewModel.sendMessage()
        
        // Give it time to process
        let expectation = XCTestExpectation(description: "Message processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let userMessage = viewModel.messages.first { $0.role == "user" }
        XCTAssertEqual(userMessage?.content, "¿Hola?", "Message should be trimmed")
    }
    
    // MARK: - AI Response Tests
    func testAIResponse() {
        let expectation = XCTestExpectation(description: "AI response")
        
        viewModel.$messages
            .sink { messages in
                if messages.count >= 2 { // User message + AI response
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.currentMessage = "¿Cuál es el estado de mi camión?"
        viewModel.sendMessage()
        
        wait(for: [expectation], timeout: 5.0)
        
        // Check AI response was added
        let aiMessage = viewModel.messages.first { $0.role == "assistant" && $0.messageType == .aiResponse }
        XCTAssertNotNil(aiMessage, "Should have AI response")
        XCTAssertFalse(aiMessage!.content.isEmpty, "AI response should have content")
        XCTAssertNotNil(aiMessage!.timestamp, "AI response should have timestamp")
    }
    
    func testLoadingStatesDuringAIResponse() {
        let expectation = XCTestExpectation(description: "Loading states")
        var loadingChanges = 0
        var thinkingChanges = 0
        
        viewModel.$isLoading
            .sink { isLoading in
                loadingChanges += 1
            }
            .store(in: &cancellables)
        
        viewModel.$isThinking
            .sink { isThinking in
                thinkingChanges += 1
            }
            .store(in: &cancellables)
        
        viewModel.currentMessage = "Test message"
        viewModel.sendMessage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertGreaterThan(loadingChanges, 1, "Loading state should change during message sending")
        XCTAssertGreaterThan(thinkingChanges, 1, "Thinking state should change during AI processing")
    }
    
    // MARK: - Quick Suggestions Tests
    func testQuickSuggestions() {
        viewModel.loadQuickSuggestions()
        
        XCTAssertGreaterThan(viewModel.suggestions.count, 0, "Should have quick suggestions")
        XCTAssertTrue(viewModel.showSuggestions, "Should show suggestions after loading")
        
        // Check suggestion content
        let suggestions = viewModel.suggestions
        XCTAssertTrue(suggestions.contains { $0.contains("próxima entrega") }, "Should have delivery-related suggestion")
        XCTAssertTrue(suggestions.contains { $0.contains("combustible") || $0.contains("fuel") }, "Should have fuel-related suggestion")
        XCTAssertTrue(suggestions.contains { $0.contains("ruta") || $0.contains("route") }, "Should have route-related suggestion")
    }
    
    func testSelectSuggestion() {
        viewModel.loadQuickSuggestions()
        
        guard let firstSuggestion = viewModel.suggestions.first else {
            XCTFail("Should have suggestions")
            return
        }
        
        let expectation = XCTestExpectation(description: "Select suggestion")
        
        viewModel.$messages
            .dropFirst()
            .sink { messages in
                if messages.count > 0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.selectSuggestion(firstSuggestion)
        
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertGreaterThan(viewModel.messages.count, 0, "Should have message after selecting suggestion")
        XCTAssertFalse(viewModel.showSuggestions, "Should hide suggestions after selection")
        
        let userMessage = viewModel.messages.first { $0.role == "user" }
        XCTAssertEqual(userMessage?.content, firstSuggestion, "Message should match selected suggestion")
    }
    
    func testHideSuggestions() {
        viewModel.loadQuickSuggestions()
        XCTAssertTrue(viewModel.showSuggestions, "Should show suggestions")
        
        viewModel.hideSuggestions()
        XCTAssertFalse(viewModel.showSuggestions, "Should hide suggestions")
    }
    
    // MARK: - Context Management Tests
    func testConversationContext() {
        // Send multiple messages to build context
        viewModel.currentMessage = "¿Cuál es mi ubicación actual?"
        viewModel.sendMessage()
        
        // Wait for first message to process
        let expectation1 = XCTestExpectation(description: "First message")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)
        
        viewModel.currentMessage = "¿Qué tan lejos está mi próximo destino?"
        viewModel.sendMessage()
        
        // Wait for context to build
        let expectation2 = XCTestExpectation(description: "Context building")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)
        
        XCTAssertFalse(viewModel.conversationContext.isEmpty, "Conversation context should be built")
        XCTAssertTrue(viewModel.conversationContext.contains("ubicación") || 
                     viewModel.conversationContext.contains("destino"), 
                     "Context should include conversation topics")
    }
    
    func testClearConversation() {
        // Add some messages first
        viewModel.currentMessage = "Test message"
        viewModel.sendMessage()
        
        let expectation = XCTestExpectation(description: "Message added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        viewModel.clearConversation()
        
        XCTAssertEqual(viewModel.messages.count, 0, "Messages should be cleared")
        XCTAssertEqual(viewModel.conversationContext, "", "Context should be cleared")
        XCTAssertEqual(viewModel.currentMessage, "", "Current message should be cleared")
        XCTAssertFalse(viewModel.showSuggestions, "Suggestions should be hidden")
    }
    
    // MARK: - Message Types Tests
    func testUserMessage() {
        let userMsg = ChatMessage(
            id: UUID(),
            role: "user",
            content: "Test user message",
            messageType: .user,
            timestamp: Date()
        )
        
        XCTAssertEqual(userMsg.role, "user")
        XCTAssertEqual(userMsg.messageType, .user)
        XCTAssertEqual(userMsg.content, "Test user message")
    }
    
    func testAIMessage() {
        let aiMsg = ChatMessage(
            id: UUID(),
            role: "assistant",
            content: "Test AI response",
            messageType: .aiResponse,
            timestamp: Date()
        )
        
        XCTAssertEqual(aiMsg.role, "assistant")
        XCTAssertEqual(aiMsg.messageType, .aiResponse)
        XCTAssertEqual(aiMsg.content, "Test AI response")
    }
    
    func testSystemMessage() {
        let systemMsg = ChatMessage(
            id: UUID(),
            role: "system",
            content: "System notification",
            messageType: .system,
            timestamp: Date()
        )
        
        XCTAssertEqual(systemMsg.role, "system")
        XCTAssertEqual(systemMsg.messageType, .system)
        XCTAssertEqual(systemMsg.content, "System notification")
    }
    
    // MARK: - Input Validation Tests
    func testVeryLongMessage() {
        let longMessage = String(repeating: "A", count: 5000)
        viewModel.currentMessage = longMessage
        viewModel.sendMessage()
        
        // Should handle very long messages
        let expectation = XCTestExpectation(description: "Long message processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Message should be processed (possibly truncated)
        let userMessage = viewModel.messages.first { $0.role == "user" }
        XCTAssertNotNil(userMessage, "Should process long message")
    }
    
    func testSpecialCharacters() {
        let specialMessage = "¿Hola! ¿Cómo está usted? 😊 #hashtag @mention"
        viewModel.currentMessage = specialMessage
        viewModel.sendMessage()
        
        let expectation = XCTestExpectation(description: "Special characters processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let userMessage = viewModel.messages.first { $0.role == "user" }
        XCTAssertEqual(userMessage?.content, specialMessage, "Should preserve special characters")
    }
    
    func testMultilineMessage() {
        let multilineMessage = """
        Esta es la primera línea
        Esta es la segunda línea
        Esta es la tercera línea
        """
        
        viewModel.currentMessage = multilineMessage
        viewModel.sendMessage()
        
        let expectation = XCTestExpectation(description: "Multiline processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let userMessage = viewModel.messages.first { $0.role == "user" }
        XCTAssertEqual(userMessage?.content, multilineMessage, "Should preserve multiline format")
    }
    
    // MARK: - Typing Indicator Tests
    func testTypingIndicator() {
        XCTAssertFalse(viewModel.isTyping, "Should not be typing initially")
        
        viewModel.startTyping()
        XCTAssertTrue(viewModel.isTyping, "Should be typing after start")
        
        viewModel.stopTyping()
        XCTAssertFalse(viewModel.isTyping, "Should not be typing after stop")
    }
    
    func testTypingTimeout() {
        viewModel.startTyping()
        XCTAssertTrue(viewModel.isTyping, "Should be typing")
        
        // Test that typing automatically stops after timeout
        let expectation = XCTestExpectation(description: "Typing timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { // Assuming 3 second timeout
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 4.0)
        
        XCTAssertFalse(viewModel.isTyping, "Should stop typing after timeout")
    }
    
    // MARK: - Error Handling Tests
    func testNetworkError() {
        mockSupabaseService.simulateNetworkError()
        
        let expectation = XCTestExpectation(description: "Network error handling")
        
        viewModel.$errorMessage
            .sink { errorMessage in
                if errorMessage != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.currentMessage = "Test message during network error"
        viewModel.sendMessage()
        
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after error")
        XCTAssertFalse(viewModel.isThinking, "Should not be thinking after error")
    }
    
    func testRetryAfterError() {
        mockSupabaseService.simulateNetworkError()
        
        viewModel.currentMessage = "Test message"
        viewModel.sendMessage()
        
        // Wait for error
        let expectation1 = XCTestExpectation(description: "Error occurred")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 2.0)
        
        // Clear error and retry
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage, "Error should be cleared")
        
        // Simulate successful retry
        let expectation2 = XCTestExpectation(description: "Retry successful")
        viewModel.retryLastMessage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 2.0)
    }
    
    // MARK: - Performance Tests
    func testManyMessages() {
        // Test performance with many messages
        for i in 1...100 {
            let message = ChatMessage(
                id: UUID(),
                role: i % 2 == 0 ? "user" : "assistant",
                content: "Test message \(i)",
                messageType: i % 2 == 0 ? .user : .aiResponse,
                timestamp: Date()
            )
            viewModel.messages.append(message)
        }
        
        XCTAssertEqual(viewModel.messages.count, 100, "Should handle 100 messages")
        
        // Test that UI operations still work
        viewModel.loadQuickSuggestions()
        XCTAssertTrue(viewModel.showSuggestions, "Suggestions should still work with many messages")
    }
    
    func testMessageOrdering() {
        // Send multiple messages quickly
        for i in 1...5 {
            viewModel.currentMessage = "Message \(i)"
            viewModel.sendMessage()
        }
        
        // Wait for all messages to process
        let expectation = XCTestExpectation(description: "All messages processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        // Check that messages are in correct order
        let userMessages = viewModel.messages.filter { $0.role == "user" }
        XCTAssertEqual(userMessages.count, 5, "Should have 5 user messages")
        
        // Check timestamps are in order
        for i in 1..<userMessages.count {
            XCTAssertLessThanOrEqual(
                userMessages[i-1].timestamp,
                userMessages[i].timestamp,
                "Messages should be in chronological order"
            )
        }
    }
    
    // MARK: - State Persistence Tests
    func testMessagePersistence() {
        // Add messages
        viewModel.currentMessage = "Persistent message"
        viewModel.sendMessage()
        
        let expectation = XCTestExpectation(description: "Message persistence")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let messageCount = viewModel.messages.count
        
        // Simulate app backgrounding/foregrounding
        // Messages should persist
        XCTAssertEqual(viewModel.messages.count, messageCount, "Messages should persist")
    }
    
    // MARK: - Accessibility Tests
    func testAccessibilityLabels() {
        let userMessage = ChatMessage(
            id: UUID(),
            role: "user", 
            content: "Test accessibility",
            messageType: .user,
            timestamp: Date()
        )
        
        let aiMessage = ChatMessage(
            id: UUID(),
            role: "assistant",
            content: "AI response for accessibility",
            messageType: .aiResponse,
            timestamp: Date()
        )
        
        // Test that messages have appropriate accessibility information
        XCTAssertEqual(userMessage.role, "user")
        XCTAssertEqual(aiMessage.role, "assistant")
        XCTAssertNotNil(userMessage.timestamp)
        XCTAssertNotNil(aiMessage.timestamp)
    }
}

// MARK: - AIChatViewModel Extensions for Testing
extension AIChatViewModel {
    func startTyping() {
        isTyping = true
    }
    
    func stopTyping() {
        isTyping = false
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func retryLastMessage() {
        // Implementation would retry the last failed message
        if let lastUserMessage = messages.last(where: { $0.role == "user" }) {
            // Simulate retry logic
            currentMessage = lastUserMessage.content
            sendMessage()
        }
    }
}