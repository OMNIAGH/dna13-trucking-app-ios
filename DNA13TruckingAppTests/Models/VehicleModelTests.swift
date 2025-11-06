//
//  VehicleModelTests.swift
//  DNA13TruckingAppTests
//
//  Tests unitarios para el modelo Vehicle
//

import XCTest
import Foundation
@testable import DNA13TruckingApp

// MARK: - Vehicle Model Tests
final class VehicleModelTests: XCTestCase {
    
    // MARK: - Test Setup
    override func setUpWithError() throws {
        // Setup antes de cada test
    }
    
    override func tearDownWithError() throws {
        // Cleanup después de cada test
    }
    
    // MARK: - Codable Conformance Tests
    
    func testVehicleEncoding() throws {
        // Given
        let vehicle = Vehicle(
            id: UUID(),
            unitNumber: "TEST001",
            vin: "1HGBH41JXMN109186",
            make: "FREIGHTLINER",
            model: "Cascadia",
            year: 2022,
            status: .active,
            currentMileage: 125000.5,
            currentLocation: "Atlanta, GA",
            lastServiceAt: Date(timeIntervalSince1970: 1640995200),
            createdAt: Date(timeIntervalSince1970: 1640995200),
            updatedAt: Date(timeIntervalSince1970: 1640995200)
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(vehicle)
        
        // Then
        XCTAssertFalse(data.isEmpty, "Los datos codificados no deberían estar vacíos")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decodedVehicle = try decoder.decode(Vehicle.self, from: data)
        
        XCTAssertEqual(vehicle.id, decodedVehicle.id, "Los IDs deberían coincidir")
        XCTAssertEqual(vehicle.unitNumber, decodedVehicle.unitNumber, "Los números de unidad deberían coincidir")
        XCTAssertEqual(vehicle.vin, decodedVehicle.vin, "Los VINs deberían coincidir")
        XCTAssertEqual(vehicle.make, decodedVehicle.make, "Las marcas deberían coincidir")
        XCTAssertEqual(vehicle.year, decodedVehicle.year, "Los años deberían coincidir")
    }
    
    func testVehicleDecoding() throws {
        // Given
        let jsonString = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "unitNumber": "305",
            "vin": "1XKYAP9X2EJ386743",
            "make": "KENWORTH",
            "model": "T680",
            "year": 2020,
            "status": "active",
            "currentMileage": 150000.0,
            "currentLocation": "Nashville, TN",
            "lastServiceAt": 1640995200,
            "createdAt": 1640995200,
            "updatedAt": 1640995200
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let vehicle = try decoder.decode(Vehicle.self, from: jsonData)
        
        // Then
        XCTAssertEqual(vehicle.unitNumber, "305", "El número de unidad debería decodificarse correctamente")
        XCTAssertEqual(vehicle.vin, "1XKYAP9X2EJ386743", "El VIN debería decodificarse correctamente")
        XCTAssertEqual(vehicle.make, "KENWORTH", "La marca debería decodificarse correctamente")
        XCTAssertEqual(vehicle.year, 2020, "El año debería decodificarse correctamente")
        XCTAssertEqual(vehicle.status, .active, "El estado debería decodificarse correctamente")
    }
    
    func testVehicleCompleteJSONRoundTrip() throws {
        // Given
        let originalVehicle = Vehicle(
            id: UUID(),
            unitNumber: "UNIT999",
            vin: "4V4NC9TG6DN563822",
            make: "VOLVO",
            model: "VNL 760",
            year: 2021,
            status: .inMaintenance,
            currentMileage: 89000.0,
            currentLocation: "Dallas, TX",
            lastServiceAt: Date(timeIntervalSince1970: 1640995200),
            createdAt: Date(timeIntervalSince1970: 1640995200),
            updatedAt: Date(timeIntervalSince1970: 1640995200)
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(originalVehicle)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decodedVehicle = try decoder.decode(Vehicle.self, from: jsonData)
        
        // Then
        XCTAssertEqual(originalVehicle.id, decodedVehicle.id)
        XCTAssertEqual(originalVehicle.unitNumber, decodedVehicle.unitNumber)
        XCTAssertEqual(originalVehicle.vin, decodedVehicle.vin)
        XCTAssertEqual(originalVehicle.make, decodedVehicle.make)
        XCTAssertEqual(originalVehicle.model, decodedVehicle.model)
        XCTAssertEqual(originalVehicle.year, decodedVehicle.year)
        XCTAssertEqual(originalVehicle.status, decodedVehicle.status)
        XCTAssertEqual(originalVehicle.currentMileage, decodedVehicle.currentMileage)
        XCTAssertEqual(originalVehicle.currentLocation, decodedVehicle.currentLocation)
        
        // Verificar que el JSON generado es válido
        XCTAssertFalse(jsonString.isEmpty, "El JSON generado no debería estar vacío")
        XCTAssertTrue(jsonString.contains("\"unitNumber\""), "El JSON debería contener unitNumber")
    }
    
    // MARK: - Vehicle Status Tests
    
    func testVehicleStatusAllCases() {
        // Given
        let allStatuses = VehicleStatus.allCases
        
        // Then
        XCTAssertEqual(allStatuses.count, 5, "Debería haber exactamente 5 estados de vehículo")
        XCTAssertTrue(allStatuses.contains(.active), "Debería incluir el estado 'active'")
        XCTAssertTrue(allStatuses.contains(.inMaintenance), "Debería incluir el estado 'in_maintenance'")
        XCTAssertTrue(allStatuses.contains(.outOfService), "Debería incluir el estado 'out_of_service'")
        XCTAssertTrue(allStatuses.contains(.inTransit), "Debería incluir el estado 'in_transit'")
        XCTAssertTrue(allStatuses.contains(.atYard), "Debería incluir el estado 'at_yard'")
    }
    
    func testVehicleStatusDisplayNames() {
        // Then
        XCTAssertEqual(VehicleStatus.active.displayName, "Activo")
        XCTAssertEqual(VehicleStatus.inMaintenance.displayName, "En Mantenimiento")
        XCTAssertEqual(VehicleStatus.outOfService.displayName, "Fuera de Servicio")
        XCTAssertEqual(VehicleStatus.inTransit.displayName, "En Tránsito")
        XCTAssertEqual(VehicleStatus.atYard.displayName, "En Patio")
    }
    
    func testVehicleStatusIsOperational() {
        // Given
        let activeVehicle = Vehicle(
            id: UUID(),
            unitNumber: "001",
            vin: "1HGBH41JXMN109186",
            make: "FREIGHTLINER",
            model: nil,
            year: 2020,
            status: .active,
            currentMileage: 0,
            currentLocation: nil,
            lastServiceAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let inTransitVehicle = Vehicle(
            id: UUID(),
            unitNumber: "002",
            vin: "1HGBH41JXMN109187",
            make: "KENWORTH",
            model: nil,
            year: 2020,
            status: .inTransit,
            currentMileage: 0,
            currentLocation: nil,
            lastServiceAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let maintenanceVehicle = Vehicle(
            id: UUID(),
            unitNumber: "003",
            vin: "1HGBH41JXMN109188",
            make: "VOLVO",
            model: nil,
            year: 2020,
            status: .inMaintenance,
            currentMileage: 0,
            currentLocation: nil,
            lastServiceAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertTrue(activeVehicle.status.isOperational, "Los vehículos activos deberían ser operativos")
        XCTAssertTrue(inTransitVehicle.status.isOperational, "Los vehículos en tránsito deberían ser operativos")
        XCTAssertFalse(maintenanceVehicle.status.isOperational, "Los vehículos en mantenimiento no deberían ser operativos")
    }
    
    // MARK: - Static Vehicle Examples Tests
    
    func testVehicleUnit115A() {
        // When
        let vehicle = Vehicle.unit115A
        
        // Then
        XCTAssertEqual(vehicle.unitNumber, "115A", "El número de unidad debería ser 115A")
        XCTAssertEqual(vehicle.vin, "4V4NC9TG6DN563822", "El VIN debería coincidir")
        XCTAssertEqual(vehicle.make, "VOLVO", "La marca debería ser VOLVO")
        XCTAssertEqual(vehicle.year, 2013, "El año debería ser 2013")
        XCTAssertEqual(vehicle.status, .active, "El estado debería ser activo")
    }
    
    func testVehicleUnit305() {
        // When
        let vehicle = Vehicle.unit305
        
        // Then
        XCTAssertEqual(vehicle.unitNumber, "305", "El número de unidad debería ser 305")
        XCTAssertEqual(vehicle.vin, "1XKYAP9X2EJ386743", "El VIN debería coincidir")
        XCTAssertEqual(vehicle.make, "KENWORTH", "La marca debería ser KENWORTH")
        XCTAssertEqual(vehicle.year, 2014, "El año debería ser 2014")
        XCTAssertEqual(vehicle.status, .active, "El estado debería ser activo")
    }
    
    // MARK: - Validation Tests
    
    func testVehicleInitializationWithValidData() {
        // When
        let vehicle = Vehicle(
            id: UUID(),
            unitNumber: "VALID001",
            vin: "1HGBH41JXMN109189",
            make: "PETERBILT",
            model: "579",
            year: 2023,
            status: .active,
            currentMileage: 50000.0,
            currentLocation: "Phoenix, AZ",
            lastServiceAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertNotNil(vehicle.id, "El ID no debería ser nil")
        XCTAssertEqual(vehicle.unitNumber, "VALID001", "El número de unidad debería ser válido")
        XCTAssertEqual(vehicle.vin, "1HGBH41JXMN109189", "El VIN debería ser válido")
        XCTAssertEqual(vehicle.make, "PETERBILT", "La marca debería ser válida")
    }
    
    func testVehicleInitializationWithMinimalData() {
        // When
        let vehicle = Vehicle(
            id: UUID(),
            unitNumber: "MINIMAL",
            vin: "1HGBH41JXMN109190",
            make: "INTERNATIONAL",
            model: nil,
            year: 2019,
            status: .outOfService,
            currentMileage: 200000.0,
            currentLocation: nil,
            lastServiceAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertNotNil(vehicle.id)
        XCTAssertEqual(vehicle.unitNumber, "MINIMAL")
        XCTAssertEqual(vehicle.vin, "1HGBH41JXMN109190")
        XCTAssertEqual(vehicle.make, "INTERNATIONAL")
        XCTAssertNil(vehicle.model)
        XCTAssertNil(vehicle.currentLocation)
        XCTAssertNil(vehicle.lastServiceAt)
    }
    
    func testVehicleWithDifferentYears() {
        // Given
        let years = [2010, 2015, 2020, 2023, 2024]
        
        for year in years {
            // When
            let vehicle = Vehicle(
                id: UUID(),
                unitNumber: "YEAR\(year)",
                vin: "1HGBH41JXMN10919\(year % 10)",
                make: "FREIGHTLINER",
                model: nil,
                year: year,
                status: .active,
                currentMileage: 0,
                currentLocation: nil,
                lastServiceAt: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Then
            XCTAssertEqual(vehicle.year, year, "El año \(year) debería asignarse correctamente")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testVehicleWithVeryLongUnitNumber() {
        // Given
        let longUnitNumber = String(repeating: "X", count: 50)
        
        // When
        let vehicle = Vehicle(
            id: UUID(),
            unitNumber: longUnitNumber,
            vin: "1HGBH41JXMN109191",
            make: "KENWORTH",
            model: nil,
            year: 2020,
            status: .active,
            currentMileage: 0,
            currentLocation: nil,
            lastServiceAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertEqual(vehicle.unitNumber.count, 50, "Debería permitir números de unidad muy largos")
    }
    
    func testVehicleWithAllStatusValues() {
        // Given
        let statuses: [VehicleStatus] = [.active, .inMaintenance, .outOfService, .inTransit, .atYard]
        
        // Then
        for status in statuses {
            let vehicle = Vehicle(
                id: UUID(),
                unitNumber: "STATUS_\(status.rawValue)",
                vin: "1HGBH41JXMN10919\(status.hashValue % 10)",
                make: "VOLVO",
                model: nil,
                year: 2020,
                status: status,
                currentMileage: 0,
                currentLocation: nil,
                lastServiceAt: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            XCTAssertEqual(vehicle.status, status, "El estado \(status.rawValue) debería asignarse correctamente")
        }
    }
    
    func testVehicleWithZeroMileage() {
        // When
        let vehicle = Vehicle(
            id: UUID(),
            unitNumber: "ZERO_MILE",
            vin: "1HGBH41JXMN109192",
            make: "PETERBILT",
            model: nil,
            year: 2023,
            status: .active,
            currentMileage: 0.0,
            currentLocation: nil,
            lastServiceAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertEqual(vehicle.currentMileage, 0.0, "Debería permitir kilometraje de cero")
    }
    
    func testVehicleWithVeryHighMileage() {
        // When
        let vehicle = Vehicle(
            id: UUID(),
            unitNumber: "HIGH_MILE",
            vin: "1HGBH41JXMN109193",
            make: "FREIGHTLINER",
            model: nil,
            year: 2010,
            status: .active,
            currentMileage: 999999.99,
            currentLocation: nil,
            lastServiceAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertEqual(vehicle.currentMileage, 999999.99, "Debería permitir kilometraje muy alto")
    }
    
    // MARK: - JSON Edge Cases Tests
    
    func testVehicleDecodingWithMissingOptionalFields() throws {
        // Given
        let jsonString = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "unitNumber": "MINIMAL",
            "vin": "1HGBH41JXMN109194",
            "make": "KENWORTH",
            "year": 2020,
            "status": "active",
            "currentMileage": 0.0,
            "createdAt": 1640995200,
            "updatedAt": 1640995200
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let vehicle = try decoder.decode(Vehicle.self, from: jsonData)
        
        // Then
        XCTAssertEqual(vehicle.unitNumber, "MINIMAL")
        XCTAssertEqual(vehicle.vin, "1HGBH41JXMN109194")
        XCTAssertEqual(vehicle.make, "KENWORTH")
        XCTAssertNil(vehicle.model, "El campo model debería ser nil")
        XCTAssertNil(vehicle.currentLocation, "El campo currentLocation debería ser nil")
        XCTAssertNil(vehicle.lastServiceAt, "El campo lastServiceAt debería ser nil")
    }
    
    func testVehicleDecodingWithInvalidStatus() {
        // Given
        let jsonString = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "unitNumber": "TEST",
            "vin": "1HGBH41JXMN109195",
            "make": "VOLVO",
            "year": 2020,
            "status": "invalid_status",
            "currentMileage": 0.0,
            "createdAt": 1640995200,
            "updatedAt": 1640995200
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode(Vehicle.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError, "Debería lanzar un DecodingError")
        }
    }
    
    func testVehicleDecodingWithInvalidYear() {
        // Given
        let jsonString = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "unitNumber": "TEST",
            "vin": "1HGBH41JXMN109196",
            "make": "PETERBILT",
            "year": "invalid_year",
            "status": "active",
            "currentMileage": 0.0,
            "createdAt": 1640995200,
            "updatedAt": 1640995200
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode(Vehicle.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError, "Debería lanzar un DecodingError para year inválido")
        }
    }
    
    // MARK: - Performance Tests
    
    func testVehicleEncodingPerformance() throws {
        // Given
        let vehicle = Vehicle(
            id: UUID(),
            unitNumber: "PERF001",
            vin: "1HGBH41JXMN109197",
            make: "FREIGHTLINER",
            model: "Cascadia",
            year: 2022,
            status: .active,
            currentMileage: 100000.0,
            currentLocation: "Performance Test Location",
            lastServiceAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When - Measure
        self.measure {
            for _ in 0..<1000 {
                _ = try? JSONEncoder().encode(vehicle)
            }
        }
    }
    
    func testVehicleDecodingPerformance() throws {
        // Given
        let jsonString = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "unitNumber": "PERF001",
            "vin": "1HGBH41JXMN109197",
            "make": "FREIGHTLINER",
            "model": "Cascadia",
            "year": 2022,
            "status": "active",
            "currentMileage": 100000.0,
            "currentLocation": "Performance Test Location",
            "lastServiceAt": 1640995200,
            "createdAt": 1640995200,
            "updatedAt": 1640995200
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When - Measure
        self.measure {
            for _ in 0..<1000 {
                _ = try? JSONDecoder().decode(Vehicle.self, from: jsonData)
            }
        }
    }
}

// MARK: - VehicleDocument Model Tests
final class VehicleDocumentModelTests: XCTestCase {
    
    func testVehicleDocumentEncodingDecoding() throws {
        // Given
        let vehicleDoc = VehicleDocument(
            id: UUID(),
            vehicleId: UUID(),
            documentId: UUID(),
            relationshipType: .registration,
            createdAt: Date()
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(vehicleDoc)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(VehicleDocument.self, from: data)
        
        // Then
        XCTAssertEqual(vehicleDoc.id, decoded.id)
        XCTAssertEqual(vehicleDoc.vehicleId, decoded.vehicleId)
        XCTAssertEqual(vehicleDoc.documentId, decoded.documentId)
        XCTAssertEqual(vehicleDoc.relationshipType, decoded.relationshipType)
    }
    
    func testVehicleDocumentTypeAllCases() {
        // Then
        let allTypes = VehicleDocument.VehicleDocumentType.allCases
        XCTAssertEqual(allTypes.count, 6)
        XCTAssertTrue(allTypes.contains(.registration))
        XCTAssertTrue(allTypes.contains(.insurance))
        XCTAssertTrue(allTypes.contains(.inspection))
        XCTAssertTrue(allTypes.contains(.leaseContract))
        XCTAssertTrue(allTypes.contains(.permits))
        XCTAssertTrue(allTypes.contains(.warranties))
    }
}

// MARK: - MaintenanceRecord Model Tests
final class MaintenanceRecordModelTests: XCTestCase {
    
    func testMaintenanceRecordEncodingDecoding() throws {
        // Given
        let part = MaintenancePart(
            name: "Filtro de Aceite",
            quantity: 1,
            unitCost: 25.99,
            totalCost: 25.99,
            partNumber: "FO-12345"
        )
        
        let maintenance = MaintenanceRecord(
            id: UUID(),
            vehicleId: UUID(),
            date: Date(),
            odometer: 75000.0,
            description: "Cambio de aceite y filtro",
            cost: 125.99,
            vendor: "Quick Lube Express",
            parts: [part],
            createdBy: UUID(),
            createdAt: Date()
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(maintenance)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MaintenanceRecord.self, from: data)
        
        // Then
        XCTAssertEqual(maintenance.id, decoded.id)
        XCTAssertEqual(maintenance.description, decoded.description)
        XCTAssertEqual(maintenance.cost, decoded.cost)
        XCTAssertEqual(maintenance.parts.count, decoded.parts.count)
    }
    
    func testMaintenanceRecordIsWarrantyWork() {
        // Given
        let warrantyMaintenance = MaintenanceRecord(
            id: UUID(),
            vehicleId: UUID(),
            date: Date(),
            odometer: 50000.0,
            description: "Reparación bajo garantía",
            cost: 0.0,
            vendor: "Warranty Service Center",
            parts: [],
            createdBy: UUID(),
            createdAt: Date()
        )
        
        let regularMaintenance = MaintenanceRecord(
            id: UUID(),
            vehicleId: UUID(),
            date: Date(),
            odometer: 50000.0,
            description: "Mantenimiento regular",
            cost: 150.0,
            vendor: "Local Garage",
            parts: [],
            createdBy: UUID(),
            createdAt: Date()
        )
        
        // Then
        XCTAssertTrue(warrantyMaintenance.isWarrantyWork, "Debería identificar trabajo de garantía")
        XCTAssertFalse(regularMaintenance.isWarrantyWork, "No debería identificar trabajo regular como garantía")
    }
}

// MARK: - Assignment Model Tests
final class AssignmentModelTests: XCTestCase {
    
    func testAssignmentEncodingDecoding() throws {
        // Given
        let now = Date()
        let futureDate = now.addingTimeInterval(86400) // +1 day
        
        let assignment = Assignment(
            id: UUID(),
            vehicleId: UUID(),
            contractId: UUID(),
            driverUserId: UUID(),
            startDate: now,
            endDate: futureDate,
            status: .active,
            createdAt: Date()
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(assignment)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Assignment.self, from: data)
        
        // Then
        XCTAssertEqual(assignment.id, decoded.id)
        XCTAssertEqual(assignment.vehicleId, decoded.vehicleId)
        XCTAssertEqual(assignment.status, decoded.status)
    }
    
    func testAssignmentIsActive() {
        // Given
        let now = Date()
        let pastDate = now.addingTimeInterval(-86400) // -1 day
        let futureDate = now.addingTimeInterval(86400) // +1 day
        
        let activeAssignment = Assignment(
            id: UUID(),
            vehicleId: UUID(),
            contractId: UUID(),
            driverUserId: UUID(),
            startDate: pastDate,
            endDate: futureDate,
            status: .active,
            createdAt: Date()
        )
        
        let futureAssignment = Assignment(
            id: UUID(),
            vehicleId: UUID(),
            contractId: UUID(),
            driverUserId: UUID(),
            startDate: futureDate,
            endDate: nil,
            status: .active,
            createdAt: Date()
        )
        
        let expiredAssignment = Assignment(
            id: UUID(),
            vehicleId: UUID(),
            contractId: UUID(),
            driverUserId: UUID(),
            startDate: pastDate,
            endDate: pastDate,
            status: .active,
            createdAt: Date()
        )
        
        // Then
        XCTAssertTrue(activeAssignment.isActive, "Debería ser activo cuando está en rango de fechas")
        XCTAssertFalse(futureAssignment.isActive, "No debería ser activo si la fecha de inicio es futura")
        XCTAssertFalse(expiredAssignment.isActive, "No debería ser activo si las fechas han expirado")
    }
}