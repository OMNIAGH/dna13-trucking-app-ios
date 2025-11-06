//
//  QueryOptimizer.swift
//  DNA13TruckingApp
//
//  Optimizador de consultas de base de datos para mejorar performance
//  y reducir el tiempo de respuesta de las queries
//

import Foundation
import OSLog

class QueryOptimizer {
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.dna13trucking.app", category: "QueryOptimizer")
    
    // MARK: - Query Building
    
    /// Construir query optimizada para estadísticas del dashboard
    func buildDashboardStatsQuery(userId: UUID) -> OptimizedQuery {
        // Use materialized view for better performance
        let selectClause = """
            user_id,
            total_loads,
            active_loads,
            completed_loads_today,
            pending_loads,
            current_location,
            fuel_level,
            maintenance_alerts_count as maintenance_alerts
        """
        
        let fromClause = "dashboard_statistics_view"
        let whereClause = "user_id = '\(userId.uuidString)'"
        
        return OptimizedQuery(
            selectClause: selectClause,
            fromClause: fromClause,
            whereClause: whereClause,
            orderClause: nil,
            limitClause: "1",
            performance: .high,
            cacheKey: "dashboard_stats_\(userId.uuidString)",
            estimatedExecutionTime: 0.05
        )
    }
    
    /// Construir query para próximas entregas con optimización de joins
    func buildNextDeliveryQuery(userId: UUID) -> OptimizedQuery {
        let selectClause = """
            l.id,
            l.customer_name,
            l.destination_address,
            l.delivery_date,
            l.priority,
            l.rate,
            l.status
        """
        
        let fromClause = """
            loads l
            INNER JOIN vehicles v ON l.assigned_vehicle_id = v.id
        """
        
        let whereClause = """
            v.assigned_driver_id = '\(userId.uuidString)'
            AND l.status IN ('assigned', 'picked_up', 'in_transit')
            AND l.delivery_date >= NOW()
        """
        
        let orderClause = "l.delivery_date ASC"
        
        return OptimizedQuery(
            selectClause: selectClause,
            fromClause: fromClause,
            whereClause: whereClause,
            orderClause: orderClause,
            limitClause: "1",
            performance: .medium,
            cacheKey: "next_delivery_\(userId.uuidString)",
            estimatedExecutionTime: 0.15
        )
    }
    
    /// Construir query para alertas con paginación optimizada
    func buildAlertsQuery(userId: UUID, limit: Int, onlyUnread: Bool) -> OptimizedQuery {
        let selectClause = """
            id,
            title,
            message,
            type,
            priority,
            created_at,
            is_read
        """
        
        let fromClause = "notifications"
        
        var whereConditions = ["user_id = '\(userId.uuidString)'"]
        if onlyUnread {
            whereConditions.append("is_read = false")
        }
        
        let whereClause = whereConditions.joined(separator: " AND ")
        let orderClause = "created_at DESC"
        
        return OptimizedQuery(
            selectClause: selectClause,
            fromClause: fromClause,
            whereClause: whereClause,
            orderClause: orderClause,
            limitClause: "\(limit)",
            performance: .medium,
            cacheKey: "alerts_\(userId.uuidString)_\(onlyUnread)_\(limit)",
            estimatedExecutionTime: 0.10
        )
    }
    
    /// Construir query para ganancias con agregaciones optimizadas
    func buildEarningsQuery(userId: UUID) -> OptimizedQuery {
        let selectClause = """
            SUM(CASE 
                WHEN l.delivery_date >= date_trunc('week', CURRENT_DATE) 
                THEN l.rate ELSE 0 
            END) as weekly_earnings,
            SUM(CASE 
                WHEN l.delivery_date >= date_trunc('month', CURRENT_DATE) 
                THEN l.rate ELSE 0 
            END) as monthly_earnings,
            SUM(CASE 
                WHEN l.delivery_date >= date_trunc('year', CURRENT_DATE) 
                THEN l.rate ELSE 0 
            END) as yearly_earnings
        """
        
        let fromClause = """
            loads l
            INNER JOIN vehicles v ON l.assigned_vehicle_id = v.id
        """
        
        let whereClause = """
            v.assigned_driver_id = '\(userId.uuidString)'
            AND l.status = 'completed'
            AND l.delivery_date >= date_trunc('year', CURRENT_DATE)
        """
        
        return OptimizedQuery(
            selectClause: selectClause,
            fromClause: fromClause,
            whereClause: whereClause,
            orderClause: nil,
            limitClause: nil,
            performance: .low, // Aggregation queries are typically slower
            cacheKey: "earnings_\(userId.uuidString)",
            estimatedExecutionTime: 0.30
        )
    }
    
