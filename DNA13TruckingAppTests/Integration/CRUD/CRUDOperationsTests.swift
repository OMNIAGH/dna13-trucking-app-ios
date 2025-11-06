import XCTest
import Supabase
@testable import DNA13TruckingApp

/// Tests de integración para operaciones CRUD en tablas principales
final class CRUDOperationsTests: XCTestCase {
    
    var supabaseService: SupabaseService!
    var testUserId: UUID!
    var testVehicleId: UUID!
    var testTripId: UUID!
    var testTimeout: TimeInterval = 30
    
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
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo para cleanup
        try super.tearDownWithError()
    }
    
    // MARK: - User Profile CRUD Tests
    
    func testCreateUserProfile() async throws {
        // Given
        let profile = UserProfile(
            id: testUserId,
            email: "crud-test@test.com",
            fullName: "CRUD Test User",
            role: "driver",
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: nil
        )
        
        // When
        try await supabaseService.createUserProfile(profile)
        
        // Then
        let retrievedProfile = try await supabaseService.getUserProfile(userId: testUserId)
        XCTAssertNotNil(retrievedProfile, "El perfil debe crearse exitosamente")
        XCTAssertEqual(retrievedProfile?.email, profile.email, "Los datos deben coincidir")
    }
    
    func testReadUserProfile() async throws {
        // Given - Crear perfil primero
        let profile = UserProfile(
            id: testUserId,
            email: "read-test@test.com",
            fullName: "Read Test User",
            role: "manager",
            avatarURL: "https://example.com/avatar.jpg",
            createdAt: Date(),
            updatedAt: Date()
        )
        try await supabaseService.createUserProfile(profile)
        
        // When
        let retrievedProfile = try await supabaseService.getUserProfile(userId: testUserId)
        
        // Then
        XCTAssertNotNil(retrievedProfile, "El perfil debe existir")
        XCTAssertEqual(retrievedProfile?.id, profile.id, "Los IDs deben coincidir")
        XCTAssertEqual(retrievedProfile?.fullName, profile.fullName, "Los nombres deben coincidir")
        XCTAssertEqual(retrievedProfile?.role, profile.role, "Los roles deben coincidir")
    }
    
    func testUpdateUserProfile() async throws {
        // Given - Crear perfil primero
        let originalProfile = UserProfile(
            id: testUserId,
            email: "update-test@test.com",
            fullName: "Original Name",
            role: "driver",
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: nil
        )
        try await supabaseService.createUserProfile(originalProfile)
        
        // Simular actualización (en implementación real esto requeriría método update)
        // Por ahora verificamos que el perfil original se mantiene
        let updatedProfile = UserProfile(
            id: testUserId,
            email: "update-test@test.com",
            fullName: "Updated Name",
            role: "manager",
            avatarURL: "https://example.com/new-avatar.jpg",
            createdAt: Date(),
            updatedAt: Date()
        )
        try await supabaseService.createUserProfile(updatedProfile)
        
        // Then
        let retrievedProfile = try await supabaseService.getUserProfile(userId: testUserId)
        XCTAssertEqual(retrievedProfile?.fullName, "Updated Name", "El nombre debe actualizarse")
        XCTAssertEqual(retrievedProfile?.role, "manager", "El rol debe actualizarse")
    }
    
    // MARK: - Vehicle CRUD Tests
    
    func testCreateVehicle() async throws {
        // Given
        let vehicle = [
            "id": testVehicleId.uuidString,
            "unit_number": "TRUCK-001",
            "vin": "1HGBH41JXMN109186",
            "make": "Freightliner",
            "model": "Cascadia",
            "year": 2022,
            "status": "active",
            "current_mileage": 45000.0,
            "current_location": "Dallas, TX",
            "last_service_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        // When
        let response = try await supabaseService.supabase
            .from("vehicles")
            .insert(vehicle)
            .execute()
        
        // Then
        XCTAssertEqual(response.statusCode, 201, "El vehículo debe crearse exitosamente")
    }
    
    func testReadVehicles() async throws {
        // Given - Crear vehículos de prueba
        let vehicles = [
            [
                "id": UUID().uuidString,
                "unit_number": "TRUCK-002",
                "vin": "1HGBH41JXMN109187",
                "make": "Volvo",
                "model": "VNL 760",
                "year": 2023,
                "status": "active",
                "current_mileage": 25000.0,
                "current_location": "Los Angeles, CA"
            ],
            [
                "id": UUID().uuidString,
                "unit_number": "TRUCK-003",
                "vin": "1HGBH41JXMN109188",
                "make": "Kenworth",
                "model": "T680",
                "year": 2021,
                "status": "maintenance",
                "current_mileage": 75000.0,
                "current_location": "Phoenix, AZ"
            ]
        ]
        
        for vehicle in vehicles {
            _ = try await supabaseService.supabase
                .from("vehicles")
                .insert(vehicle)
                .execute()
        }
        
        // When
        let retrievedVehicles = try await supabaseService.getVehicles()
        
        // Then
        XCTAssertGreaterThanOrEqual(retrievedVehicles.count, 2, "Debe recuperar al menos los vehículos creados")
    }
    
    func testReadVehicleById() async throws {
        // Given - Crear vehículo específico
        let testVehicle = [
            "id": testVehicleId.uuidString,
            "unit_number": "TRUCK-SPECIFIC",
            "vin": "1HGBH41JXMN109189",
            "make": "Peterbilt",
            "model": "579",
            "year": 2023,
            "status": "active",
            "current_mileage": 15000.0,
            "current_location": "Houston, TX"
        ]
        
        _ = try await supabaseService.supabase
            .from("vehicles")
            .insert(testVehicle)
            .execute()
        
        // When
        let response = try await supabaseService.supabase
            .from("vehicles")
            .select("*")
            .eq("id", testVehicleId.uuidString)
            .maybeSingle()
        
        // Then
        XCTAssertNotNil(response.data.first, "El vehículo debe existir")
        if let vehicleData = response.data.first {
            let unitNumber = vehicleData["unit_number"] as? String
            XCTAssertEqual(unitNumber, "TRUCK-SPECIFIC", "Los datos del vehículo deben coincidir")
        }
    }
    
    // MARK: - Trip CRUD Tests
    
    func testCreateTrip() async throws {
        // Given
        let trip = [
            "id": testTripId.uuidString,
            "vehicle_id": testVehicleId.uuidString,
            "driver_user_id": testUserId.uuidString,
            "origin_city": "Dallas",
            "origin_state": "TX",
            "dest_city": "Los Angeles",
            "dest_state": "CA",
            "status": "planned",
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        // When
        let response = try await supabaseService.supabase
            .from("trips")
            .insert(trip)
            .execute()
        
        // Then
        XCTAssertEqual(response.statusCode, 201, "El viaje debe crearse exitosamente")
    }
    
    func testReadCurrentTrip() async throws {
        // Given - Crear viaje actual
        let currentTrip = [
            "id": testTripId.uuidString,
            "vehicle_id": testVehicleId.uuidString,
            "driver_user_id": testUserId.uuidString,
            "origin_city": "Phoenix",
            "origin_state": "AZ",
            "dest_city": "Denver",
            "dest_state": "CO",
            "status": "in_transit",
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        _ = try await supabaseService.supabase
            .from("trips")
            .insert(currentTrip)
            .execute()
        
        // When
        let retrievedTrip = try await supabaseService.getCurrentTrip(vehicleId: testVehicleId)
        
        // Then
        XCTAssertNotNil(retrievedTrip, "Debe existir un viaje actual")
        XCTAssertEqual(retrievedTrip?.originCity, "Phoenix", "Los datos del viaje deben coincidir")
        XCTAssertEqual(retrievedTrip?.status, "in_transit", "El estado debe ser correcto")
    }
    
    func testReadTripMetrics() async throws {
        // Given - Crear métricas de viaje
        let tripMetrics = [
            "id": UUID().uuidString,
            "trip_id": testTripId.uuidString,
            "total_miles": 1250.5,
            "drive_time_minutes": 720,
            "idle_time_minutes": 45,
            "fuel_volume_gal": 180.5,
            "fuel_cost": 540.75,
            "mpg": 6.93,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        _ = try await supabaseService.supabase
            .from("trip_metrics")
            .insert(tripMetrics)
            .execute()
        
        // When
        let retrievedMetrics = try await supabaseService.getTripMetrics(tripId: testTripId)
        
        // Then
        XCTAssertNotNil(retrievedMetrics, "Las métricas deben existir")
        XCTAssertEqual(retrievedMetrics?.totalMiles, 1250.5, "La distancia total debe coincidir")
        XCTAssertEqual(retrievedMetrics?.driveTimeMinutes, 720, "El tiempo de conducción debe coincidir")
    }
    
    // MARK: - Fuel Records CRUD Tests
    
    func testCreateFuelRecord() async throws {
        // Given
        let fuelRecord = [
            "id": UUID().uuidString,
            "vehicle_id": testVehicleId.uuidString,
            "trip_id": testTripId.uuidString,
            "date": ISO8601DateFormatter().string(from: Date()),
            "station": "Shell",
            "city": "Albuquerque",
            "state": "NM",
            "gallons": 150.0,
            "amount": 450.00,
            "unit_price": 3.00,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        // When
        let response = try await supabaseService.supabase
            .from("fuel_records")
            .insert(fuelRecord)
            .execute()
        
        // Then
        XCTAssertEqual(response.statusCode, 201, "El registro de combustible debe crearse exitosamente")
    }
    
    func testReadFuelRecords() async throws {
        // Given - Crear múltiples registros de combustible
        let fuelRecords = [
            [
                "id": UUID().uuidString,
                "vehicle_id": testVehicleId.uuidString,
                "trip_id": testTripId.uuidString,
                "date": ISO8601DateFormatter().string(from: Date()),
                "station": "BP",
                "city": "Oklahoma City",
                "state": "OK",
                "gallons": 120.0,
                "amount": 360.00,
                "unit_price": 3.00
            ],
            [
                "id": UUID().uuidString,
                "vehicle_id": testVehicleId.uuidString,
                "trip_id": testTripId.uuidString,
                "date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400)), // Ayer
                "station": "Exxon",
                "city": "Dallas",
                "state": "TX",
                "gallons": 100.0,
                "amount": 295.00,
                "unit_price": 2.95
            ]
        ]
        
        for record in fuelRecords {
            _ = try await supabaseService.supabase
                .from("fuel_records")
                .insert(record)
                .execute()
        }
        
        // When
        let retrievedRecords = try await supabaseService.getFuelRecords(vehicleId: testVehicleId, limit: 10)
        
        // Then
        XCTAssertGreaterThanOrEqual(retrievedRecords.count, 2, "Debe recuperar al menos los registros creados")
    }
    
    // MARK: - Notifications CRUD Tests
    
    func testCreateNotification() async throws {
        // Given
        let notification = [
            "id": UUID().uuidString,
            "user_id": testUserId.uuidString,
            "type": "fuel_alert",
            "payload": ["message": "Fuel level low", "priority": "high"],
            "status": "pending",
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        // When
        let response = try await supabaseService.supabase
            .from("notifications")
            .insert(notification)
            .execute()
        
        // Then
        XCTAssertEqual(response.statusCode, 201, "La notificación debe crearse exitosamente")
    }
    
    func testReadRecentNotifications() async throws {
        // Given - Crear múltiples notificaciones
        let notifications = [
            [
                "id": UUID().uuidString,
                "user_id": testUserId.uuidString,
                "type": "maintenance",
                "payload": ["message": "Maintenance due"],
                "status": "delivered",
                "created_at": ISO8601DateFormatter().string(from: Date())
            ],
            [
                "id": UUID().uuidString,
                "user_id": testUserId.uuidString,
                "type": "route_update",
                "payload": ["message": "Route changed"],
                "status": "pending",
                "created_at": ISO8601DateFormatter().string(from: Date())
            ]
        ]
        
        for notification in notifications {
            _ = try await supabaseService.supabase
                .from("notifications")
                .insert(notification)
                .execute()
        }
        
        // When
        let retrievedNotifications = try await supabaseService.getRecentAlerts(userId: testUserId, limit: 20)
        
        // Then
        XCTAssertGreaterThanOrEqual(retrievedNotifications.count, 2, "Debe recuperar al menos las notificaciones creadas")
    }
    
    // MARK: - Batch Operations Tests
    
    func testBatchCreateVehicles() async throws {
        // Given
        let vehicles = (1...3).map { i in
            [
                "id": UUID().uuidString,
                "unit_number": "BATCH-TRUCK-\(i)",
                "vin": "1HGBH41JXMN10919\(i)",
                "make": "Freightliner",
                "model": "Cascadia",
                "year": 2022 + i,
                "status": "active",
                "current_mileage": Double(10000 * i),
                "current_location": "City \(i), State"
            ]
        }
        
        // When
        for vehicle in vehicles {
            let response = try await supabaseService.supabase
                .from("vehicles")
                .insert(vehicle)
                .execute()
            XCTAssertEqual(response.statusCode, 201, "Cada vehículo del batch debe crearse exitosamente")
        }
    }
    
    func testBatchReadOperations() async throws {
        // When - Obtener datos de múltiples tablas
        let vehicles = try await supabaseService.getVehicles()
        let notifications = try await supabaseService.getRecentAlerts(userId: testUserId)
        let fuelRecords = try await supabaseService.getFuelRecords(vehicleId: testVehicleId)
        
        // Then
        XCTAssertNotNil(vehicles, "La consulta de vehículos debe completarse")
        XCTAssertNotNil(notifications, "La consulta de notificaciones debe completarse")
        XCTAssertNotNil(fuelRecords, "La consulta de registros de combustible debe completarse")
    }
    
    // MARK: - Error Handling Tests
    
    func testCreateDuplicateVehicle() async throws {
        // Given - Crear vehículo
        let vehicle = [
            "id": testVehicleId.uuidString,
            "unit_number": "DUPLICATE-TRUCK",
            "vin": "1HGBH41JXMN109199",
            "make": "Volvo",
            "model": "VNL",
            "year": 2023,
            "status": "active",
            "current_mileage": 0.0
        ]
        
        _ = try await supabaseService.supabase
            .from("vehicles")
            .insert(vehicle)
            .execute()
        
        // When & Then - Intentar crear vehículo duplicado
        do {
            _ = try await supabaseService.supabase
                .from("vehicles")
                .insert(vehicle)
                .execute()
            XCTFail("Debe fallar al intentar crear vehículo duplicado")
        } catch {
            XCTAssertNotNil(error, "Debe lanzar error para vehículo duplicado")
        }
    }
    
    func testReadNonExistentRecord() async throws {
        // Given - ID de registro que no existe
        let nonExistentId = UUID()
        
        // When
        let response = try await supabaseService.supabase
            .from("vehicles")
            .select("*")
            .eq("id", nonExistentId.uuidString)
            .maybeSingle()
        
        // Then
        XCTAssertNil(response.data.first, "No debe existir registro con ID inexistente")
    }
    
    func testUpdateNonExistentRecord() async throws {
        // Given - ID de registro que no existe
        let nonExistentId = UUID()
        let updateData = ["status": "updated"]
        
        // When & Then
        do {
            _ = try await supabaseService.supabase
                .from("vehicles")
                .update(updateData)
                .eq("id", nonExistentId.uuidString)
                .execute()
            XCTFail("Debe fallar al intentar actualizar registro inexistente")
        } catch {
            XCTAssertNotNil(error, "Debe lanzar error para registro inexistente")
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataConsistencyAcrossTables() async throws {
        // Given - Crear vehículo, viaje y registros relacionados
        let vehicle = [
            "id": testVehicleId.uuidString,
            "unit_number": "CONSISTENCY-TRUCK",
            "vin": "1HGBH41JXMN109200",
            "make": "Kenworth",
            "model": "T680",
            "year": 2023,
            "status": "active",
            "current_mileage": 5000.0
        ]
        
        _ = try await supabaseService.supabase
            .from("vehicles")
            .insert(vehicle)
            .execute()
        
        let trip = [
            "id": testTripId.uuidString,
            "vehicle_id": testVehicleId.uuidString,
            "driver_user_id": testUserId.uuidString,
            "origin_city": "Consistency City",
            "origin_state": "CS",
            "dest_city": "Test City",
            "dest_state": "TS",
            "status": "planned"
        ]
        
        _ = try await supabaseService.supabase
            .from("trips")
            .insert(trip)
            .execute()
        
        // When - Verificar que todos los datos relacionados existen
        let vehicles = try await supabaseService.getVehicles()
        let currentTrip = try await supabaseService.getCurrentTrip(vehicleId: testVehicleId)
        let fuelRecords = try await supabaseService.getFuelRecords(vehicleId: testVehicleId)
        
        // Then
        XCTAssertTrue(vehicles.contains { $0.unitNumber == "CONSISTENCY-TRUCK" }, "El vehículo debe existir")
        XCTAssertNotNil(currentTrip, "El viaje actual debe existir")
        XCTAssertEqual(currentTrip?.vehicleId, testVehicleId, "La relación vehículo-viaje debe ser correcta")
    }
    
    // MARK: - Performance Tests
    
    func testLargeDataQuery() async throws {
        // Given - Insertar múltiples registros para prueba de rendimiento
        let recordCount = 100
        let batchSize = 10
        
        for batchStart in stride(from: 0, to: recordCount, by: batchSize) {
            let batch = (batchStart..<min(batchStart + batchSize, recordCount)).map { i in
                [
                    "id": UUID().uuidString,
                    "vehicle_id": testVehicleId.uuidString,
                    "trip_id": testTripId.uuidString,
                    "date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-Double(i * 3600))),
                    "station": "Station \(i)",
                    "city": "City \(i)",
                    "state": "ST",
                    "gallons": Double(100 + i),
                    "amount": Double(300 + i * 2),
                    "unit_price": 3.0 + Double(i) * 0.01
                ]
            }
            
            for record in batch {
                _ = try await supabaseService.supabase
                    .from("fuel_records")
                    .insert(record)
                    .execute()
            }
        }
        
        // When - Realizar consulta de gran volumen
        let startTime = Date()
        let fuelRecords = try await supabaseService.getFuelRecords(vehicleId: testVehicleId, limit: 50)
        let endTime = Date()
        
        // Then
        XCTAssertGreaterThanOrEqual(fuelRecords.count, 0, "La consulta debe completarse")
        let queryTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(queryTime, 10.0, "La consulta debe completarse en menos de 10 segundos")
    }
}