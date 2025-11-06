//
//  CRMViewModel.swift
//  DNA13TruckingApp
//
//  ViewModel para la vista de CRM y métricas
//

import Foundation
import SwiftUI
import Combine

class CRMViewModel: ObservableObject {
    @Published var metrics: CRMMetrics = CRMMetrics()
    @Published var isLoading: Bool = false
    @Published var selectedPeriod: TimePeriod = .thisMonth
    @Published var fuelEfficiency: [FuelEfficiencyData] = []
    @Published var revenueData: [RevenueData] = []
    @Published var performanceData: [PerformanceData] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let supabaseService = SupabaseService.shared
    
    init() {
        loadMetrics()
        setupPeriodObserver()
    }
    
    private func setupPeriodObserver() {
        $selectedPeriod
            .sink { [weak self] period in
                Task {
                    await self?.loadMetricsForPeriod(period)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadMetrics() {
        isLoading = true
        
        Task {
            await loadMetricsForPeriod(selectedPeriod)
        }
    }
    
    private func loadMetricsForPeriod(_ period: TimePeriod) async {
        do {
            let (metrics, fuel, revenue, performance) = try await supabaseService.getCRMMetrics(
                period: period
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.metrics = metrics
                self?.fuelEfficiency = fuel
                self?.revenueData = revenue
                self?.performanceData = performance
                self?.isLoading = false
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                // TODO: Manejar error
            }
        }
    }
    
    func exportReport() async throws {
        try await supabaseService.exportCRMReport(period: selectedPeriod)
    }
    
    func getTopPerformingRoutes() -> [RoutePerformance] {
        return performanceData
            .sorted { $0.efficiencyScore > $1.efficiencyScore }
            .prefix(5)
            .map { RoutePerformance(
                origin: $0.origin,
                destination: $0.destination,
                efficiencyScore: $0.efficiencyScore,
                totalTrips: $0.totalTrips,
                averageMPG: $0.averageMPG
            )}
    }
    
    func getFuelTrends() -> [FuelTrend] {
        return fuelEfficiency.map { FuelTrend(
            date: $0.date,
            mpg: $0.mpg,
            cost: $0.cost,
            gallons: $0.gallons
        )}
    }
    
    func getRevenueBreakdown() -> RevenueBreakdown {
        let totalRevenue = revenueData.reduce(0.0) { $0 + $1.amount }
        let totalMiles = metrics.totalMiles
        let avgRevenuePerMile = totalMiles > 0 ? totalRevenue / totalMiles : 0
        
        return RevenueBreakdown(
            totalRevenue: totalRevenue,
            totalMiles: totalMiles,
            revenuePerMile: avgRevenuePerMile,
            topRoutes: getTopPerformingRoutes()
        )
    }
    
    func getMonthlyComparison() -> MonthlyComparison {
        let current = metrics
        // TODO: Calcular comparación con mes anterior
        return MonthlyComparison(
            revenueChange: 0.0,
            mileageChange: 0.0,
            efficiencyChange: 0.0,
            tripsChange: 0
        )
    }
}

// MARK: - CRM Metrics
struct CRMMetrics: Codable {
    var totalMiles: Double = 0
    var totalTrips: Int = 0
    var totalRevenue: Double = 0
    var totalFuelCost: Double = 0
    var averageMPG: Double = 0
    var totalDeductions: Double = 0
    var netIncome: Double = 0
    var onTimeDeliveries: Int = 0
    var safetyScore: Double = 0
    var efficiencyScore: Double = 0
}

// MARK: - Time Period
enum TimePeriod: String, CaseIterable, Identifiable {
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case lastMonth = "last_month"
    case thisQuarter = "this_quarter"
    case thisYear = "this_year"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .thisWeek:
            return "Esta Semana"
        case .thisMonth:
            return "Este Mes"
        case .lastMonth:
            return "Mes Pasado"
        case .thisQuarter:
            return "Este Trimestre"
        case .thisYear:
            return "Este Año"
        case .custom:
            return "Personalizado"
        }
    }
    
    var dateRange: (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (startOfWeek, now)
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (startOfMonth, now)
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            let startOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? lastMonth
            let endOfLastMonth = calendar.dateInterval(of: .month, for: lastMonth)?.end ?? lastMonth
            return (startOfLastMonth, endOfLastMonth)
        case .thisQuarter:
            let startOfQuarter = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
            return (startOfQuarter, now)
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return (startOfYear, now)
        case .custom:
            return (now, now)
        }
    }
}

// MARK: - Fuel Efficiency Data
struct FuelEfficiencyData: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let mpg: Double
    let cost: Double
    let gallons: Double
    let miles: Double
}

// MARK: - Revenue Data
struct RevenueData: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    let miles: Double
    let trips: Int
}

// MARK: - Performance Data
struct PerformanceData: Codable, Identifiable {
    let id = UUID()
    let origin: String
    let destination: String
    let totalTrips: Int
    let averageMPG: Double
    let averageTime: Double
    let efficiencyScore: Double
}

// MARK: - Route Performance
struct RoutePerformance: Identifiable {
    let id = UUID()
    let origin: String
    let destination: String
    let efficiencyScore: Double
    let totalTrips: Int
    let averageMPG: Double
}

// MARK: - Fuel Trend
struct FuelTrend: Identifiable {
    let id = UUID()
    let date: Date
    let mpg: Double
    let cost: Double
    let gallons: Double
}

// MARK: - Revenue Breakdown
struct RevenueBreakdown {
    let totalRevenue: Double
    let totalMiles: Double
    let revenuePerMile: Double
    let topRoutes: [RoutePerformance]
}

// MARK: - Monthly Comparison
struct MonthlyComparison {
    let revenueChange: Double
    let mileageChange: Double
    let efficiencyChange: Double
    let tripsChange: Int
    
    var revenueChangeFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter.string(from: NSNumber(value: revenueChange)) ?? "0%"
    }
    
    var mileageChangeFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter.string(from: NSNumber(value: mileageChange)) ?? "0%"
    }
    
    var efficiencyChangeFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter.string(from: NSNumber(value: efficiencyChange)) ?? "0%"
    }
    
    var tripsChangeFormatted: String {
        return "\(tripsChange > 0 ? "+" : "")\(tripsChange)"
    }
}

// MARK: - Performance Metrics
extension CRMViewModel {
    struct PerformanceMetrics {
        let safetyScore: Double
        let efficiencyScore: Double
        let onTimePercentage: Double
        let averageSpeed: Double
        let idleTime: Double
    }
    
    func getPerformanceMetrics() -> PerformanceMetrics {
        return PerformanceMetrics(
            safetyScore: metrics.safetyScore,
            efficiencyScore: metrics.efficiencyScore,
            onTimePercentage: metrics.totalTrips > 0 ? Double(metrics.onTimeDeliveries) / Double(metrics.totalTrips) * 100 : 0,
            averageSpeed: 55.0, // TODO: Calcular desde datos reales
            idleTime: 15.0 // TODO: Calcular desde datos reales
        )
    }
}