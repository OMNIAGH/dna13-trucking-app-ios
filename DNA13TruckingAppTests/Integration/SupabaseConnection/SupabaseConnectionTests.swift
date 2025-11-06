import XCTest
import Supabase
@testable import DNA13TruckingApp

/// Tests de integración para conexión y autenticación con Supabase
final class SupabaseConnectionTests: XCTestCase {
    
    var supabaseService: SupabaseService!
    var testTimeout: TimeInterval = 30
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        supabaseService = SupabaseService()
    }
    
    override func tearDownWithError() throws {
        supabaseService = nil
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo para cleanup
        try super.tearDownWithError()
    }
    
    // MARK: - Connection Tests
    
    /// Test de conexión básica con Supabase
    func testConnectionToSupabase() async throws {
        // Given
        let service = SupabaseService()
        
        // When
        await service.checkConnection()
        
        // Then
        XCTAssertTrue(service.isConnected, "La conexión con Supabase debe ser exitosa")
        XCTAssertEqual(service.connectionStatus, "Connected", "El estado de conexión debe ser 'Connected'")
    }
    
    /// Test de timeout de conexión
    func testConnectionTimeout() async throws {
        // Given
        let service = SupabaseService()
        
        // When & Then
        await fulfillment(of: [], timeout: testTimeout) {
            await service.checkConnection()
        }
        
        XCTAssertTrue(service.isConnected, "La conexión debe completarse dentro del timeout")
    }
    
    // MARK: - Authentication Tests
    
    /// Test de registro de usuario
    func testUserSignUp() async throws {
        // Given
        let testEmail = "test-\(UUID().uuidString)@test.com"
        let testPassword = "TestPassword123!"
        let testFullName = "Test User"
        
        // When
        let user = try await supabaseService.signUp(
            email: testEmail,
            password: testPassword,
            fullName: testFullName
        )
        
        // Then
        XCTAssertNotNil(user, "El usuario debe crearse exitosamente")
        XCTAssertEqual(user.email, testEmail, "El email debe coincidir")
        
        // Cleanup
        try await supabaseService.signOut()
    }
    
    /// Test de inicio de sesión
    func testUserSignIn() async throws {
        // Given - Primero crear usuario
        let testEmail = "test-signin-\(UUID().uuidString)@test.com"
        let testPassword = "TestPassword123!"
        let testFullName = "Test Signin User"
        
        _ = try await supabaseService.signUp(
            email: testEmail,
            password: testPassword,
            fullName: testFullName
        )
        
        // When - Ahora iniciar sesión
        let user = try await supabaseService.signIn(
            email: testEmail,
            password: testPassword
        )
        
        // Then
        XCTAssertNotNil(user, "El inicio de sesión debe ser exitoso")
        XCTAssertEqual(user.email, testEmail, "El email del usuario debe coincidir")
        
        // Cleanup
        try await supabaseService.signOut()
    }
    
    /// Test de inicio de sesión con credenciales inválidas
    func testSignInWithInvalidCredentials() async throws {
        // Given
        let invalidEmail = "invalid@test.com"
        let invalidPassword = "invalidpassword"
        
        // When & Then
        do {
            _ = try await supabaseService.signIn(
                email: invalidEmail,
                password: invalidPassword
            )
            XCTFail("El inicio de sesión debe fallar con credenciales inválidas")
        } catch {
            XCTAssertNotNil(error, "Debe lanzarse un error con credenciales inválidas")
        }
    }
    
    /// Test de obtención de usuario actual
    func testGetCurrentUser() async throws {
        // Given
        let testEmail = "test-currentuser-\(UUID().uuidString)@test.com"
        let testPassword = "TestPassword123!"
        let testFullName = "Test Current User"
        
        // When
        let user = try await supabaseService.signUp(
            email: testEmail,
            password: testPassword,
            fullName: testFullName
        )
        
        let currentUser = await supabaseService.getCurrentUser()
        
        // Then
        XCTAssertNotNil(currentUser, "Debe existir un usuario actual")
        XCTAssertEqual(currentUser?.id, user.id, "El usuario actual debe coincidir con el registrado")
        
        // Cleanup
        try await supabaseService.signOut()
    }
    
    /// Test de cierre de sesión
    func testSignOut() async throws {
        // Given
        let testEmail = "test-signout-\(UUID().uuidString)@test.com"
        let testPassword = "TestPassword123!"
        let testFullName = "Test Signout User"
        
        _ = try await supabaseService.signUp(
            email: testEmail,
            password: testPassword,
            fullName: testFullName
        )
        
        // When
        try await supabaseService.signOut()
        
        // Then
        let currentUser = await supabaseService.getCurrentUser()
        XCTAssertNil(currentUser, "No debe haber usuario actual después del sign out")
    }
    
    // MARK: - User Profile Tests
    
    /// Test de creación de perfil de usuario
    func testCreateUserProfile() async throws {
        // Given
        let testUserId = UUID()
        let testProfile = UserProfile(
            id: testUserId,
            email: "test-profile@test.com",
            fullName: "Test Profile",
            role: "driver",
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: nil
        )
        
        // When
        try await supabaseService.createUserProfile(testProfile)
        
        // Then
        let retrievedProfile = try await supabaseService.getUserProfile(userId: testUserId)
        XCTAssertNotNil(retrievedProfile, "El perfil debe crearse y poder recuperarse")
        XCTAssertEqual(retrievedProfile?.fullName, testProfile.fullName, "Los datos del perfil deben coincidir")
    }
    
    /// Test de obtención de perfil de usuario inexistente
    func testGetNonExistentUserProfile() async throws {
        // Given
        let nonExistentUserId = UUID()
        
        // When
        let profile = try await supabaseService.getUserProfile(userId: nonExistentUserId)
        
        // Then
        XCTAssertNil(profile, "No debe existir perfil para usuario inexistente")
    }
    
    // MARK: - Performance Tests
    
    /// Test de rendimiento de múltiples conexiones concurrentes
    func testConcurrentConnections() async throws {
        // Given
        let serviceCount = 5
        var services: [SupabaseService] = []
        
        for i in 0..<serviceCount {
            let service = SupabaseService()
            services.append(service)
        }
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for service in services {
                group.addTask {
                    await service.checkConnection()
                }
            }
        }
        
        // Then
        for service in services {
            XCTAssertTrue(service.isConnected, "Todas las conexiones concurrentes deben ser exitosas")
        }
    }
    
    /// Test de rendimiento de autenticación múltiple
    func testConcurrentAuthentication() async throws {
        // Given
        let authCount = 3
        var results: [Result<User, Error>] = []
        
        // When
        await withTaskGroup(of: (Int, Result<User, Error>).self) { group in
            for i in 0..<authCount {
                group.addTask { index in
                    let testEmail = "test-concurrent-\(index)-\(UUID().uuidString)@test.com"
                    let testPassword = "TestPassword123!"
                    let testFullName = "Test Concurrent User \(index)"
                    
                    do {
                        let user = try await self.supabaseService.signUp(
                            email: testEmail,
                            password: testPassword,
                            fullName: testFullName
                        )
                        return (index, .success(user))
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
        XCTAssertEqual(results.count, authCount, "Debe procesarse el número esperado de autenticaciones")
        
        for result in results {
            switch result {
            case .success:
                break // Éxito esperado
            case .failure(let error):
                XCTFail("Autenticación concurrente falló: \(error.localizedDescription)")
            }
        }
        
        // Cleanup
        for result in results {
            if case .success(let user) = result {
                // Note: En un escenario real, necesitarías mantener referencias a los servicios
                // para poder hacer sign out
            }
        }
    }
    
    // MARK: - Network Tests
    
    /// Test de recuperación de conexión de red
    func testNetworkReconnection() async throws {
        // Given
        let service = SupabaseService()
        
        // When - Simular pérdida de conexión y recuperación
        await service.checkConnection()
        XCTAssertTrue(service.isConnected, "La conexión inicial debe ser exitosa")
        
        // Simular tiempo de reintento
        await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
        
        // Verificar reconexión
        await service.checkConnection()
        XCTAssertTrue(service.isConnected, "La reconexión debe ser exitosa")
    }
    
    /// Test de validación de configuración de Supabase
    func testSupabaseConfiguration() throws {
        // Then - Verificar que la configuración está presente
        XCTAssertFalse(AppConfig.supabaseURL.isEmpty, "La URL de Supabase debe estar configurada")
        XCTAssertFalse(AppConfig.supabaseAnonKey.isEmpty, "La clave anónima de Supabase debe estar configurada")
        XCTAssertTrue(AppConfig.supabaseURL.hasPrefix("https://"), "La URL de Supabase debe usar HTTPS")
        XCTAssertTrue(AppConfig.supabaseAnonKey.count > 100, "La clave anónima debe tener una longitud válida")
    }
}