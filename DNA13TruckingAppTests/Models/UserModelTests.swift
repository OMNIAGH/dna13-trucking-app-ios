//
//  UserModelTests.swift
//  DNA13TruckingAppTests
//
//  Tests unitarios para el modelo User
//

import XCTest
import Foundation
@testable import DNA13TruckingApp

// MARK: - User Model Tests
final class UserModelTests: XCTestCase {
    
    // MARK: - Test Setup
    override func setUpWithError() throws {
        // Setup antes de cada test
    }
    
    override func tearDownWithError() throws {
        // Cleanup después de cada test
    }
    
    // MARK: - Codable Conformance Tests
    
    func testUserEncoding() throws {
        // Given
        let user = User(
            id: UUID(),
            username: "testuser",
            email: "test@example.com",
            phone: "+1234567890",
            status: .active,
            passwordHash: "hashedPassword",
            biometricIdRef: "biometric123",
            lastLoginAt: Date(),
            createdAt: Date(timeIntervalSince1970: 1640995200),
            updatedAt: Date(timeIntervalSince1970: 1640995200)
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(user)
        
        // Then
        XCTAssertFalse(data.isEmpty, "Los datos codificados no deberían estar vacíos")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decodedUser = try decoder.decode(User.self, from: data)
        
        XCTAssertEqual(user.id, decodedUser.id, "Los IDs deberían coincidir")
        XCTAssertEqual(user.username, decodedUser.username, "Los nombres de usuario deberían coincidir")
        XCTAssertEqual(user.email, decodedUser.email, "Los emails deberían coincidir")
        XCTAssertEqual(user.status, decodedUser.status, "Los estados deberían coincidir")
    }
    
    func testUserDecoding() throws {
        // Given
        let jsonString = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "username": "testuser",
            "email": "test@example.com",
            "phone": "+1234567890",
            "status": "active",
            "passwordHash": "hashedPassword",
            "biometricIdRef": "biometric123",
            "lastLoginAt": 1640995200,
            "createdAt": 1640995200,
            "updatedAt": 1640995200
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let user = try decoder.decode(User.self, from: jsonData)
        
        // Then
        XCTAssertEqual(user.username, "testuser", "El nombre de usuario debería decodificarse correctamente")
        XCTAssertEqual(user.email, "test@example.com", "El email debería decodificarse correctamente")
        XCTAssertEqual(user.status, .active, "El estado debería decodificarse correctamente")
        XCTAssertEqual(user.phone, "+1234567890", "El teléfono debería decodificarse correctamente")
    }
    
    func testUserCompleteJSONRoundTrip() throws {
        // Given
        let originalUser = User(
            id: UUID(),
            username: "comprehensive_user",
            email: "comprehensive@example.com",
            phone: "+1987654321",
            status: .active,
            passwordHash: "secureHash",
            biometricIdRef: "bioRef456",
            lastLoginAt: Date(),
            createdAt: Date(timeIntervalSince1970: 1640995200),
            updatedAt: Date(timeIntervalSince1970: 1640995200)
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(originalUser)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decodedUser = try decoder.decode(User.self, from: jsonData)
        
        // Then
        XCTAssertEqual(originalUser.id, decodedUser.id)
        XCTAssertEqual(originalUser.username, decodedUser.username)
        XCTAssertEqual(originalUser.email, decodedUser.email)
        XCTAssertEqual(originalUser.phone, decodedUser.phone)
        XCTAssertEqual(originalUser.status, decodedUser.status)
        XCTAssertEqual(originalUser.passwordHash, decodedUser.passwordHash)
        XCTAssertEqual(originalUser.biometricIdRef, decodedUser.biometricIdRef)
        
        // Verificar que el JSON generado es válido
        XCTAssertFalse(jsonString.isEmpty, "El JSON generado no debería estar vacío")
        XCTAssertTrue(jsonString.contains("\"username\""), "El JSON debería contener la clave username")
    }
    
    // MARK: - User Status Tests
    
    func testUserStatusAllCases() {
        // Given
        let allStatuses = UserStatus.allCases
        
        // Then
        XCTAssertEqual(allStatuses.count, 4, "Debería haber exactamente 4 estados de usuario")
        XCTAssertTrue(allStatuses.contains(.active), "Debería incluir el estado 'active'")
        XCTAssertTrue(allStatuses.contains(.inactive), "Debería incluir el estado 'inactive'")
        XCTAssertTrue(allStatuses.contains(.suspended), "Debería incluir el estado 'suspended'")
        XCTAssertTrue(allStatuses.contains(.pending), "Debería incluir el estado 'pending'")
    }
    
    func testUserStatusDisplayNames() {
        // Then
        XCTAssertEqual(UserStatus.active.displayName, "Activo")
        XCTAssertEqual(UserStatus.inactive.displayName, "Inactivo")
        XCTAssertEqual(UserStatus.suspended.displayName, "Suspendido")
        XCTAssertEqual(UserStatus.pending.displayName, "Pendiente")
    }
    
    func testUserStatusIsActive() {
        // Given
        let activeUser = User(
            id: UUID(),
            username: "activeuser",
            email: "active@example.com",
            phone: nil,
            status: .active,
            passwordHash: "hash",
            biometricIdRef: nil,
            lastLoginAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let inactiveUser = User(
            id: UUID(),
            username: "inactiveuser",
            email: "inactive@example.com",
            phone: nil,
            status: .inactive,
            passwordHash: "hash",
            biometricIdRef: nil,
            lastLoginAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertTrue(activeUser.isActive, "El usuario activo debería retornar true para isActive")
        XCTAssertFalse(inactiveUser.isActive, "El usuario inactivo debería retornar false para isActive")
    }
    
    // MARK: - Validation Tests
    
    func testUserInitializationWithValidData() {
        // When
        let user = User(
            id: UUID(),
            username: "validuser",
            email: "valid@example.com",
            phone: "+1234567890",
            status: .active,
            passwordHash: "hashedPassword",
            biometricIdRef: "biometricRef",
            lastLoginAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertNotNil(user.id, "El ID no debería ser nil")
        XCTAssertEqual(user.username, "validuser", "El nombre de usuario debería ser válido")
        XCTAssertEqual(user.email, "valid@example.com", "El email debería ser válido")
    }
    
    func testUserInitializationWithMinimalData() {
        // When
        let user = User(
            id: UUID(),
            username: "minimaluser",
            email: "minimal@example.com",
            phone: nil,
            status: .pending,
            passwordHash: "hashedPassword",
            biometricIdRef: nil,
            lastLoginAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.username, "minimaluser")
        XCTAssertEqual(user.email, "minimal@example.com")
        XCTAssertNil(user.phone)
        XCTAssertNil(user.biometricIdRef)
        XCTAssertNil(user.lastLoginAt)
    }
    
    // MARK: - Edge Cases Tests
    
    func testUserWithEmptyUsername() {
        // When
        let user = User(
            id: UUID(),
            username: "",
            email: "test@example.com",
            phone: nil,
            status: .active,
            passwordHash: "hash",
            biometricIdRef: nil,
            lastLoginAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then - El modelo debería permitir username vacío
        XCTAssertEqual(user.username, "", "Debería permitir username vacío")
        XCTAssertEqual(user.fullName, "", "fullName debería retornar username vacío")
    }
    
    func testUserWithAllStatusValues() {
        // Given
        let statuses: [UserStatus] = [.active, .inactive, .suspended, .pending]
        
        // Then
        for status in statuses {
            let user = User(
                id: UUID(),
                username: "user_\(status.rawValue)",
                email: "\(status.rawValue)@example.com",
                phone: nil,
                status: status,
                passwordHash: "hash",
                biometricIdRef: nil,
                lastLoginAt: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            XCTAssertEqual(user.status, status, "El estado \(status.rawValue) debería asignarse correctamente")
            
            if status == .active {
                XCTAssertTrue(user.isActive, "Solo active debería retornar true en isActive")
            } else {
                XCTAssertFalse(user.isActive, "\(status.rawValue) debería retornar false en isActive")
            }
        }
    }
    
    // MARK: - JSON Edge Cases Tests
    
    func testUserDecodingWithMissingOptionalFields() throws {
        // Given
        let jsonString = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "username": "minimaluser",
            "email": "minimal@example.com",
            "status": "active",
            "passwordHash": "hashedPassword",
            "createdAt": 1640995200,
            "updatedAt": 1640995200
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let user = try decoder.decode(User.self, from: jsonData)
        
        // Then
        XCTAssertEqual(user.username, "minimaluser")
        XCTAssertEqual(user.email, "minimal@example.com")
        XCTAssertEqual(user.status, .active)
        XCTAssertNil(user.phone, "El campo phone debería ser nil")
        XCTAssertNil(user.biometricIdRef, "El campo biometricIdRef debería ser nil")
        XCTAssertNil(user.lastLoginAt, "El campo lastLoginAt debería ser nil")
    }
    
    func testUserDecodingWithInvalidStatus() {
        // Given
        let jsonString = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "username": "testuser",
            "email": "test@example.com",
            "status": "invalid_status",
            "passwordHash": "hashedPassword",
            "createdAt": 1640995200,
            "updatedAt": 1640995200
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode(User.self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError, "Debería lanzar un DecodingError")
        }
    }
    
    func testUserWithVeryLongFields() {
        // Given
        let longString = String(repeating: "a", count: 1000)
        
        // When
        let user = User(
            id: UUID(),
            username: longString,
            email: "test@example.com",
            phone: nil,
            status: .active,
            passwordHash: longString,
            biometricIdRef: nil,
            lastLoginAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertEqual(user.username.count, 1000, "Debería permitir strings muy largos")
        XCTAssertEqual(user.passwordHash.count, 1000, "Debería permitir hash muy largo")
    }
    
    // MARK: - Performance Tests
    
    func testUserEncodingPerformance() throws {
        // Given
        let user = User(
            id: UUID(),
            username: "perfuser",
            email: "perf@example.com",
            phone: "+1234567890",
            status: .active,
            passwordHash: "hashedPassword",
            biometricIdRef: "biometricRef",
            lastLoginAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When - Measure
        self.measure {
            for _ in 0..<1000 {
                _ = try? JSONEncoder().encode(user)
            }
        }
    }
    
    func testUserDecodingPerformance() throws {
        // Given
        let jsonString = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "username": "perfuser",
            "email": "perf@example.com",
            "phone": "+1234567890",
            "status": "active",
            "passwordHash": "hashedPassword",
            "biometricIdRef": "biometricRef",
            "lastLoginAt": 1640995200,
            "createdAt": 1640995200,
            "updatedAt": 1640995200
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When - Measure
        self.measure {
            for _ in 0..<1000 {
                _ = try? JSONDecoder().decode(User.self, from: jsonData)
            }
        }
    }
}

// MARK: - Role Model Tests
final class RoleModelTests: XCTestCase {
    
    func testRoleEncodingDecoding() throws {
        // Given
        let role = Role(
            id: UUID(),
            code: "driver",
            name: "Conductor",
            description: "Rol para conductores de camiones"
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(role)
        let decoder = JSONDecoder()
        let decodedRole = try decoder.decode(Role.self, from: data)
        
        // Then
        XCTAssertEqual(role.id, decodedRole.id)
        XCTAssertEqual(role.code, decodedRole.code)
        XCTAssertEqual(role.name, decodedRole.name)
        XCTAssertEqual(role.description, decodedRole.description)
    }
    
    func testRoleAllCodes() {
        // Then
        let allCodes = Role.RoleCode.allCases
        XCTAssertEqual(allCodes.count, 4)
        XCTAssertTrue(allCodes.contains(.driver))
        XCTAssertTrue(allCodes.contains(.dispatcher))
        XCTAssertTrue(allCodes.contains(.manager))
        XCTAssertTrue(allCodes.contains(.admin))
    }
}

// MARK: - Permission Model Tests
final class PermissionModelTests: XCTestCase {
    
    func testPermissionEncodingDecoding() throws {
        // Given
        let permission = Permission(
            id: UUID(),
            code: "trips.create",
            name: "Crear Viajes",
            description: "Permiso para crear nuevos viajes"
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(permission)
        let decoder = JSONDecoder()
        let decodedPermission = try decoder.decode(Permission.self, from: data)
        
        // Then
        XCTAssertEqual(permission.id, decodedPermission.id)
        XCTAssertEqual(permission.code, decodedPermission.code)
        XCTAssertEqual(permission.name, decodedPermission.name)
    }
    
    func testPermissionAllCodes() {
        // Then
        let allCodes = Permission.PermissionCode.allCases
        XCTAssertTrue(allCodes.contains(.tripsCreate))
        XCTAssertTrue(allCodes.contains(.vehiclesCreate))
        XCTAssertTrue(allCodes.contains(.documentsCreate))
        XCTAssertTrue(allCodes.contains(.fuelCreate))
        XCTAssertTrue(allCodes.contains(.costsCreate))
        XCTAssertTrue(allCodes.contains(.escrowRead))
        XCTAssertTrue(allCodes.contains(.reportsRead))
    }
}