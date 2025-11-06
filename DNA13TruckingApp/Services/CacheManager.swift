//
//  CacheManager.swift
//  DNA13TruckingApp
//
//  Gestor de cache inteligente para mejorar performance y reducir llamadas a la base de datos
//

import Foundation
import OSLog

@MainActor
class CacheManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CacheManager()
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.dna13trucking.app", category: "CacheManager")
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var memoryCache: NSCache<NSString, CacheItem> = NSCache()
    private var cacheMetadata: [String: CacheMetadata] = [:]
    private let maxMemoryCacheSize: Int = 50 * 1024 * 1024 // 50MB
    private let maxDiskCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    
    private lazy var cacheDirectory: URL = {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let cacheDir = documentsPath.appendingPathComponent("AppCache")
        
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        
        return cacheDir
    }()
    
    // MARK: - Initialization
    private init() {
        setupCache()
        setupCacheCleaning()
        loadCacheMetadata()
    }
    
    // MARK: - Public Methods
    
    /// Guardar objeto en cache con tiempo de expiración
    func setCachedObject<T: Codable>(_ object: T, for key: String, expiration: CacheExpiration = .minutes(10)) async {
        do {
            let data = try encoder.encode(object)
            let expirationDate = expiration.date
            
            // Store in memory cache
            let cacheItem = CacheItem(data: data, expirationDate: expirationDate)
            memoryCache.setObject(cacheItem, forKey: NSString(string: key))
            
            // Store in disk cache for persistence
            await saveToDiskCache(data: data, key: key, expirationDate: expirationDate)
            
            // Update metadata
            cacheMetadata[key] = CacheMetadata(
                size: data.count,
                lastAccessed: Date(),
                expirationDate: expirationDate,
                hitCount: 0
            )
            
            await saveCacheMetadata()
            
            logger.debug("Cached object for key: \(key) (size: \(data.count) bytes)")
            
        } catch {
            logger.error("Failed to cache object for key \(key): \(error)")
        }
    }
    
    /// Obtener objeto del cache
    func getCachedObject<T: Codable>(for key: String, type: T.Type) async -> T? {
        // Update access time
        cacheMetadata[key]?.lastAccessed = Date()
        cacheMetadata[key]?.hitCount += 1
        
        // Try memory cache first
        if let cacheItem = memoryCache.object(forKey: NSString(string: key)) {
            if cacheItem.isValid {
                do {
                    let object = try decoder.decode(type, from: cacheItem.data)
                    logger.debug("Cache hit (memory) for key: \(key)")
                    return object
                } catch {
                    logger.error("Failed to decode cached object for key \(key): \(error)")
                    removeCachedObject(for: key)
                }
            } else {
                // Expired, remove from memory
                memoryCache.removeObject(forKey: NSString(string: key))
            }
        }
        
        // Try disk cache
        if let data = await loadFromDiskCache(key: key) {
            do {
                let object = try decoder.decode(type, from: data)
                
                // Also store back in memory cache
                if let metadata = cacheMetadata[key] {
                    let cacheItem = CacheItem(data: data, expirationDate: metadata.expirationDate)
                    memoryCache.setObject(cacheItem, forKey: NSString(string: key))
                }
                
                logger.debug("Cache hit (disk) for key: \(key)")
                return object
                
            } catch {
                logger.error("Failed to decode disk cached object for key \(key): \(error)")
                removeCachedObject(for: key)
            }
        }
        
        logger.debug("Cache miss for key: \(key)")
        return nil
    }
    
    /// Verificar si un objeto está en cache y es válido
    func isCached(key: String) -> Bool {
        if let cacheItem = memoryCache.object(forKey: NSString(string: key)) {
            return cacheItem.isValid
        }
        
        if let metadata = cacheMetadata[key] {
            return metadata.expirationDate > Date()
        }
        
        return false
    }
    
    /// Remover objeto específico del cache
    func removeCachedObject(for key: String) {
        memoryCache.removeObject(forKey: NSString(string: key))
        
        let diskPath = cacheDirectory.appendingPathComponent("\(key).cache")
        try? fileManager.removeItem(at: diskPath)
        
        cacheMetadata.removeValue(forKey: key)
        
        Task {
            await saveCacheMetadata()
        }
        
        logger.debug("Removed cached object for key: \(key)")
    }
    
    /// Limpiar todo el cache
    func clearAllCache() async {
        memoryCache.removeAllObjects()
        
        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in cacheFiles {
                try fileManager.removeItem(at: file)
            }
        } catch {
            logger.error("Failed to clear disk cache: \(error)")
        }
        
        cacheMetadata.removeAll()
        await saveCacheMetadata()
        
        logger.info("Cleared all cache")
    }
    
    /// Limpiar cache expirado
    func cleanupExpiredCache() async {
        let now = Date()
        var keysToRemove: [String] = []
        
        // Find expired items
        for (key, metadata) in cacheMetadata {
            if metadata.expirationDate <= now {
                keysToRemove.append(key)
            }
        }
        
        // Remove expired items
        for key in keysToRemove {
            removeCachedObject(for: key)
        }
        
        // Also clean up memory cache
        memoryCache.removeAllObjects()
        
        logger.info("Cleaned up \(keysToRemove.count) expired cache items")
    }
    
    /// Obtener estadísticas del cache
    func getCacheStatistics() -> CacheStatistics {
        let totalItems = cacheMetadata.count
        let totalMemorySize = memoryCache.totalCostLimit
        
        var totalDiskSize: Int64 = 0
        var hitCount: Int = 0
        
        for metadata in cacheMetadata.values {
            totalDiskSize += Int64(metadata.size)
            hitCount += metadata.hitCount
        }
        
        return CacheStatistics(
            totalItems: totalItems,
            memorySize: totalMemorySize,
            diskSize: totalDiskSize,
            totalHits: hitCount,
            hitRate: totalItems > 0 ? Double(hitCount) / Double(totalItems) : 0.0
        )
    }
    
    /// Obtener tiempo de último cache para una key
    func getLastCacheTime(for key: String) -> Date? {
        return cacheMetadata[key]?.lastAccessed
    }
    
    // MARK: - Private Methods
    
    private func setupCache() {
        // Configure memory cache
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 1000 // Max 1000 items in memory
        
        // Setup date formatters
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    private func setupCacheCleaning() {
        // Clean expired cache every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { await self?.cleanupExpiredCache() }
        }
        
        // Clean cache when app moves to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.cleanupExpiredCache() }
        }
    }
    
    private func saveToDiskCache(data: Data, key: String, expirationDate: Date) async {
        let diskPath = cacheDirectory.appendingPathComponent("\(key).cache")
        
        do {
            try data.write(to: diskPath)
            
            // Set file attributes for expiration tracking
            try fileManager.setAttributes([
                .modificationDate: expirationDate
            ], ofItemAtPath: diskPath.path)
            
        } catch {
            logger.error("Failed to save to disk cache for key \(key): \(error)")
        }
    }
    
    private func loadFromDiskCache(key: String) async -> Data? {
        let diskPath = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard fileManager.fileExists(atPath: diskPath.path) else {
            return nil
        }
        
        do {
            // Check if file is expired
            let attributes = try fileManager.attributesOfItem(atPath: diskPath.path)
            if let modificationDate = attributes[.modificationDate] as? Date,
               modificationDate <= Date() {
                // File is expired, remove it
                try fileManager.removeItem(at: diskPath)
                return nil
            }
            
            return try Data(contentsOf: diskPath)
            
        } catch {
            logger.error("Failed to load from disk cache for key \(key): \(error)")
            return nil
        }
    }
    
    private func loadCacheMetadata() {
        let metadataPath = cacheDirectory.appendingPathComponent("metadata.json")
        
        guard fileManager.fileExists(atPath: metadataPath.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: metadataPath)
            cacheMetadata = try decoder.decode([String: CacheMetadata].self, from: data)
        } catch {
            logger.error("Failed to load cache metadata: \(error)")
        }
    }
    
    private func saveCacheMetadata() async {
        let metadataPath = cacheDirectory.appendingPathComponent("metadata.json")
        
        do {
            let data = try encoder.encode(cacheMetadata)
            try data.write(to: metadataPath)
        } catch {
            logger.error("Failed to save cache metadata: \(error)")
        }
    }
}

