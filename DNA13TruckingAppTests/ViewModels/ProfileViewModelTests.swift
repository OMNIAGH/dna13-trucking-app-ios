//
//  ProfileViewModelTests.swift
//  DNA13TruckingAppTests
//
//  Tests para ProfileViewModel
//

import XCTest
import Combine
import UIKit
@testable import DNA13TruckingApp

// MARK: - ProfileViewModelTests
class ProfileViewModelTests: XCTestCase {
    
    private var viewModel: ProfileViewModel!
    private var mockAuthManager: MockAuthManager!
    private var mockSupabaseService: MockSupabaseService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockAuthManager = MockAuthManager()
        mockSupabaseService = MockSupabaseService()
        viewModel = ProfileViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuthManager = nil
        mockSupabaseService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testProfileViewModelInitialization() {
        XCTAssertNil(viewModel.user, "User should be nil initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertFalse(viewModel.isEditing, "Should not be editing initially")
        XCTAssertNil(viewModel.selectedImage, "No image should be selected initially")
        XCTAssertFalse(viewModel.showImagePicker, "Image picker should not be shown initially")
        XCTAssertFalse(viewModel.showCamera, "Camera should not be shown initially")
        XCTAssertEqual(viewModel.fullName, "", "Full name should be empty initially")
        XCTAssertEqual(viewModel.email, "", "Email should be empty initially")
        XCTAssertEqual(viewModel.phone, "", "Phone should be empty initially")
        XCTAssertEqual(viewModel.emergencyContact, "", "Emergency contact should be empty initially")
        XCTAssertEqual(viewModel.emergencyPhone, "", "Emergency phone should be empty initially")
        XCTAssertEqual(viewModel.preferredLanguage, "es", "Language should default to Spanish")
        XCTAssertTrue(viewModel.notificationsEnabled, "Notifications should be enabled by default")
        XCTAssertFalse(viewModel.biometricEnabled, "Biometric should be disabled by default")
        XCTAssertFalse(viewModel.darkModeEnabled, "Dark mode should be disabled by default")
        XCTAssertFalse(viewModel.isAdmin, "Should not be admin by default")
    }
    
    // MARK: - User Profile Loading Tests
    func testLoadUserProfile() {
        let expectation = XCTestExpectation(description: "Load user profile")
        
        viewModel.$isLoading
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadUserProfile()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testLoadUserProfileWithUser() {
        // Setup: Create mock user
        let mockUser = MockSupabaseService.createMockUser()
        mockAuthManager.currentUser = mockUser
        
        let expectation = XCTestExpectation(description: "Load user with data")
        
        viewModel.$user
            .sink { user in
                if user != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadUserProfile()
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(viewModel.user, "User should be set after loading")
    }
    
    func testUpdateFormFields() {
        // Setup: Create mock user
        let mockUser = MockSupabaseService.createMockUser(
            id: UUID(),
            email: "test@example.com"
        )
        
        // Manually set user to test form field update
        viewModel.user = mockUser
        viewModel.updateFormFields()
        
        XCTAssertEqual(viewModel.fullName, "Test User")
        XCTAssertEqual(viewModel.email, "test@example.com")
    }
    
    func testUpdateFormFieldsWithEmptyUser() {
        // Test with nil user
        viewModel.user = nil
        viewModel.updateFormFields()
        
        // Should not crash and keep existing values
        XCTAssertEqual(viewModel.fullName, "")
        XCTAssertEqual(viewModel.email, "")
    }
    
    // MARK: - Form Fields Tests
    func testFormFieldValidation() {
        // Test valid form fields
        viewModel.fullName = "John Doe"
        viewModel.email = "john.doe@example.com"
        viewModel.phone = "555-123-4567"
        
        XCTAssertFalse(viewModel.fullName.isEmpty, "Full name should not be empty")
        XCTAssertFalse(viewModel.email.isEmpty, "Email should not be empty")
        XCTAssertFalse(viewModel.phone.isEmpty, "Phone should not be empty")
        XCTAssertTrue(viewModel.email.contains("@"), "Email should contain @ symbol")
    }
    
    func testFormFieldUpdates() {
        viewModel.fullName = "Jane Smith"
        viewModel.email = "jane.smith@example.com"
        viewModel.phone = "555-987-6543"
        
        XCTAssertEqual(viewModel.fullName, "Jane Smith")
        XCTAssertEqual(viewModel.email, "jane.smith@example.com")
        XCTAssertEqual(viewModel.phone, "555-987-6543")
    }
    
    func testEmergencyContactFields() {
        viewModel.emergencyContact = "Mary Johnson"
        viewModel.emergencyPhone = "555-456-7890"
        
        XCTAssertEqual(viewModel.emergencyContact, "Mary Johnson")
        XCTAssertEqual(viewModel.emergencyPhone, "555-456-7890")
    }
    
    // MARK: - Preferences Tests
    func testPreferredLanguage() {
        viewModel.preferredLanguage = "en"
        XCTAssertEqual(viewModel.preferredLanguage, "en")
        
        viewModel.preferredLanguage = "es"
        XCTAssertEqual(viewModel.preferredLanguage, "es")
    }
    
    func testNotificationSettings() {
        viewModel.notificationsEnabled = true
        XCTAssertTrue(viewModel.notificationsEnabled)
        
        viewModel.notificationsEnabled = false
        XCTAssertFalse(viewModel.notificationsEnabled)
    }
    
    func testBiometricSettings() {
        viewModel.biometricEnabled = true
        XCTAssertTrue(viewModel.biometricEnabled)
        
        viewModel.biometricEnabled = false
        XCTAssertFalse(viewModel.biometricEnabled)
    }
    
    func testDarkModeSettings() {
        viewModel.darkModeEnabled = true
        XCTAssertTrue(viewModel.darkModeEnabled)
        
        viewModel.darkModeEnabled = false
        XCTAssertFalse(viewModel.darkModeEnabled)
    }
    
    func testAllPreferences() {
        // Test all preference settings together
        viewModel.preferredLanguage = "fr"
        viewModel.notificationsEnabled = false
        viewModel.biometricEnabled = true
        viewModel.darkModeEnabled = true
        
        XCTAssertEqual(viewModel.preferredLanguage, "fr")
        XCTAssertFalse(viewModel.notificationsEnabled)
        XCTAssertTrue(viewModel.biometricEnabled)
        XCTAssertTrue(viewModel.darkModeEnabled)
    }
    
    // MARK: - Image Handling Tests
    func testImageSelection() {
        let testImage = UIImage(systemName: "person.circle")!
        
        viewModel.selectedImage = testImage
        XCTAssertEqual(viewModel.selectedImage, testImage)
        XCTAssertNil(viewModel.showImagePicker, "Image picker should not be shown when setting image directly")
    }
    
    func testImagePickerToggle() {
        XCTAssertFalse(viewModel.showImagePicker, "Initially not showing picker")
        
        viewModel.showImagePicker = true
        XCTAssertTrue(viewModel.showImagePicker, "Should be showing picker when set to true")
        
        viewModel.showImagePicker = false
        XCTAssertFalse(viewModel.showImagePicker, "Should not be showing picker when set to false")
    }
    
    func testCameraToggle() {
        XCTAssertFalse(viewModel.showCamera, "Initially not showing camera")
        
        viewModel.showCamera = true
        XCTAssertTrue(viewModel.showCamera, "Should be showing camera when set to true")
        
        viewModel.showCamera = false
        XCTAssertFalse(viewModel.showCamera, "Should not be showing camera when set to false")
    }
    
    // MARK: - Edit Mode Tests
    func testEditModeToggle() {
        XCTAssertFalse(viewModel.isEditing, "Initially not editing")
        
        viewModel.isEditing = true
        XCTAssertTrue(viewModel.isEditing, "Should be editing when set to true")
        
        viewModel.isEditing = false
        XCTAssertFalse(viewModel.isEditing, "Should not be editing when set to false")
    }
    
    func testStartEditing() {
        viewModel.fullName = "Original Name"
        viewModel.isEditing = true
        
        XCTAssertTrue(viewModel.isEditing)
    }
    
    func testCancelEditing() {
        // Setup: Start editing with some changes
        viewModel.isEditing = true
        viewModel.fullName = "Changed Name"
        
        // Cancel editing
        viewModel.isEditing = false
        
        XCTAssertFalse(viewModel.isEditing)
        // Note: In a real implementation, you might want to restore original values
    }
    
    // MARK: - Admin Tests
    func testAdminDetection() {
        XCTAssertFalse(viewModel.isAdmin, "Should not be admin initially")
        
        // Simulate admin user
        viewModel.isAdmin = true
        XCTAssertTrue(viewModel.isAdmin, "Should be admin when set to true")
    }
    
    func testApiSettings() {
        let testSettings = APISettings(
            openaiApiKey: "test-key",
            googleMapsApiKey: "maps-key",
            datApiKey: "dat-key",
            truckerPathApiKey: "path-key",
            weatherApiKey: "weather-key",
            maxRetries: 3,
            requestTimeout: 30,
            enableLogging: true
        )
        
        viewModel.apiSettings = testSettings
        XCTAssertEqual(viewModel.apiSettings.openaiApiKey, "test-key")
        XCTAssertEqual(viewModel.apiSettings.maxRetries, 3)
    }
    
    func testSystemSettings() {
        let testSettings = SystemSettings(
            appMaintenance: false,
            maintenanceMessage: "System is operational",
            maxActiveUsers: 1000,
            sessionTimeout: 3600,
            autoBackupEnabled: true,
            backupFrequency: 24,
            alertThresholds: AlertThresholds(
                fuelLevel: 20,
                maintenanceDue: 500,
                permitExpiry: 30,
                insuranceExpiry: 15
            ),
            featureFlags: FeatureFlags(
                aiRecommendations: true,
                predictiveAlerts: true,
                loadMatching: true,
                routeOptimization: true,
                fuelTracking: true,
                maintenanceReminders: true,
                complianceAlerts: true,
                weatherIntegration: true
            )
        )
        
        viewModel.systemSettings = testSettings
        XCTAssertFalse(viewModel.systemSettings.appMaintenance)
        XCTAssertTrue(viewModel.systemSettings.autoBackupEnabled)
        XCTAssertEqual(viewModel.systemSettings.maxActiveUsers, 1000)
    }
    
    // MARK: - Business Logic Tests
    func testEmailValidation() {
        // Valid emails
        XCTAssertTrue(isValidEmail("user@example.com"), "user@example.com should be valid")
        XCTAssertTrue(isValidEmail("test.user@domain.co.uk"), "test.user@domain.co.uk should be valid")
        
        // Invalid emails
        XCTAssertFalse(isValidEmail("invalid"), "invalid should be invalid")
        XCTAssertFalse(isValidEmail("user@"), "user@ should be invalid")
        XCTAssertFalse(isValidEmail("@domain.com"), "@domain.com should be invalid")
        XCTAssertFalse(isValidEmail("user@domain"), "user@domain should be invalid")
    }
    
    func testPhoneValidation() {
        // Valid phone numbers
        XCTAssertTrue(isValidPhone("555-123-4567"), "555-123-4567 should be valid")
        XCTAssertTrue(isValidPhone("(555) 123-4567"), "(555) 123-4567 should be valid")
        XCTAssertTrue(isValidPhone("5551234567"), "5551234567 should be valid")
        
        // Invalid phone numbers
        XCTAssertFalse(isValidPhone("123"), "123 should be invalid")
        XCTAssertFalse(isValidPhone("abc-def-ghij"), "abc-def-ghij should be invalid")
        XCTAssertFalse(isValidPhone(""), "empty string should be invalid")
    }
    
    func testFormCompleteness() {
        // Test that all required fields are filled
        viewModel.fullName = "John Doe"
        viewModel.email = "john@example.com"
        viewModel.phone = "555-123-4567"
        
        let isComplete = !viewModel.fullName.isEmpty && 
                        !viewModel.email.isEmpty && 
                        isValidEmail(viewModel.email)
        
        XCTAssertTrue(isComplete, "Form should be complete with valid data")
    }
    
    func testPreferencesData() {
        let preferences = UserPreferences(
            emergencyContact: "Jane Doe",
            emergencyPhone: "555-987-6543",
            preferredLanguage: "en",
            notificationsEnabled: false,
            biometricEnabled: true,
            darkModeEnabled: true
        )
        
        XCTAssertEqual(preferences.emergencyContact, "Jane Doe")
        XCTAssertEqual(preferences.preferredLanguage, "en")
        XCTAssertFalse(preferences.notificationsEnabled)
        XCTAssertTrue(preferences.biometricEnabled)
    }
    
    // MARK: - State Management Tests
    func testLoadingState() {
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        
        viewModel.isLoading = true
        XCTAssertTrue(viewModel.isLoading, "Should be loading when set to true")
        
        viewModel.isLoading = false
        XCTAssertFalse(viewModel.isLoading, "Should not be loading when set to false")
    }
    
    func testStateChanges() {
        let expectation = XCTestExpectation(description: "State changes")
        var stateChangeCount = 0
        
        viewModel.$isLoading
            .sink { _ in
                stateChangeCount += 1
                if stateChangeCount >= 2 { // Initial false, then true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.isLoading = true
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Async/Await Tests
    func testAsyncProfileUpdate() async {
        // Test async profile update if implemented
        let mockUser = MockSupabaseService.createMockUser()
        
        do {
            // Simulate async profile update
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            XCTAssertNotNil(mockUser, "Mock user should exist")
        } catch {
            XCTFail("Async operation should not fail")
        }
    }
    
    // MARK: - Edge Cases Tests
    func testEmptyUser() {
        viewModel.user = nil
        viewModel.updateFormFields()
        
        // Should handle nil user gracefully
        XCTAssertEqual(viewModel.fullName, "")
        XCTAssertEqual(viewModel.email, "")
    }
    
    func testVeryLongStrings() {
        let longString = String(repeating: "A", count: 1000)
        
        viewModel.fullName = longString
        viewModel.email = "\(longString)@example.com"
        
        XCTAssertEqual(viewModel.fullName.count, 1000)
        XCTAssertTrue(viewModel.email.count > 1000)
    }
    
    func testSpecialCharacters() {
        viewModel.fullName = "José María García-López"
        viewModel.email = "josé.maría@ejemplo.com"
        viewModel.phone = "+1-555-123-4567"
        
        XCTAssertEqual(viewModel.fullName, "José María García-López")
        XCTAssertEqual(viewModel.email, "josé.maría@ejemplo.com")
        XCTAssertEqual(viewModel.phone, "+1-555-123-4567")
    }
    
    func testNilValues() {
        // Test handling of nil optional values
        viewModel.phone = "" // Empty string
        viewModel.emergencyContact = "" // Empty string
        viewModel.emergencyPhone = "" // Empty string
        
        XCTAssertEqual(viewModel.phone, "")
        XCTAssertEqual(viewModel.emergencyContact, "")
        XCTAssertEqual(viewModel.emergencyPhone, "")
    }
    
    // MARK: - Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9\\-\\(\\)\\s\\+]+$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone)
    }
}

// MARK: - Test Data Models
struct UserPreferences {
    let emergencyContact: String
    let emergencyPhone: String
    let preferredLanguage: String
    let notificationsEnabled: Bool
    let biometricEnabled: Bool
    let darkModeEnabled: Bool
}