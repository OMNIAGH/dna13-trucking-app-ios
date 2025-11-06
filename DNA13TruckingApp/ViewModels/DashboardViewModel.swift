import Foundation
import Combine
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var totalLoads: Int = 0
    @Published var activeLoads: Int = 0
    @Published var completedLoadsToday: Int = 0
    @Published var pendingLoads: Int = 0
    @Published var currentLocation: String = "En ruta"
    @Published var nextDelivery: DeliveryInfo?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Estadísticas de ganancias
    @Published var weeklyEarnings: Double = 0.0
    @Published var monthlyEarnings: Double = 0.0
    @Published var yearlyEarnings: Double = 0.0
    
    // Notificaciones y alertas
    @Published var recentAlerts: [Alert] = []
    @Published var unreadNotifications: Int = 0
    
    private let authManager: AuthManager
    private let supabaseService: SupabaseService
    private var cancellables = Set<AnyCancellable>()
    
    init(authManager: AuthManager = AuthManager.shared, supabaseService: SupabaseService = SupabaseService.shared) {
        self.authManager = authManager
        self.supabaseService = supabaseService
        
        // Cargar datos iniciales
        loadDashboardData()
    }
    
    func loadDashboardData() {
        isLoading = true
        
        // Simular carga de datos
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.updateStatistics()
            self.loadNextDelivery()
            self.loadRecentAlerts()
            self.isLoading = false
        }
    }
    
    private func updateStatistics() {
        // Aquí se cargarían las estadísticas reales desde la base de datos
        self.totalLoads = 45
        self.activeLoads = 3
        self.completedLoadsToday = 2
        self.pendingLoads = 5
        
        // Estadísticas de ganancias (valores de ejemplo)
        self.weeklyEarnings = 2400.00
        self.monthlyEarnings = 9600.00
        self.yearlyEarnings = 115200.00
    }
    
    private func loadNextDelivery() {
        // Simular datos de la próxima entrega
        self.nextDelivery = DeliveryInfo(
            id: "DLV001",
            customerName: "Logistics Corp",
            address: "123 Industrial Ave, Phoenix, AZ",
            deadline: Date().addingTimeInterval(2 * 3600), // 2 horas
            priority: .high,
            loadValue: 1500.00
        )
    }
    
    private func loadRecentAlerts() {
        // Simular alertas recientes
        self.recentAlerts = [
            Alert(id: "1", title: "Mantenimiento programado", message: "Su camión requiere mantenimiento en 500 millas", type: .maintenance, timestamp: Date().addingTimeInterval(-1800)),
            Alert(id: "2", title: "Entrega completada", message: "Entrega #DLV001 completada exitosamente", type: .success, timestamp: Date().addingTimeInterval(-3600))
        ]
        self.unreadNotifications = recentAlerts.count
    }
    
    func refreshData() {
        loadDashboardData()
    }
    
    func markNotificationAsRead(_ alert: Alert) {
        if let index = recentAlerts.firstIndex(where: { $0.id == alert.id }) {
            recentAlerts.remove(at: index)
            unreadNotifications = max(0, unreadNotifications - 1)
        }
    }
    
    func getCurrentStatus() -> String {
        if activeLoads > 0 {
            return "En ruta - \(activeLoads) entregas activas"
        } else {
            return "Disponible"
        }
    }
}

// MARK: - Models
struct DeliveryInfo {
    let id: String
    let customerName: String
    let address: String
    let deadline: Date
    let priority: Priority
    let loadValue: Double
    var isCompleted: Bool = false
}

struct Alert: Identifiable {
    let id: String
    let title: String
    let message: String
    let type: AlertType
    let timestamp: Date
}

enum Priority {
    case low
    case medium
    case high
    case urgent
}

enum AlertType {
    case maintenance
    case delivery
    case traffic
    case weather
    case success
    case error
    case warning
}