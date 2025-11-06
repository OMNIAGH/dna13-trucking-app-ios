//
//  ProfileViewModel.swift
//  DNA13TruckingApp
//
//  ViewModel para la vista de perfil de usuario
//

import Foundation
import SwiftUI
import Combine

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var isEditing: Bool = false
    @Published var selectedImage: UIImage?
    @Published var showImagePicker: Bool = false
    @Published var showCamera: Bool = false
    
    // Form fields
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var emergencyContact: String = ""
    @Published var emergencyPhone: String = ""
    @Published var preferredLanguage: String = "es"
    @Published var notificationsEnabled: Bool = true
    @Published var biometricEnabled: Bool = false
    @Published var darkModeEnabled: Bool = false
    
    // Admin settings (only visible to admins)
    @Published var isAdmin: Bool = false
    @Published var apiSettings: APISettings = APISettings()
    @Published var systemSettings: SystemSettings = SystemSettings()
    
    private var cancellables = Set<AnyCancellable>()
    private let authManager = AuthManager.shared
    private let supabaseService = SupabaseService.shared
    
    init() {
        loadUserProfile()
        setupObservers()
    }
    
    private func setupObservers() {
        // Observar cambios en autenticación
        authManager.$currentUser
            .sink { [weak self] user in
                self?.user = user
                self?.updateFormFields()
            }
            .store(in: &cancellables)
    }
    
    func loadUserProfile() {
        isLoading = true
        
        Task {
            do {
                let user = try await authManager.getCurrentUser()
                
                DispatchQueue.main.async { [weak self] in
                    self?.user = user
                    self?.updateFormFields()
                    self?.isLoading = false
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    // TODO: Manejar error
                }
            }
        }
    }
    
    private func updateFormFields() {
        guard let user = user else { return }
        
        fullName = user.fullName
        email = user.email
        phone = user.phone ?? ""
        
        // Verificar si es admin
        isAdmin = user.hasPermission(.reportsCreate, rolePermissions: [], userRoles: [], roles: [], permissions: [])
    }
    
    func saveProfile() {
        guard let user = user else { return }
        
        isLoading = true
        
        let updatedUser = User(
            id: user.id,
            username: user.username,
            email: email,
            phone: phone.isEmpty ? nil : phone,
            status: user.status,
            passwordHash: user.passwordHash,
            biometricIdRef: user.biometricIdRef,
            lastLoginAt: user.lastLoginAt,
            createdAt: user.createdAt,
            updatedAt: Date()
        )
        
        Task {
            do {
                try await supabaseService.updateUserProfile(updatedUser)
                
                // Guardar preferencias
                await saveUserPreferences()
                
                DispatchQueue.main.async { [weak self] in
                    self?.user = updatedUser
                    self?.isEditing = false
                    self?.isLoading = false
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    // TODO: Mostrar error
                }
            }
        }
    }
    
    private func saveUserPreferences() async {
        let preferences = UserPreferences(
            emergencyContact: emergencyContact,
            emergencyPhone: emergencyPhone,
            preferredLanguage: preferredLanguage,
            notificationsEnabled: notificationsEnabled,
            biometricEnabled: biometricEnabled,
            darkModeEnabled: darkModeEnabled
        )
        
        do {
            try await supabaseService.saveUserPreferences(preferences)
        } catch {
            // TODO: Manejar error
        }
    }
    
    func uploadProfileImage() {
        guard let image = selectedImage else { return }
        
        isLoading = true
        
        Task {
            do {
                let imageUrl = try await supabaseService.uploadProfileImage(image)
                
                DispatchQueue.main.async { [weak self] in
                    // TODO: Actualizar URL de imagen del usuario
                    self?.isLoading = false
                    self?.selectedImage = nil
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    // TODO: Mostrar error
                }
            }
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await authManager.changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }
    
    func enableBiometricAuth() {
        Task {
            do {
                try await authManager.enableBiometricAuthentication()
                
                DispatchQueue.main.async { [weak self] in
                    self?.biometricEnabled = true
                }
            } catch {
                // TODO: Manejar error
            }
        }
    }
    
    func disableBiometricAuth() {
        Task {
            do {
                try await authManager.disableBiometricAuthentication()
                
                DispatchQueue.main.async { [weak self] in
                    self?.biometricEnabled = false
                }
            } catch {
                // TODO: Manejar error
            }
        }
    }
    
    func logout() {
        authManager.logout()
    }
    
    func deleteAccount() async throws {
        guard let user = user else { return }
        
        try await supabaseService.deleteUserAccount(userId: user.id)
        authManager.logout()
    }
    
    // MARK: - Admin Functions
    
    func saveAPISettings() {
        guard isAdmin else { return }
        
        Task {
            do {
                try await supabaseService.updateAPISettings(apiSettings)
            } catch {
                // TODO: Manejar error
            }
        }
    }
    
    func saveSystemSettings() {
        guard isAdmin else { return }
        
        Task {
            do {
                try await supabaseService.updateSystemSettings(systemSettings)
            } catch {
                // TODO: Manejar error
            }
        }
    }
    
    func exportUserData() async throws {
        guard let user = user else { return }
        
        try await supabaseService.exportUserData(userId: user.id)
    }
    
    func backupDatabase() async throws {
        guard isAdmin else { return }
        
        try await supabaseService.backupDatabase()
    }
    
    func createBackup() async throws {
        guard isAdmin else { return }
        
        try await supabaseService.createFullBackup()
    }
    
    func restoreFromBackup(backupId: String) async throws {
        guard isAdmin else { return }
        
        try await supabaseService.restoreFromBackup(backupId: backupId)
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var emergencyContact: String
    var emergencyPhone: String
    var preferredLanguage: String
    var notificationsEnabled: Bool
    var biometricEnabled: Bool
    var darkModeEnabled: Bool
}

// MARK: - API Settings (Admin only)
struct APISettings: Codable {
    var openaiApiKey: String = ""
    var googleMapsApiKey: String = ""
    var datApiKey: String = ""
    var truckerPathApiKey: String = ""
    var weatherApiKey: String = ""
    var maxRetries: Int = 3
    var requestTimeout: Int = 30
    var enableLogging: Bool = true
}

// MARK: - System Settings (Admin only)
struct SystemSettings: Codable {
    var appMaintenance: Bool = false
    var maintenanceMessage: String = ""
    var maxActiveUsers: Int = 100
    var sessionTimeout: Int = 480 // 8 horas
    var autoBackupEnabled: Bool = true
    var backupFrequency: String = "daily"
    var alertThresholds: AlertThresholds = AlertThresholds()
    var featureFlags: FeatureFlags = FeatureFlags()
}

// MARK: - Alert Thresholds
struct AlertThresholds: Codable {
    var fuelLevel: Double = 0.25 // 25%
    var maintenanceDue: Int = 7 // días
    var permitExpiry: Int = 30 // días
    var insuranceExpiry: Int = 30 // días
}

// MARK: - Feature Flags
struct FeatureFlags: Codable {
    var aiRecommendations: Bool = true
    var predictiveAlerts: Bool = true
    var loadMatching: Bool = true
    var routeOptimization: Bool = true
    var fuelTracking: Bool = true
    var maintenanceReminders: Bool = true
    var complianceAlerts: Bool = true
    var weatherIntegration: Bool = true
}

// MARK: - Profile Validation
extension ProfileViewModel {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    var isValidPhone: Bool {
        guard !phone.isEmpty else { return true }
        let phoneRegex = "^\\+?[1-9]\\d{1,14}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone)
    }
    
    var isFormValid: Bool {
        return isValidEmail && isValidPhone && !fullName.isEmpty
    }
    
    var hasChanges: Bool {
        guard let user = user else { return false }
        
        return fullName != user.fullName ||
               email != user.email ||
               phone != (user.phone ?? "")
    }
}