    /// Construir query batch para múltiples inserts
    func buildBatchInsertQuery(table: String, records: [[String: Any]], conflictResolution: ConflictResolution = .ignore) -> BatchQuery {
        let columns = Array(records.first?.keys ?? [])
        let columnsList = columns.joined(separator: ", ")
        
        var valueRows: [String] = []
        for record in records {
            let values = columns.map { column -> String in
                if let value = record[column] {
                    return formatValue(value)
                } else {
                    return "NULL"
                }
            }
            valueRows.append("(\(values.joined(separator: ", ")))")
        }
        
        let valuesClause = valueRows.joined(separator: ", ")
        
        var conflictClause = ""
        switch conflictResolution {
        case .ignore:
            conflictClause = "ON CONFLICT DO NOTHING"
        case .update(let updateColumns):
            let updateList = updateColumns.map { "\($0) = EXCLUDED.\($0)" }.joined(separator: ", ")
            conflictClause = "ON CONFLICT DO UPDATE SET \(updateList)"
        case .replace:
            conflictClause = "ON CONFLICT DO UPDATE SET " + columns.map { "\($0) = EXCLUDED.\($0)" }.joined(separator: ", ")
        }
        
        let query = """
            INSERT INTO \(table) (\(columnsList))
            VALUES \(valuesClause)
            \(conflictClause)
        """
        
        return BatchQuery(
            query: query,
            recordCount: records.count,
            estimatedExecutionTime: Double(records.count) * 0.01,
            batchSize: records.count
        )
    }
    
    // MARK: - Query Analysis
    
    /// Analizar performance de una query
    func analyzeQueryPerformance(_ query: String) -> QueryAnalysis {
        var suggestions: [String] = []
        var estimatedPerformance: QueryPerformance = .medium
        
        let queryLower = query.lowercased()
        
        // Check for potential performance issues
        if queryLower.contains("select *") {
            suggestions.append("Evitar SELECT * - especificar columnas necesarias")
            estimatedPerformance = .low
        }
        
        if queryLower.contains("like '%") && queryLower.contains("%'") {
            suggestions.append("Evitar LIKE con wildcards al inicio - usar índices de texto completo")
            estimatedPerformance = .low
        }
        
        if queryLower.contains("order by") && !queryLower.contains("limit") {
            suggestions.append("Considerar agregar LIMIT para queries con ORDER BY")
        }
        
        if queryLower.contains("distinct") && queryLower.contains("order by") {
            suggestions.append("DISTINCT con ORDER BY puede ser costoso - considerar alternativas")
            estimatedPerformance = .low
        }
        
        // Check for good practices
        if queryLower.contains("inner join") {
            suggestions.append("Buen uso de INNER JOIN para mejor performance")
        }
        
        if queryLower.contains("limit") {
            suggestions.append("Buen uso de LIMIT para controlar resultados")
        }
        
        // Estimate complexity
        let joinCount = queryLower.components(separatedBy: "join").count - 1
        let whereConditions = queryLower.components(separatedBy: "and").count + queryLower.components(separatedBy: "or").count - 1
        
        let complexity: QueryComplexity
        if joinCount > 3 || whereConditions > 5 {
            complexity = .high
        } else if joinCount > 1 || whereConditions > 2 {
            complexity = .medium
        } else {
            complexity = .low
        }
        
        return QueryAnalysis(
            estimatedPerformance: estimatedPerformance,
            complexity: complexity,
            suggestions: suggestions,
            joinCount: joinCount,
            whereConditionsCount: whereConditions
        )
    }
    
