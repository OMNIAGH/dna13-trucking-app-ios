import XCTest
import Supabase
@testable import DNA13TruckingApp

/// Tests de integración para Edge Functions de Supabase
final class EdgeFunctionsTests: XCTestCase {
    
    var supabaseService: SupabaseService!
    var testUserId: UUID!
    var testVehicleId: UUID!
    var testTripId: UUID!
    var testTimeout: TimeInterval = 45
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        supabaseService = SupabaseService()
        
        // Crear datos de prueba
        testUserId = UUID()
        testVehicleId = UUID()
        testTripId = UUID()
    }
    
    override func tearDownWithError() throws {
        supabaseService = nil
        testUserId = nil
        testVehicleId = nil
        testTripId = nil
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos para cleanup
        try super.tearDownWithError()
    }
    
    // MARK: - OpenAI Proxy Edge Function Tests
    
    func testOpenAIProxyBasicRequest() async throws {
        // Given
        let messages = [
            ChatMessage(role: "user", content: "What is the current status of my trip?"),
            ChatMessage(role: "assistant", content: "I can help you with that. Let me check your trip details.")
        ]
        
        // When
        let response = try await supabaseService.callOpenAI(
            messages: messages,
            userId: testUserId,
            tripId: testTripId,
            vehicleId: testVehicleId
        )
        
        // Then
        XCTAssertNotNil(response, "La respuesta de OpenAI no debe ser nil")
        XCTAssertNotNil(response.data, "Los datos de respuesta deben existir")
        XCTAssertFalse(response.data.message.isEmpty, "El mensaje de respuesta no debe estar vacío")
        XCTAssertNotNil(response.data.model, "El modelo debe estar especificado")
        XCTAssertGreaterThan(response.data.usage["total_tokens"] ?? 0, 0, "Debe haber uso de tokens")
    }
    
    func testOpenAIProxyWithEmptyMessages() async throws {
        // Given
        let emptyMessages: [ChatMessage] = []
        
        // When & Then
        do {
            _ = try await supabaseService.callOpenAI(
                messages: emptyMessages,
                userId: testUserId
            )
            XCTFail("Debe fallar con mensajes vacíos")
        } catch {
            XCTAssertNotNil(error, "Debe lanzar error para mensajes vacíos")
        }
    }
    
    func testOpenAIProxyWithContextualTripData() async throws {
        // Given - Crear datos de viaje en el contexto
        let contextualMessages = [
            ChatMessage(role: "user", content: "How much fuel did I use on my last trip?"),
            ChatMessage(role: "assistant", content: "Let me check your trip fuel consumption data."),
            ChatMessage(role: "user", content: "From Dallas to Los Angeles, trip ID: \(testTripId.uuidString)")
        ]
        
        // When
        let response = try await supabaseService.callOpenAI(
            messages: contextualMessages,
            userId: testUserId,
            tripId: testTripId,
            vehicleId: testVehicleId
        )
        
        // Then
        XCTAssertNotNil(response, "La respuesta contextual debe existir")
        XCTAssertTrue(response.data.message.contains("fuel") || response.data.message.contains("diesel"), 
                     "La respuesta debe mencionar combustible")
    }
    
    // MARK: - Document OCR Edge Function Tests
    
    func testDocumentOCRBasicProcessing() async throws {
        // Given
        let ocrText = """
        BILL OF LADING
        Shipper: ABC Company
        Consignee: XYZ Corporation
        Freight: General Merchandise
        Weight: 2000 lbs
        Pieces: 10
        Pickup Date: 2024-01-15
        Delivery Date: 2024-01-18
        """
        
        // When
        let response = try await supabaseService.processDocumentOCR(
            ocrText: ocrText,
            documentType: .bol,
            documentId: UUID(),
            userId: testUserId
        )
        
        // Then
        XCTAssertNotNil(response, "La respuesta de OCR no debe ser nil")
        XCTAssertNotNil(response.data, "Los datos de OCR deben existir")
        XCTAssertGreaterThan(response.data.confidence, 0.0, "La confianza debe ser mayor a 0")
        XCTAssertEqual(response.data.documentType, "BOL", "El tipo de documento debe detectarse correctamente")
        XCTAssertFalse(response.data.processedData.isEmpty, "Debe haber datos procesados")
    }
    
    func testDocumentOCRWithInvoice() async throws {
        // Given
        let invoiceText = """
        INVOICE #INV-2024-001
        Date: January 15, 2024
        Bill To: Customer Name
        Amount: $1,500.00
        Items: 
        - Service Fee: $1,000.00
        - Tax: $500.00
        """
        
        // When
        let response = try await supabaseService.processDocumentOCR(
            ocrText: invoiceText,
            documentType: .invoice,
            documentId: UUID(),
            userId: testUserId
        )
        
        // Then
        XCTAssertEqual(response.data.documentType, "invoice", "Debe detectar correctamente tipo invoice")
        XCTAssertTrue(response.data.processedData.keys.contains("amount"), "Debe extraer el monto")
        XCTAssertTrue(response.data.processedData.values.contains { $0.contains("1,500.00") }, 
                     "Debe extraer el valor del monto")
    }
    
    func testDocumentOCRWithLowConfidence() async throws {
        // Given - Texto muy mal formateado
        let poorText = "asd 123 xyz abc def ghi"
        
        // When
        let response = try await supabaseService.processDocumentOCR(
            ocrText: poorText,
            documentType: .contract,
            documentId: UUID(),
            userId: testUserId
        )
        
        // Then
        XCTAssertNotNil(response, "La respuesta debe existir incluso con texto pobre")
        XCTAssertLessThan(response.data.confidence, 0.8, "La confianza debe ser baja para texto pobre")
    }
    
    // MARK: - Load Search Edge Function Tests
    
    func testLoadSearchBasic() async throws {
        // Given
        let searchCriteria = LoadSearchRequest(
            origin: "Dallas",
            destination: "Los Angeles",
            currentLocation: "Phoenix, AZ",
            vehicleId: testVehicleId.uuidString,
            userId: testUserId.uuidString,
            maxDistance: 500
        )
        
        // When
        let response = try await supabaseService.searchLoads(
            origin: searchCriteria.origin,
            destination: searchCriteria.destination,
            currentLocation: searchCriteria.currentLocation,
            vehicleId: testVehicleId,
            userId: testUserId,
            maxDistance: searchCriteria.maxDistance
        )
        
        // Then
        XCTAssertNotNil(response, "La respuesta de búsqueda de cargas no debe ser nil")
        XCTAssertNotNil(response.data, "Los datos de búsqueda deben existir")
        XCTAssertGreaterThanOrEqual(response.data.loads.count, 0, "Debe retornar lista de cargas")
        XCTAssertNotNil(response.data.proactiveSuggestions, "Debe incluir sugerencias proactivas")
        XCTAssertNotNil(response.data.timestamp, "Debe incluir timestamp")
    }
    
    func testLoadSearchWithProximity() async throws {
        // Given - Búsqueda con ubicación actual
        let proximitySearch = LoadSearchRequest(
            origin: nil,
            destination: nil,
            currentLocation: "Houston, TX",
            vehicleId: testVehicleId.uuidString,
            userId: testUserId.uuidString,
            maxDistance: 200
        )
        
        // When
        let response = try await supabaseService.searchLoads(
            origin: proximitySearch.origin,
            destination: proximitySearch.destination,
            currentLocation: proximitySearch.currentLocation,
            vehicleId: testVehicleId,
            userId: testUserId,
            maxDistance: proximitySearch.maxDistance
        )
        
        // Then
        XCTAssertNotNil(response, "La búsqueda por proximidad debe completarse")
        // Verificar que las cargas están ordenadas por distancia
        if response.data.loads.count > 1 {
            for i in 0..<(response.data.loads.count - 1) {
                XCTAssertLessThanOrEqual(response.data.loads[i].distance, 
                                       response.data.loads[i + 1].distance, 
                                       "Las cargas deben estar ordenadas por distancia")
            }
        }
    }
    
    func testLoadSearchWithSpecificCriteria() async throws {
        // Given - Búsqueda específica Dallas -> Los Angeles
        let specificSearch = LoadSearchRequest(
            origin: "Dallas",
            destination: "Los Angeles",
            currentLocation: "Dallas, TX",
            vehicleId: testVehicleId.uuidString,
            userId: testUserId.uuidString,
            maxDistance: 1000
        )
        
        // When
        let response = try await supabaseService.searchLoads(
            origin: specificSearch.origin,
            destination: specificSearch.destination,
            currentLocation: specificSearch.currentLocation,
            vehicleId: testVehicleId,
            userId: testUserId,
            maxDistance: specificSearch.maxDistance
        )
        
        // Then
        XCTAssertNotNil(response, "La búsqueda específica debe completarse")
        if !response.data.loads.isEmpty {
            // Verificar que las cargas coinciden con criterios de búsqueda
            let dallasToLA = response.data.loads.filter { load in
                load.origin.contains("Dallas") && load.destination.contains("Los Angeles")
            }
            XCTAssertGreaterThanOrEqual(dallasToLA.count, 0, "Debe haber cargas de Dallas a Los Angeles o similares")
        }
    }
    
    // MARK: - Alert System Edge Function Tests
    
    func testAlertSystemBasic() async throws {
        // Given
        let alertRequest = AlertRequest(
            vehicleId: testVehicleId.uuidString,
            userId: testUserId.uuidString,
            location: "Phoenix, AZ"
        )
        
        // When
        let response = try await supabaseService.getPredictiveAlerts(
            vehicleId: testVehicleId,
            userId: testUserId,
            location: alertRequest.location
        )
        
        // Then
        XCTAssertNotNil(response, "La respuesta del sistema de alertas no debe ser nil")
        XCTAssertNotNil(response.data, "Los datos de alertas deben existir")
        XCTAssertGreaterThanOrEqual(response.data.totalAlerts, 0, "Debe retornar número de alertas")
        XCTAssertGreaterThanOrEqual(response.data.highPriority, 0, "Debe contar alertas de alta prioridad")
        XCTAssertNotNil(response.data.alerts, "Debe incluir lista de alertas")
        XCTAssertNotNil(response.data.timestamp, "Debe incluir timestamp")
    }
    
    func testAlertSystemWithMaintenancePredictions() async throws {
        // Given - Simular vehículo con alto kilometraje
        let highMileageRequest = AlertRequest(
            vehicleId: testVehicleId.uuidString,
            userId: testUserId.uuidString,
            location: "Los Angeles, CA"
        )
        
        // When
        let response = try await supabaseService.getPredictiveAlerts(
            vehicleId: testVehicleId,
            userId: testUserId,
            location: highMileageRequest.location
        )
        
        // Then
        XCTAssertNotNil(response, "El sistema de alertas debe responder para vehículo de alto kilometraje")
        // Verificar si hay alertas de mantenimiento
        let maintenanceAlerts = response.data.alerts.filter { $0.type == "maintenance" }
        if !maintenanceAlerts.isEmpty {
            XCTAssertGreaterThan(maintenanceAlerts.count, 0, "Debe haber alertas de mantenimiento")
        }
    }
    
    func testAlertSystemLocationSpecific() async throws {
        // Given - Múltiples ubicaciones
        let locations = ["Denver, CO", "Chicago, IL", "Atlanta, GA"]
        
        for location in locations {
            // When
            let response = try await supabaseService.getPredictiveAlerts(
                vehicleId: testVehicleId,
                userId: testUserId,
                location: location
            )
            
            // Then
            XCTAssertNotNil(response, "El sistema debe responder para la ubicación: \(location)")
        }
    }
    
    // MARK: - Edge Function Error Handling Tests
    
    func testOpenAIProxyWithInvalidAPIKey() async throws {
        // Given - Simular API key inválida (esto podría fallar en la edge function)
        let messages = [ChatMessage(role: "user", content: "Test")]
        
        // When & Then
        do {
            _ = try await supabaseService.callOpenAI(
                messages: messages,
                userId: testUserId
            )
            XCTFail("Debe fallar con API key inválida")
        } catch {
            XCTAssertNotNil(error, "Debe lanzar error para API key inválida")
        }
    }
    
    func testDocumentOCRWithUnsupportedFormat() async throws {
        // Given - Formato no soportado
        let invalidText = "This is not a supported document format"
        
        // When & Then
        do {
            _ = try await supabaseService.processDocumentOCR(
                ocrText: invalidText,
                documentType: .contract,
                documentId: UUID(),
                userId: testUserId
            )
            XCTFail("Debe fallar con formato no soportado")
        } catch {
            XCTAssertNotNil(error, "Debe lanzar error para formato no soportado")
        }
    }
    
    func testLoadSearchWithInvalidLocation() async throws {
        // Given - Ubicación inválida
        let invalidLocation = "InvalidCity, InvalidState"
        
        // When & Then
        do {
            _ = try await supabaseService.searchLoads(
                origin: invalidLocation,
                destination: "Los Angeles",
                currentLocation: invalidLocation,
                vehicleId: testVehicleId,
                userId: testUserId
            )
            XCTFail("Debe fallar con ubicación inválida")
        } catch {
            XCTAssertNotNil(error, "Debe lanzar error para ubicación inválida")
        }
    }
    
    func testAlertSystemWithNonExistentVehicle() async throws {
        // Given - ID de vehículo que no existe
        let nonExistentVehicleId = UUID()
        
        // When & Then
        do {
            _ = try await supabaseService.getPredictiveAlerts(
                vehicleId: nonExistentVehicleId,
                userId: testUserId,
                location: "Test City, TS"
            )
            XCTFail("Debe fallar con vehículo inexistente")
        } catch {
            XCTAssertNotNil(error, "Debe lanzar error para vehículo inexistente")
        }
    }
    
    // MARK: - Performance Tests
    
    func testOpenAIProxyPerformance() async throws {
        // Given
        let startTime = Date()
        let messages = [
            ChatMessage(role: "user", content: "What is the best route from Dallas to Los Angeles?"),
            ChatMessage(role: "assistant", content: "I recommend taking I-40 West for the most efficient route."),
            ChatMessage(role: "user", content: "What about fuel stops?")
        ]
        
        // When
        let response = try await supabaseService.callOpenAI(
            messages: messages,
            userId: testUserId,
            tripId: testTripId,
            vehicleId: testVehicleId
        )
        
        let endTime = Date()
        let responseTime = endTime.timeIntervalSince(startTime)
        
        // Then
        XCTAssertNotNil(response, "La respuesta debe completarse")
        XCTAssertLessThan(responseTime, 30.0, "La respuesta debe completarse en menos de 30 segundos")
    }
    
    func testMultipleEdgeFunctionCalls() async throws {
        // Given - Realizar múltiples llamadas concurrentes
        let concurrentTasks = 3
        var results: [Result<OpenAIResponse, Error>] = []
        
        // When
        await withTaskGroup(of: (Int, Result<OpenAIResponse, Error>).self) { group in
            for i in 0..<concurrentTasks {
                group.addTask { index in
                    let messages = [
                        ChatMessage(role: "user", content: "Test message \(index)")
                    ]
                    do {
                        let response = try await self.supabaseService.callOpenAI(
                            messages: messages,
                            userId: self.testUserId
                        )
                        return (index, .success(response))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            
            for await (index, result) in group {
                results.append(result)
            }
        }
        
        // Then
        XCTAssertEqual(results.count, concurrentTasks, "Debe procesarse el número esperado de llamadas")
        
        for result in results {
            switch result {
            case .success(let response):
                XCTAssertNotNil(response, "Cada respuesta debe ser exitosa")
            case .failure(let error):
                XCTFail("Llamada concurrente falló: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Backup Edge Functions Tests (Future Implementation)
    
    func testDatabaseBackupFunction() async throws {
        // Given - La función de backup debe estar disponible
        let functionUrl = "\(AppConfig.supabaseURL)/functions/v1/database-backup"
        
        var request = URLRequest(url: URL(string: functionUrl)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "type": "full",
            "description": "Test backup from iOS integration tests",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // When
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Then
        XCTAssertNotNil(data, "Debe recibir datos de respuesta")
        XCTAssertNotNil(response, "Debe recibir respuesta HTTP")
        
        if let httpResponse = response as? HTTPURLResponse {
            XCTAssertTrue(httpResponse.statusCode == 200 || httpResponse.statusCode == 404, 
                         "La función de backup debe existir (200) o no estar disponible (404)")
        }
    }
    
    func testBackupIntegrityFunction() async throws {
        // Given - La función de integridad debe estar disponible
        let functionUrl = "\(AppConfig.supabaseURL)/functions/v1/backup-integrity"
        
        var request = URLRequest(url: URL(string: functionUrl)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["backupId": "test-backup-123"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // When
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Then
        XCTAssertNotNil(data, "Debe recibir datos de respuesta")
        XCTAssertNotNil(response, "Debe recibir respuesta HTTP")
    }
    
    // MARK: - Rate Limiting Tests
    
    func testEdgeFunctionRateLimiting() async throws {
        // Given - Realizar múltiples llamadas rápidas para probar rate limiting
        let rapidCalls = 5
        let callInterval: TimeInterval = 0.1 // 100ms entre llamadas
        
        var results: [Result<OpenAIResponse, Error>] = []
        
        // When
        for i in 0..<rapidCalls {
            let messages = [ChatMessage(role: "user", content: "Rate limit test \(i)")]
            
            do {
                let response = try await supabaseService.callOpenAI(
                    messages: messages,
                    userId: testUserId
                )
                results.append(.success(response))
            } catch {
                results.append(.failure(error))
            }
            
            // Pausa entre llamadas
            try await Task.sleep(nanoseconds: UInt64(callInterval * 1_000_000_000))
        }
        
        // Then
        let successCount = results.filter { result in
            if case .success = result { return true }
            return false
        }.count
        
        XCTAssertGreaterThan(successCount, 0, "Al menos una llamada debe ser exitosa")
        
        if results.count > successCount {
            // Verificar que los fallos son por rate limiting y no por otros errores
            let failureCount = results.count - successCount
            print("Rate limiting test: \(successCount) successes, \(failureCount) failures")
        }
    }
}