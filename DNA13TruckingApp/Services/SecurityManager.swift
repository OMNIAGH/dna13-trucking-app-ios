//
//  SecurityManager.swift
//  DNA13TruckingApp
//
//  Gestor de seguridad para encriptación, almacenamiento seguro de credenciales
//  y protección de datos sensibles
//

import Foundation
import Security
import CryptoKit
import OSLog

class SecurityManager {
    
    // MARK: - Singleton
    static let shared = SecurityManager()
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.dna13trucking.app", category: "SecurityManager")
    private let keychain = Keychain()
    private let encryptionKey: SymmetricKey
    
    // MARK: - Secure Values Keys
    enum SecureValueKey: String, CaseIterable {
        case supabaseURL = "supabase_url"
        case supabaseAnonKey = "supabase_anon_key"
        case supabaseServiceKey = "supabase_service_key"
        case googleMapsAPIKey = "google_maps_api_key"
        case openAIAPIKey = "openai_api_key"
        case userBiometricData = "user_biometric_data"
        case deviceSecret = "device_secret"
    }
    
    // MARK: - Initialization
    private init() {
        // Generate or retrieve encryption key
        if let existingKeyData = keychain.get("master_encryption_key") {
            self.encryptionKey = SymmetricKey(data: existingKeyData)
        } else {
            // Generate new key
            self.encryptionKey = SymmetricKey(size: .bits256)
            let keyData = encryptionKey.withUnsafeBytes { Data($0) }
            keychain.set(keyData, forKey: "master_encryption_key")
        }
        
        initializeDefaultSecureValues()
    }
    
    // MARK: - Public Methods
    
    /// Obtener valor seguro encriptado
    func getSecureValue(_ key: SecureValueKey) -> String {
        guard let encryptedData = keychain.get(key.rawValue) else {
            logger.warning("Secure value not found for key: \(key.rawValue)")
            return ""
        }
        
        do {
            let decryptedData = try decrypt(data: encryptedData)
            return String(data: decryptedData, encoding: .utf8) ?? ""
        } catch {
            logger.error("Failed to decrypt secure value for key \(key.rawValue): \(error)")
            return ""
        }
    }
    
    /// Establecer valor seguro encriptado
    func setSecureValue(_ value: String, for key: SecureValueKey) {
        guard let valueData = value.data(using: .utf8) else {
            logger.error("Failed to convert value to data for key: \(key.rawValue)")
            return
        }
        
        do {
            let encryptedData = try encrypt(data: valueData)
            keychain.set(encryptedData, forKey: key.rawValue)
            logger.debug("Successfully stored secure value for key: \(key.rawValue)")
        } catch {
            logger.error("Failed to encrypt and store secure value for key \(key.rawValue): \(error)")
        }
    }
    
    /// Eliminar valor seguro
    func removeSecureValue(for key: SecureValueKey) {
        keychain.delete(key.rawValue)
        logger.debug("Removed secure value for key: \(key.rawValue)")
    }
    
    /// Verificar si un valor seguro existe
    func hasSecureValue(for key: SecureValueKey) -> Bool {
        return keychain.get(key.rawValue) != nil
    }
    
    /// Encriptar datos sensibles
    func encryptSensitiveData(_ data: Data) throws -> Data {
        return try encrypt(data: data)
    }
    
    /// Desencriptar datos sensibles
    func decryptSensitiveData(_ encryptedData: Data) throws -> Data {
        return try decrypt(data: encryptedData)
    }
    
    /// Generar hash seguro para passwords
    func hashPassword(_ password: String, salt: Data? = nil) -> (hash: String, salt: Data) {
        let usedSalt = salt ?? generateSalt()
        let passwordData = Data(password.utf8)
        let saltedPassword = passwordData + usedSalt
        
        let hash = SHA256.hash(data: saltedPassword)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        return (hash: hashString, salt: usedSalt)
    }
    
    /// Verificar password hasheado
    func verifyPassword(_ password: String, hash: String, salt: Data) -> Bool {
        let computedHash = hashPassword(password, salt: salt).hash
        return computedHash == hash
    }
    
    /// Generar token seguro aleatorio
    func generateSecureToken(length: Int = 32) -> String {
        let bytes = (0..<length).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64EncodedString()
    }
    
    /// Validar integridad de datos
    func validateDataIntegrity(_ data: Data, signature: Data) -> Bool {
        let computedSignature = HMAC<SHA256>.authenticationCode(for: data, using: encryptionKey)
        return Data(computedSignature) == signature
    }
    
