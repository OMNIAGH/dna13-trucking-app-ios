//
//  MockSupabaseService.swift
//  DNA13TruckingAppTests
//
//  Mock del SupabaseService para testing
//

import Foundation
import Combine
@testable import DNA13TruckingApp

// MARK: - Mock SupabaseService
class MockSupabaseService: ObservableObject {
    @Published var isConnected = true
    @Published var currentUser: User?
    @Published var connectionStatus = "Connected"
    
    private var mockData: [String: Any] = [:]
    private var shouldThrowError = false
    private var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: nil)
    
    // MARK: - Configuration Methods
    func simulateConnectionFailure() {
        isConnected = false
        connectionStatus = "Connection Failed"
        shouldThrowError = true
    }
    
    func simulateNetworkError() {
        shouldThrowError = true
        errorToThrow = NSError(domain: "NetworkError", code: 2, userInfo: nil)
    }
    
    func setMockUser(_ user: User) {
        currentUser = user
    }
    
    func addMockData<T: Codable>(for key: String, data: T) {
        mockData[key] = data
    }
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String, fullName: String, role: UserRole = .driver) async throws -> User {
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Mock user creation
        let mockUser = User(
            id: UUID(),
            email: email,
            fullName: fullName,
            role: role.rawValue,
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        currentUser = mockUser
        return mockUser
    }
    
    func signIn(email: String, password: String) async throws -> User {
        if shouldThrowError {
            throw errorToThrow
        }
        
        let mockUser = User(
            id: UUID(),
            email: email,
            fullName: "Test User",
            role: "driver",
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        currentUser = mockUser
        return mockUser
    }
    
    func signOut() async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        currentUser = nil
    }
    
    func getCurrentUser() async -> User? {
        return currentUser
    }
    
    // MARK: - Database Operations
    func createUserProfile(_ profile: UserProfile) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        // Mock profile creation
    }
    
    func getUserProfile(userId: UUID) async throws -> UserProfile? {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let profile = mockData["userProfile"] as? UserProfile {
            return profile
        }
        
        return UserProfile(
            id: userId,
            email: "test@example.com",
            fullName: "Test User",
            role: "driver",
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func getVehicles() async throws -> [Vehicle] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let vehicles = mockData["vehicles"] as? [Vehicle] {
            return vehicles
        }
        
        return [
            Vehicle(
                id: UUID(),
                unitNumber: "TRK-001",
                vin: "1HGBH41JXMN109186",
                make: "Freightliner",
                model: "Cascadia",
                year: 2020,
                status: "active",
                currentMileage: 150000,
                currentLocation: "Phoenix, AZ",
                lastServiceAt: Date().addingTimeInterval(-30 * 24 * 3600)
            )
        ]
    }
    
    func getCurrentTrip(vehicleId: UUID) async throws -> Trip? {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let trip = mockData["currentTrip"] as? Trip {
            return trip
        }
        
        return Trip(
            id: UUID(),
            vehicleId: vehicleId,
            driverUserId: currentUser?.id,
            externalRef: "TRIP-001",
            plannedStartAt: Date(),
            actualStartAt: Date(),
            endAt: nil,
            originAddress: "123 Industrial Ave",
            originCity: "Phoenix",
            originState: "AZ",
            destAddress: "456 Commerce Blvd",
            destCity: "Los Angeles",
            destState: "CA",
            distanceMiles: 357.5,
            status: "in_transit",
            createdAt: Date().addingTimeInterval(-2 * 3600),
            updatedAt: Date()
        )
    }
    
    func getTripMetrics(tripId: UUID) async throws -> TripMetrics? {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let metrics = mockData["tripMetrics"] as? TripMetrics {
            return metrics
        }
        
        return TripMetrics(
            id: UUID(),
            tripId: tripId,
            totalMiles: 150.0,
            driveTimeMinutes: 180,
            idleTimeMinutes: 30,
            fuelVolumeGal: 25.5,
            fuelCost: 75.30,
            mpg: 15.2,
            createdAt: Date()
        )
    }
    
    func getFuelRecords(vehicleId: UUID, limit: Int = 10) async throws -> [FuelRecord] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let records = mockData["fuelRecords"] as? [FuelRecord] {
            return Array(records.prefix(limit))
        }
        
        return [
            FuelRecord(
                id: UUID(),
                vehicleId: vehicleId,
                tripId: nil,
                date: Date(),
                station: "Shell",
                city: "Phoenix",
                state: "AZ",
                gallons: 25.5,
                amount: 75.30,
                unitPrice: 2.95
            )
        ]
    }
    
    func getRecentAlerts(userId: UUID, limit: Int = 20) async throws -> [Notification] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let alerts = mockData["recentAlerts"] as? [Notification] {
            return Array(alerts.prefix(limit))
        }
        
        return [
            Notification(
                id: UUID(),
                userId: userId,
                type: "maintenance",
                payload: ["message": "Maintenance required"],
                status: "unread",
                createdAt: Date(),
                deliveredAt: nil
            )
        ]
    }
    
    // MARK: - Edge Functions
    func callOpenAI(messages: [ChatMessage], userId: UUID, tripId: UUID? = nil, vehicleId: UUID? = nil) async throws -> OpenAIResponse {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return OpenAIResponse(
            data: OpenAIData(
                message: "Esta es una respuesta simulada de la IA para testing.",
                usage: ["tokens": 100],
                model: "gpt-3.5-turbo"
            )
        )
    }
    
    func processDocumentOCR(ocrText: String, documentType: DocumentType, documentId: UUID?, userId: UUID) async throws -> OCRResponse {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return OCRResponse(
            data: OCRData(
                processedData: ["amount": "1,500.00", "date": "2024-01-15"],
                confidence: 0.95,
                documentType: documentType.rawValue,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        )
    }
    
    func searchLoads(origin: String?, destination: String?, currentLocation: String, vehicleId: UUID, userId: UUID, maxDistance: Int = 500) async throws -> LoadSearchResponse {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return LoadSearchResponse(
            data: LoadSearchData(
                loads: [
                    Load(
                        id: "LOAD-001",
                        origin: "Phoenix, AZ",
                        destination: "Los Angeles, CA",
                        distance: 357,
                        rate: 2.5,
                        total: 892.50,
                        commodity: "General Freight",
                        weight: 40000,
                        pieces: 1,
                        pickupDate: "2024-01-20",
                        deliveryDate: "2024-01-21",
                        source: "DAT",
                        broker: "ABC Logistics",
                        contact: "John Smith",
                        notes: "Handle with care",
                        aiRank: 1,
                        aiReasoning: "Best match based on location and timing"
                    )
                ],
                proactiveSuggestions: [],
                searchCriteria: [:],
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        )
    }
    
    func getPredictiveAlerts(vehicleId: UUID, userId: UUID, location: String) async throws -> AlertSystemResponse {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return AlertSystemResponse(
            data: AlertData(
                alerts: [
                    PredictiveAlert(
                        type: "maintenance",
                        priority: "high",
                        title: "Mantenimiento requerido",
                        message: "Su vehículo necesita mantenimiento en 500 millas",
                        action: "schedule_maintenance",
                        location: location,
                        daysRemaining: 5
                    )
                ],
                totalAlerts: 1,
                highPriority: 1,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        )
    }
    
    // MARK: - Storage Operations
    func uploadDocument(file: Data, fileName: String, documentType: DocumentType) async throws -> String {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return "https://mock-storage.com/documents/\(documentType.rawValue)/\(fileName)"
    }
    
    func uploadAvatar(image: Data, userId: UUID) async throws -> String {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return "https://mock-storage.com/avatars/avatar-\(userId.uuidString).jpg"
    }
}

// MARK: - Mock Models
extension MockSupabaseService {
    static func createMockUser(id: UUID = UUID(), email: String = "test@example.com") -> User {
        return User(
            id: id,
            email: email,
            fullName: "Test User",
            role: "driver",
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static func createMockVehicle(id: UUID = UUID()) -> Vehicle {
        return Vehicle(
            id: id,
            unitNumber: "TRK-001",
            vin: "1HGBH41JXMN109186",
            make: "Freightliner",
            model: "Cascadia",
            year: 2020,
            status: "active",
            currentMileage: 150000,
            currentLocation: "Phoenix, AZ",
            lastServiceAt: Date().addingTimeInterval(-30 * 24 * 3600)
        )
    }
    
    static func createMockTrip(vehicleId: UUID, driverUserId: UUID) -> Trip {
        return Trip(
            id: UUID(),
            vehicleId: vehicleId,
            driverUserId: driverUserId,
            externalRef: "TRIP-001",
            plannedStartAt: Date(),
            actualStartAt: Date(),
            endAt: nil,
            originAddress: "123 Industrial Ave",
            originCity: "Phoenix",
            originState: "AZ",
            destAddress: "456 Commerce Blvd",
            destCity: "Los Angeles",
            destState: "CA",
            distanceMiles: 357.5,
            status: "in_transit",
            createdAt: Date().addingTimeInterval(-2 * 3600),
            updatedAt: Date()
        )
    }
    
    static func createMockLoad() -> Load {
        return Load(
            id: "LOAD-001",
            origin: "Phoenix, AZ",
            destination: "Los Angeles, CA",
            distance: 357,
            rate: 2.5,
            total: 892.50,
            commodity: "General Freight",
            weight: 40000,
            pieces: 1,
            pickupDate: "2024-01-20",
            deliveryDate: "2024-01-21",
            source: "DAT",
            broker: "ABC Logistics",
            contact: "John Smith",
            notes: "Handle with care",
            aiRank: 1,
            aiReasoning: "Best match based on location and timing"
        )
    }
    
    static func createMockNotification(userId: UUID) -> Notification {
        return Notification(
            id: UUID(),
            userId: userId,
            type: "maintenance",
            payload: ["message": "Maintenance required"],
            status: "unread",
            createdAt: Date(),
            deliveredAt: nil
        )
    }
}

// MARK: - Shared Instance
extension SupabaseService {
    static let mock: MockSupabaseService = MockSupabaseService()
}