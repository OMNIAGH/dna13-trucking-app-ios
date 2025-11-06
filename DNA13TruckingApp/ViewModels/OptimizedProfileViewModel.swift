//
//  OptimizedProfileViewModel.swift
//  DNA13TruckingApp
//
//  ViewModel optimizado para el perfil de usuario con mejor manejo de errores,
//  validación en tiempo real y seguridad mejorada
//

import Foundation
import SwiftUI
import Combine
import OSLog

@MainActor
class OptimizedProfileViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var isEditing: Bool = false
    @Published var isSaving: Bool = false
    
    // Form fields with validation
    @Published var fullName: String = "" {
        didSet { validateFullName() }
    }
    @Published var email: String = "" {
        didSet { validateEmail() }
    }
    @Published var phone: String = "" {
        didSet { validatePhone() }
    }
    @Published var emergencyContact: String = ""
    @Published var emergencyPhone: String = "" {
        didSet { validateEmergencyPhone() }
    }
    
    // Preferences
    @Published var preferences: UserPreferences = UserPreferences()
    
    // Validation states
    @Published var validationErrors: [ValidationError] = []
    @Published var isFormValid: Bool = false
    
    // Image handling
    @Published var selectedImage: UIImage?
    @Published var showImagePicker: Bool = false
    @Published var showCamera: Bool = false
    @Published var isUploadingImage: Bool = false
    
    // Admin settings (only visible to admins)
    @Published var isAdmin: Bool = false
    @Published var adminSettings: AdminSettings = AdminSettings()
    
    // Error handling
    @Published var errorState: ProfileErrorState?
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    private let authManager: AuthManager
    private let supabaseService: OptimizedSupabaseService
    private let securityManager: SecurityManager
    private let logger = Logger(subsystem: "com.dna13trucking.app", category: "ProfileViewModel")
    
    private var cancellables = Set<AnyCancellable>()
    private var validationTimer: Timer?
    private var saveDebouncer: Timer?
    
    // MARK: - Initialization
    init(
        authManager: AuthManager = AuthManager.shared,
        supabaseService: OptimizedSupabaseService = OptimizedSupabaseService.shared,
        securityManager: SecurityManager = SecurityManager.shared
    ) {
        self.authManager = authManager
        self.supabaseService = supabaseService
        self.securityManager = securityManager
        
        setupObservers()
        loadUserProfile()
        setupRealTimeValidation()
    }
    
    deinit {
        validationTimer?.invalidate()
        saveDebouncer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func loadUserProfile() {
        guard !isLoading else { return }
        
        isLoading = true
        errorState = nil
        
        Task {
            do {
                let currentUser = try await authManager.getCurrentUser()
                let userPreferences = try await loadUserPreferences()
                
                self.user = currentUser
                self.preferences = userPreferences
                self.updateFormFields()
                self.checkAdminStatus()
                
                logger.info("User profile loaded successfully")
                
            } catch {
                await handleError(error, operation: "cargar perfil")
            }
            
            self.isLoading = false
        }
    }
    
    func saveProfile() {
        guard isFormValid && !isSaving else { return }
        
        isSaving = true
        errorState = nil
        
        Task {
            do {
                // Validate data integrity
                try validateFormData()
                
                // Create updated user object
                guard let currentUser = user else {
                    throw ProfileError.noCurrentUser
                }
                
                let updatedUser = createUpdatedUser(from: currentUser)
                
                // Save user profile
                try await supabaseService.updateUserProfile(updatedUser)
                
                // Save preferences
                try await saveUserPreferences()
                
                // Save admin settings if admin
                if isAdmin {
                    try await saveAdminSettings()
                }
                
                // Update local state
                self.user = updatedUser
                self.isEditing = false
                self.successMessage = "Perfil actualizado exitosamente"
                
                // Auto-hide success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.successMessage = nil
                }
                
                logger.info("Profile saved successfully")
                
            } catch {
                await handleError(error, operation: "guardar perfil")
            }
            
            self.isSaving = false
        }
    }
    
    func uploadProfileImage() {
        guard let image = selectedImage, !isUploadingImage else { return }
        
        isUploadingImage = true
        
        Task {
            do {
                // Optimize image before upload
                let optimizedImage = optimizeImage(image)
                guard let imageData = optimizedImage.jpegData(compressionQuality: 0.8) else {
                    throw ProfileError.imageProcessingFailed
                }
                
                // Validate image size
                if imageData.count > 5 * 1024 * 1024 { // 5MB limit
                    throw ProfileError.imageTooLarge
                }
                
                // Upload to secure storage
                let imageUrl = try await supabaseService.uploadProfileImage(imageData)
                
                // Update user profile with new image URL
                if var currentUser = user {
                    currentUser.profileImageURL = imageUrl
                    try await supabaseService.updateUserProfile(currentUser)
                    self.user = currentUser
                }
                
                self.selectedImage = nil
                self.successMessage = "Imagen de perfil actualizada"
                
                logger.info("Profile image uploaded successfully")
                
            } catch {
                await handleError(error, operation: "subir imagen")
            }
            
            self.isUploadingImage = false
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) async {
        do {
            // Validate passwords
            try validatePasswordChange(current: currentPassword, new: newPassword, confirm: confirmPassword)
            
            // Change password with enhanced security
            try await authManager.changePasswordSecure(currentPassword: currentPassword, newPassword: newPassword)
            
            self.successMessage = "Contraseña cambiada exitosamente"
            
            logger.info("Password changed successfully")
            
        } catch {
            await handleError(error, operation: "cambiar contraseña")
        }
    }
    
    func enableBiometricAuth() async {
        do {
            try await authManager.enableBiometricAuthentication()
            preferences.biometricEnabled = true
            
            self.successMessage = "Autenticación biométrica habilitada"
            
        } catch {
            await handleError(error, operation: "habilitar autenticación biométrica")
        }
    }
    
    func disableBiometricAuth() async {
        do {
            try await authManager.disableBiometricAuthentication()
            preferences.biometricEnabled = false
            
            self.successMessage = "Autenticación biométrica deshabilitada"
            
        } catch {
            await handleError(error, operation: "deshabilitar autenticación biométrica")
        }
    }
    
    func exportUserData() async {
        guard let user = user else { return }
        
        do {
            let exportData = try await supabaseService.exportUserData(userId: user.id)
            
            // Create and share export file
            await shareExportedData(exportData)
            
            self.successMessage = "Datos exportados exitosamente"
            
        } catch {
            await handleError(error, operation: "exportar datos")
        }
    }
    
    func deleteAccount() async {
        guard let user = user else { return }
        
        // Show confirmation before deletion
        let confirmed = await showDeleteConfirmation()
        guard confirmed else { return }
        
        do {
            // Delete user account and all associated data
            try await supabaseService.deleteUserAccount(userId: user.id)
            
            // Clear all local data
            clearAllUserData()
            
            // Logout user
            authManager.logout()
            
            logger.info("User account deleted successfully")
            
        } catch {
            await handleError(error, operation: "eliminar cuenta")
        }
    }
    
    // MARK: - Admin Functions
    
    func performSecurityAudit() async {
        guard isAdmin else { return }
        
        let auditResult = securityManager.performSecurityAudit()
        
        // Update admin settings with audit results
        adminSettings.lastSecurityAudit = auditResult.auditDate
        adminSettings.securityIssuesCount = auditResult.issues.count
        
        if auditResult.severity == .critical {
            errorState = .securityAuditFailed(auditResult.issues.map { $0.description })
        }
    }
    
    func rotateEncryptionKeys() async {
        guard isAdmin else { return }
        
        do {
            try securityManager.rotateEncryptionKey()
            self.successMessage = "Claves de encriptación rotadas exitosamente"
            
        } catch {
            await handleError(error, operation: "rotar claves de encriptación")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe authentication changes
        authManager.$currentUser
            .removeDuplicates()
            .sink { [weak self] user in
                if user != nil {
                    self?.loadUserProfile()
                } else {
                    self?.clearUserData()
                }
            }
            .store(in: &cancellables)
        
        // Observe form changes for auto-save
        Publishers.CombineLatest4($fullName, $email, $phone, $preferences)
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                if self?.isEditing == true && self?.isFormValid == true {
                    self?.debouncedSave()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRealTimeValidation() {
        validationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.validateForm()
        }
    }
    
    private func updateFormFields() {
        guard let user = user else { return }
        
        fullName = user.fullName
        email = user.email
        phone = user.phone ?? ""
        
        validateForm()
    }
    
    private func checkAdminStatus() {
        guard let user = user else { return }
        
        // Check user permissions to determine admin status
        isAdmin = user.hasAdminPermissions()
        
        if isAdmin {
            Task {
                await loadAdminSettings()
            }
        }
    }
    
    private func validateForm() {
        var errors: [ValidationError] = []
        
        // Validate full name
        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyFullName)
        } else if fullName.count < 2 {
            errors.append(.fullNameTooShort)
        }
        
        // Validate email
        if !isValidEmail(email) {
            errors.append(.invalidEmail)
        }
        
        // Validate phone (optional but must be valid if provided)
        if !phone.isEmpty && !isValidPhone(phone) {
            errors.append(.invalidPhone)
        }
        
        // Validate emergency phone
        if !emergencyPhone.isEmpty && !isValidPhone(emergencyPhone) {
            errors.append(.invalidEmergencyPhone)
        }
        
        validationErrors = errors
        isFormValid = errors.isEmpty
    }
    
    private func validateFullName() {
        // Real-time validation feedback for full name
        if !fullName.isEmpty && fullName.count < 2 {
            // Show inline error
        }
    }
    
    private func validateEmail() {
        // Real-time validation feedback for email
        if !email.isEmpty && !isValidEmail(email) {
            // Show inline error
        }
    }
    
    private func validatePhone() {
        // Real-time validation feedback for phone
        if !phone.isEmpty && !isValidPhone(phone) {
            // Show inline error
        }
    }
    
    private func validateEmergencyPhone() {
        // Real-time validation feedback for emergency phone
        if !emergencyPhone.isEmpty && !isValidPhone(emergencyPhone) {
            // Show inline error
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^\\+?[1-9]\\d{1,14}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone)
    }
    
    private func validateFormData() throws {
        if !isFormValid {
            throw ProfileError.invalidFormData(validationErrors)
        }
    }
    
    private func validatePasswordChange(current: String, new: String, confirm: String) throws {
        if current.isEmpty {
            throw ProfileError.emptyCurrentPassword
        }
        
        if new.isEmpty {
            throw ProfileError.emptyNewPassword
        }
        
        if new.count < 8 {
            throw ProfileError.passwordTooShort
        }
        
        if new != confirm {
            throw ProfileError.passwordMismatch
        }
        
        // Check password strength
        if !isStrongPassword(new) {
            throw ProfileError.weakPassword
        }
    }
    
    private func isStrongPassword(_ password: String) -> Bool {
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasDigit = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil
        
        return hasUppercase && hasLowercase && hasDigit && hasSpecial
    }
    
    private func createUpdatedUser(from currentUser: User) -> User {
        var updatedUser = currentUser
        updatedUser.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedUser.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedUser.phone = phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedUser.updatedAt = Date()
        
        return updatedUser
    }
    
    private func loadUserPreferences() async throws -> UserPreferences {
        // Implementation to load user preferences from database
        // For now, return default preferences
        return UserPreferences()
    }
    
    private func saveUserPreferences() async throws {
        // Implementation to save user preferences to database
        try await supabaseService.saveUserPreferences(preferences)
    }
    
    private func loadAdminSettings() async {
        // Load admin-specific settings
        do {
            adminSettings = try await supabaseService.getAdminSettings()
        } catch {
            logger.error("Failed to load admin settings: \(error)")
        }
    }
    
    private func saveAdminSettings() async throws {
        try await supabaseService.updateAdminSettings(adminSettings)
    }
    
    private func optimizeImage(_ image: UIImage) -> UIImage {
        let maxSize: CGFloat = 1024
        let size = image.size
        
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if aspectRatio > 1 {
            // Landscape
            newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            // Portrait or square
            newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func handleError(_ error: Error, operation: String) async {
        logger.error("Failed to \(operation): \(error)")
        
        let errorMessage: String
        let suggestion: String
        let canRetry: Bool
        
        switch error {
        case ProfileError.noCurrentUser:
            errorMessage = "No hay usuario autenticado"
            suggestion = "Por favor, inicia sesión nuevamente"
            canRetry = false
            
        case ProfileError.invalidFormData(let validationErrors):
            errorMessage = "Datos inválidos en el formulario"
            suggestion = validationErrors.map { $0.description }.joined(separator: "\n")
            canRetry = false
            
        case ProfileError.networkError:
            errorMessage = "Error de conexión"
            suggestion = "Verifica tu conexión a internet e intenta nuevamente"
            canRetry = true
            
        case ProfileError.imageTooLarge:
            errorMessage = "La imagen es demasiado grande"
            suggestion = "Selecciona una imagen menor a 5MB"
            canRetry = false
            
        default:
            errorMessage = "Error inesperado"
            suggestion = "Intenta nuevamente o contacta con soporte"
            canRetry = true
        }
        
        errorState = .operationFailed(
            operation: operation,
            message: errorMessage,
            suggestion: suggestion,
            canRetry: canRetry
        )
    }
    
    private func debouncedSave() {
        saveDebouncer?.invalidate()
        saveDebouncer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.saveProfile()
        }
    }
    
    private func shareExportedData(_ data: Data) async {
        // Implementation to share exported data
        // This would typically show a share sheet
    }
    
    private func showDeleteConfirmation() async -> Bool {
        // Implementation to show confirmation dialog
        // For now, return false as safety measure
        return false
    }
    
    private func clearUserData() {
        user = nil
        fullName = ""
        email = ""
        phone = ""
        emergencyContact = ""
        emergencyPhone = ""
        preferences = UserPreferences()
        isAdmin = false
        adminSettings = AdminSettings()
        validationErrors = []
        isFormValid = false
        errorState = nil
        successMessage = nil
    }
    
    private func clearAllUserData() {
        clearUserData()
        
        // Clear any cached data
        Task {
            await CacheManager.shared.clearAllCache()
        }
        
        // Clear secure values
        securityManager.clearAllSecureValues()
    }
}

// MARK: - Supporting Types

struct AdminSettings: Codable {
    var lastSecurityAudit: Date?
    var securityIssuesCount: Int = 0
    var systemMaintenanceMode: Bool = false
    var debugLoggingEnabled: Bool = false
}

enum ValidationError: Error, CustomStringConvertible {
    case emptyFullName
    case fullNameTooShort
    case invalidEmail
    case invalidPhone
    case invalidEmergencyPhone
    
    var description: String {
        switch self {
        case .emptyFullName:
            return "El nombre completo es requerido"
        case .fullNameTooShort:
            return "El nombre debe tener al menos 2 caracteres"
        case .invalidEmail:
            return "Email inválido"
        case .invalidPhone:
            return "Número de teléfono inválido"
        case .invalidEmergencyPhone:
            return "Número de emergencia inválido"
        }
    }
}

enum ProfileError: Error, LocalizedError {
    case noCurrentUser
    case invalidFormData([ValidationError])
    case networkError
    case imageProcessingFailed
    case imageTooLarge
    case emptyCurrentPassword
    case emptyNewPassword
    case passwordTooShort
    case passwordMismatch
    case weakPassword
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No hay usuario autenticado"
        case .invalidFormData:
            return "Datos del formulario inválidos"
        case .networkError:
            return "Error de red"
        case .imageProcessingFailed:
            return "Error al procesar imagen"
        case .imageTooLarge:
            return "Imagen demasiado grande"
        case .emptyCurrentPassword:
            return "Contraseña actual requerida"
        case .emptyNewPassword:
            return "Nueva contraseña requerida"
        case .passwordTooShort:
            return "Contraseña debe tener al menos 8 caracteres"
        case .passwordMismatch:
            return "Las contraseñas no coinciden"
        case .weakPassword:
            return "Contraseña debe incluir mayúscula, minúscula, número y carácter especial"
        }
    }
}

enum ProfileErrorState {
    case operationFailed(operation: String, message: String, suggestion: String, canRetry: Bool)
    case securityAuditFailed([String])
    
    var title: String {
        switch self {
        case .operationFailed(let operation, _, _, _):
            return "Error al \(operation)"
        case .securityAuditFailed:
            return "Problemas de seguridad detectados"
        }
    }
    
    var message: String {
        switch self {
        case .operationFailed(_, let message, _, _):
            return message
        case .securityAuditFailed(let issues):
            return issues.joined(separator: "\n")
        }
    }
}