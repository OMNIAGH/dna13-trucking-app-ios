//
//  AlertsViewModel.swift
//  DNA13TruckingApp
//
//  ViewModel para la vista de alertas
//

import Foundation
import SwiftUI
import Combine

class AlertsViewModel: ObservableObject {
    @Published var alerts: [Notification] = []
    @Published var isLoading: Bool = false
    @Published var selectedAlertType: AlertTypeFilter = .all
    @Published var unreadCount: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let supabaseService = SupabaseService.shared
    
    init() {
        loadAlerts()
        setupAutoRefresh()
    }
    
    private func setupAutoRefresh() {
        // Actualizar alertas cada 5 minutos
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.loadAlerts()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadAlerts() async {
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
        }
        
        do {
            let alerts = try await supabaseService.getNotifications()
            
            DispatchQueue.main.async { [weak self] in
                self?.alerts = alerts
                self?.unreadCount = alerts.filter { !$0.isRead }.count
                self?.isLoading = false
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
                // TODO: Mostrar error
            }
        }
    }
    
    func markAsRead(_ alert: Notification) {
        Task {
            do {
                try await supabaseService.markNotificationAsRead(alertId: alert.id)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    if let index = self.alerts.firstIndex(where: { $0.id == alert.id }) {
                        self.alerts[index].readAt = Date()
                        self.unreadCount = self.alerts.filter { !$0.isRead }.count
                    }
                }
            } catch {
                // TODO: Manejar error
            }
        }
    }
    
    func markAllAsRead() {
        Task {
            do {
                try await supabaseService.markAllNotificationsAsRead()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    let now = Date()
                    self.alerts.indices.forEach { index in
                        self.alerts[index].readAt = now
                    }
                    self.unreadCount = 0
                }
            } catch {
                // TODO: Manejar error
            }
        }
    }
    
    func deleteAlert(_ alert: Notification) {
        Task {
            do {
                try await supabaseService.deleteNotification(alertId: alert.id)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.alerts.removeAll { $0.id == alert.id }
                    self.unreadCount = self.alerts.filter { !$0.isRead }.count
                }
            } catch {
                // TODO: Manejar error
            }
        }
    }
    
    func filteredAlerts() -> [Notification] {
        switch selectedAlertType {
        case .all:
            return alerts
        case .unread:
            return alerts.filter { !$0.isRead }
        case .trip:
            return alerts.filter { $0.type == .tripCreated || $0.type == .tripUpdated || $0.type == .stopUpdate }
        case .compliance:
            return alerts.filter { $0.type == .complianceAlert }
        case .maintenance:
            return alerts.filter { $0.type == .maintenanceReminder }
        case .fuel:
            return alerts.filter { $0.type == .fuelAlert }
        case .weather:
            return alerts.filter { $0.type == .weatherAlert }
        case .traffic:
            return alerts.filter { $0.type == .trafficAlert }
        }
    }
    
    func getAlertsByPriority() -> [NotificationPriority: [Notification]] {
        let grouped = Dictionary(grouping: alerts) { $0.priority }
        return grouped
    }
    
    func getRecentAlerts(hours: Int = 24) -> [Notification] {
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        return alerts.filter { $0.createdAt >= cutoffDate }
    }
    
    func getOverdueAlerts() -> [Notification] {
        return alerts.filter { 
            $0.status == .pending && $0.createdAt < Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
        }
    }
    
    func requestRefresh() {
        Task {
            await loadAlerts()
        }
    }
}

// MARK: - Alert Type Filter
enum AlertTypeFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case unread = "unread"
    case trip = "trip"
    case compliance = "compliance"
    case maintenance = "maintenance"
    case fuel = "fuel"
    case weather = "weather"
    case traffic = "traffic"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all:
            return "Todas"
        case .unread:
            return "No Leídas"
        case .trip:
            return "Viajes"
        case .compliance:
            return "Cumplimiento"
        case .maintenance:
            return "Mantenimiento"
        case .fuel:
            return "Combustible"
        case .weather:
            return "Clima"
        case .traffic:
            return "Tráfico"
        }
    }
    
    var icon: String {
        switch self {
        case .all:
            return "bell"
        case .unread:
            return "bell.badge"
        case .trip:
            return "truck"
        case .compliance:
            return "exclamationmark.triangle"
        case .maintenance:
            return "wrench"
        case .fuel:
            return "fuelpump"
        case .weather:
            return "cloud.sun"
        case .traffic:
            return "car"
        }
    }
}

// MARK: - Alert Summary
extension AlertsViewModel {
    struct AlertSummary {
        let totalCount: Int
        let unreadCount: Int
        let urgentCount: Int
        let overdueCount: Int
        let recentCount: Int
        let byType: [String: Int]
    }
    
    func getAlertSummary() -> AlertSummary {
        let urgentCount = alerts.filter { $0.priority == .urgent }.count
        let overdueCount = getOverdueAlerts().count
        let recentCount = getRecentAlerts(hours: 24).count
        
        let byType = Dictionary(grouping: alerts) { $0.type.displayName }
            .mapValues { $0.count }
        
        return AlertSummary(
            totalCount: alerts.count,
            unreadCount: unreadCount,
            urgentCount: urgentCount,
            overdueCount: overdueCount,
            recentCount: recentCount,
            byType: byType
        )
    }
}