    /// Sugerir índices para optimizar queries
    func suggestIndexes(for query: String, table: String) -> [IndexSuggestion] {
        var suggestions: [IndexSuggestion] = []
        let queryLower = query.lowercased()
        
        // Analyze WHERE conditions
        let wherePattern = #"where\s+(.+?)(?:order\s+by|group\s+by|limit|$)"#
        if let regex = try? NSRegularExpression(pattern: wherePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)) {
            
            let whereClause = String(query[Range(match.range(at: 1), in: query)!])
            
            // Extract column names from WHERE conditions
            let columnPattern = #"(\w+)\s*[=<>!]"#
            if let columnRegex = try? NSRegularExpression(pattern: columnPattern) {
                let matches = columnRegex.matches(in: whereClause, range: NSRange(whereClause.startIndex..., in: whereClause))
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: whereClause) {
                        let column = String(whereClause[range])
                        
                        suggestions.append(IndexSuggestion(
                            table: table,
                            columns: [column],
                            type: .btree,
                            reason: "Columna usada en WHERE clause",
                            estimatedImprovement: 0.30
                        ))
                    }
                }
            }
        }
        
        // Analyze ORDER BY
        if queryLower.contains("order by") {
            let orderPattern = #"order\s+by\s+(\w+)"#
            if let regex = try? NSRegularExpression(pattern: orderPattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)) {
                
                let column = String(query[Range(match.range(at: 1), in: query)!])
                
                suggestions.append(IndexSuggestion(
                    table: table,
                    columns: [column],
                    type: .btree,
                    reason: "Columna usada en ORDER BY",
                    estimatedImprovement: 0.25
                ))
            }
        }
        
        return suggestions
    }
    
    // MARK: - Private Helpers
    
    private func formatValue(_ value: Any) -> String {
        switch value {
        case let string as String:
            return "'\(string.replacingOccurrences(of: "'", with: "''"))'"
        case let number as NSNumber:
            return number.stringValue
        case let date as Date:
            return "'\(ISO8601DateFormatter().string(from: date))'"
        case is NSNull:
            return "NULL"
        default:
            return "'\(String(describing: value))'"
        }
    }
}

// MARK: - Supporting Types

struct OptimizedQuery {
    let selectClause: String
    let fromClause: String
    let whereClause: String?
    let orderClause: String?
    let limitClause: String?
    let performance: QueryPerformance
    let cacheKey: String
    let estimatedExecutionTime: TimeInterval
    
    var fullQuery: String {
        var query = "SELECT \(selectClause) FROM \(fromClause)"
        
        if let whereClause = whereClause {
            query += " WHERE \(whereClause)"
        }
        
        if let orderClause = orderClause {
            query += " ORDER BY \(orderClause)"
        }
        
        if let limitClause = limitClause {
            query += " LIMIT \(limitClause)"
        }
        
        return query
    }
}

struct BatchQuery {
    let query: String
    let recordCount: Int
    let estimatedExecutionTime: TimeInterval
    let batchSize: Int
}

struct QueryAnalysis {
    let estimatedPerformance: QueryPerformance
    let complexity: QueryComplexity
    let suggestions: [String]
    let joinCount: Int
    let whereConditionsCount: Int
}

struct IndexSuggestion {
    let table: String
    let columns: [String]
    let type: IndexType
    let reason: String
    let estimatedImprovement: Double // 0.0 to 1.0
    
    var createStatement: String {
        let indexName = "idx_\(table)_\(columns.joined(separator: "_"))"
        let columnsList = columns.joined(separator: ", ")
        
        switch type {
        case .btree:
            return "CREATE INDEX \(indexName) ON \(table) (\(columnsList))"
        case .hash:
            return "CREATE INDEX \(indexName) ON \(table) USING HASH (\(columnsList))"
        case .gin:
            return "CREATE INDEX \(indexName) ON \(table) USING GIN (\(columnsList))"
        case .gist:
            return "CREATE INDEX \(indexName) ON \(table) USING GIST (\(columnsList))"
        }
    }
}

enum QueryPerformance {
    case high    // < 50ms
    case medium  // 50ms - 200ms
    case low     // > 200ms
    
    var description: String {
        switch self {
        case .high: return "Alta"
        case .medium: return "Media"
        case .low: return "Baja"
        }
    }
}

enum QueryComplexity {
    case low
    case medium
    case high
    
    var description: String {
        switch self {
        case .low: return "Baja"
        case .medium: return "Media"
        case .high: return "Alta"
        }
    }
}

enum IndexType {
    case btree
    case hash
    case gin
    case gist
}

enum ConflictResolution {
    case ignore
    case update([String]) // columns to update
    case replace
}