// MARK: - Supporting Types

class CacheItem: NSObject {
    let data: Data
    let expirationDate: Date
    
    init(data: Data, expirationDate: Date) {
        self.data = data
        self.expirationDate = expirationDate
        super.init()
    }
    
    var isValid: Bool {
        return expirationDate > Date()
    }
}

struct CacheMetadata: Codable {
    let size: Int
    var lastAccessed: Date
    let expirationDate: Date
    var hitCount: Int
}

enum CacheExpiration {
    case minutes(Int)
    case hours(Int)
    case days(Int)
    case custom(Date)
    
    var date: Date {
        let now = Date()
        switch self {
        case .minutes(let minutes):
            return Calendar.current.date(byAdding: .minute, value: minutes, to: now) ?? now
        case .hours(let hours):
            return Calendar.current.date(byAdding: .hour, value: hours, to: now) ?? now
        case .days(let days):
            return Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        case .custom(let date):
            return date
        }
    }
}

struct CacheStatistics {
    let totalItems: Int
    let memorySize: Int
    let diskSize: Int64
    let totalHits: Int
    let hitRate: Double
    
    var formattedMemorySize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(memorySize), countStyle: .memory)
    }
    
    var formattedDiskSize: String {
        return ByteCountFormatter.string(fromByteCount: diskSize, countStyle: .file)
    }
}