    /// Crear firma de integridad para datos
    func createDataSignature(_ data: Data) -> Data {
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: encryptionKey)
        return Data(signature)
    }
    
    /// Limpiar todos los valores seguros (para logout completo)
    func clearAllSecureValues() {
        for key in SecureValueKey.allCases {
            removeSecureValue(for: key)
        }
        logger.info("Cleared all secure values")
    }
    
    /// Rotar clave de encriptación
    func rotateEncryptionKey() throws {
        // Desencriptar todos los valores actuales
        var currentValues: [SecureValueKey: String] = [:]
        for key in SecureValueKey.allCases {
            if hasSecureValue(for: key) {
                currentValues[key] = getSecureValue(key)
            }
        }
        
        // Generar nueva clave
        let newKey = SymmetricKey(size: .bits256)
        let newKeyData = newKey.withUnsafeBytes { Data($0) }
        
        // Guardar nueva clave
        keychain.set(newKeyData, forKey: "master_encryption_key")
        
        // Re-encriptar todos los valores con la nueva clave
        for (key, value) in currentValues {
            setSecureValue(value, for: key)
        }
        
        logger.info("Successfully rotated encryption key")
    }
    
    /// Verificar integridad del keychain
    func verifyKeychainIntegrity() -> Bool {
        // Verificar que la clave maestra existe y es válida
        guard let keyData = keychain.get("master_encryption_key"),
              keyData.count == 32 else {
            logger.error("Master encryption key is invalid or missing")
            return false
        }
        
        // Verificar que podemos usar la clave para encriptar/desencriptar
        let testData = "integrity_test".data(using: .utf8)!
        do {
            let encrypted = try encrypt(data: testData)
            let decrypted = try decrypt(data: encrypted)
            
            return decrypted == testData
        } catch {
            logger.error("Keychain integrity check failed: \(error)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func encrypt(data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        return sealedBox.combined!
    }
    
    private func decrypt(data: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }
    
    private func generateSalt(length: Int = 16) -> Data {
        let bytes = (0..<length).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes)
    }
    
    private func initializeDefaultSecureValues() {
        // Solo establecer valores por defecto si no existen
        let defaultValues: [SecureValueKey: String] = [
            .supabaseURL: "https://athazapkqtozhjromuvn.supabase.co",
            .supabaseAnonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0aGF6YXBrcXRvemhqcm9tdXZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzOTM4MTksImV4cCI6MjA3Nzk2OTgxOX0.SthqTO_xfi83avhr3HVfRyKrlF_hrLOwVKt83uv-qNQ",
            .googleMapsAPIKey: "AIzaSyCO0kKndUNlmQi3B5mxy4dblg_8WYcuKuk"
        ]
        
        for (key, value) in defaultValues {
            if !hasSecureValue(for: key) {
                setSecureValue(value, for: key)
            }
        }
    }
}

// MARK: - Keychain Wrapper

private class Keychain {
    
    func set(_ data: Data, forKey key: String) {
        delete(key) // Remove any existing item
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Keychain set error: \(status)")
        }
    }
    
    func get(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return item as? Data
    }
    
    func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Security Audit

extension SecurityManager {
    
    /// Realizar auditoría de seguridad completa
    func performSecurityAudit() -> SecurityAuditResult {
        var issues: [SecurityIssue] = []
        var recommendations: [String] = []
        
        // Verificar integridad del keychain
        if !verifyKeychainIntegrity() {
            issues.append(.keychainCorrupted)
            recommendations.append("Reinicializar keychain y rotar claves")
        }
        
        // Verificar que existen todas las claves necesarias
        let requiredKeys: [SecureValueKey] = [.supabaseURL, .supabaseAnonKey, .googleMapsAPIKey]
        for key in requiredKeys {
            if !hasSecureValue(for: key) {
                issues.append(.missingSecureValue(key.rawValue))
                recommendations.append("Configurar valor seguro para \(key.rawValue)")
            }
        }
        
        // Verificar fortaleza de encriptación
        if encryptionKey.withUnsafeBytes({ Data($0) }).count < 32 {
            issues.append(.weakEncryption)
            recommendations.append("Actualizar a clave de encriptación de 256 bits")
        }
        
        let severity: SecurityAuditSeverity
        if issues.contains(where: { $0.isCritical }) {
            severity = .critical
        } else if !issues.isEmpty {
            severity = .warning
        } else {
            severity = .secure
        }
        
        return SecurityAuditResult(
            severity: severity,
            issues: issues,
            recommendations: recommendations,
            auditDate: Date()
        )
    }
}

// MARK: - Security Audit Types

struct SecurityAuditResult {
    let severity: SecurityAuditSeverity
    let issues: [SecurityIssue]
    let recommendations: [String]
    let auditDate: Date
}

enum SecurityAuditSeverity {
    case secure
    case warning
    case critical
    
    var description: String {
        switch self {
        case .secure: return "Seguro"
        case .warning: return "Advertencia"
        case .critical: return "Crítico"
        }
    }
}

enum SecurityIssue {
    case keychainCorrupted
    case missingSecureValue(String)
    case weakEncryption
    case expiredCertificate
    
    var isCritical: Bool {
        switch self {
        case .keychainCorrupted, .weakEncryption:
            return true
        case .missingSecureValue, .expiredCertificate:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .keychainCorrupted:
            return "Keychain corrupto o inaccesible"
        case .missingSecureValue(let key):
            return "Valor seguro faltante: \(key)"
        case .weakEncryption:
            return "Encriptación débil detectada"
        case .expiredCertificate:
            return "Certificado expirado"
        }
    }
}