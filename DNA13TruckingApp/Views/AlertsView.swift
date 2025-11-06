import SwiftUI

// MARK: - Alerts View
struct AlertsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    @State private var alerts: [PredictiveAlert] = []
    @State private var filteredAlerts: [PredictiveAlert] = []
    @State private var selectedFilter: AlertFilter = .all
    @State private var isRefreshing = false
    
    enum AlertFilter: String, CaseIterable {
        case all = "Todas"
        case high = "Alta Prioridad"
        case medium = "Media Prioridad"
        case low = "Baja Prioridad"
        case weather = "Clima"
        case traffic = "Tráfico"
        case permits = "Permisos"
        case maintenance = "Mantenimiento"
        case fuel = "Combustible"
        case compliance = "Compliance"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.dnaBackground, .dnaGreenDark.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with Statistics
                    alertStatsView
                    
                    // Filter Tabs
                    filterTabsView
                    
                    // Alerts List
                    if isRefreshing {
                        loadingView
                    } else if filteredAlerts.isEmpty {
                        emptyStateView
                    } else {
                        alertsListView
                    }
                }
            }
            .navigationTitle("Alertas Predictivas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Actualizar") {
                        Task {
                            await refreshAlerts()
                        }
                    }
                    .font(Typography.buttonSmall)
                    .foregroundColor(.dnaOrange)
                }
            }
        }
        .onAppear {
            loadAlerts()
        }
    }
    
    // MARK: - Alert Statistics View
    private var alertStatsView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alertas Activas")
                        .font(Typography.h3)
                        .foregroundColor(.dnaTextSecondary)
                    
                    Text("\(alerts.count) total")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Alta Prioridad")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    Text("\(alerts.filter { $0.priority == "high" }.count)")
                        .font(Typography.h2)
                        .foregroundColor(.dnaAlert)
                }
            }
            
            // Priority Distribution
            HStack(spacing: 12) {
                priorityIndicator(count: alerts.filter { $0.priority == "high" }.count, color: .red, label: "Alta")
                priorityIndicator(count: alerts.filter { $0.priority == "medium" }.count, color: .yellow, label: "Media")
                priorityIndicator(count: alerts.filter { $0.priority == "low" }.count, color: .green, label: "Baja")
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Filter Tabs View
    private var filterTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AlertFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        title: filter.rawValue,
                        count: getFilterCount(filter),
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        filterAlerts()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .dnaOrange))
                .scaleEffect(1.5)
            
            Text("Cargando alertas...")
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 48))
                .foregroundColor(.green.opacity(0.7))
            
            Text("¡Sin Alertas!")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
            
            Text(selectedFilter == .all 
                ? "No hay alertas pendientes en este momento." 
                : "No hay alertas del tipo \(selectedFilter.rawValue.lowercased()).")
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Alerts List View
    private var alertsListView: some View {
        List {
            ForEach(filteredAlerts, id: \.type) { alert in
                AlertRowView(alert: alert) {
                    handleAlertAction(alert)
                }
                .listRowBackground(Color.dnaBackground)
                .listRowSeparatorTint(.dnaTextSecondary.opacity(0.2))
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Utility Methods
    private func loadAlerts() {
        guard let user = authManager.currentUser,
              let vehicle = appState.selectedVehicle else { return }
        
        isRefreshing = true
        
        Task {
            do {
                let response = try await SupabaseService.shared.getPredictiveAlerts(
                    vehicleId: vehicle.id,
                    userId: user.id,
                    location: appState.currentLocation
                )
                
                await MainActor.run {
                    self.alerts = response.data.alerts
                    self.filterAlerts()
                    self.isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    self.isRefreshing = false
                    // Handle error - maybe show sample data for demo
                    self.alerts = generateSampleAlerts()
                    self.filterAlerts()
                }
            }
        }
    }
    
    private func refreshAlerts() async {
        await loadAlerts()
    }
    
    private func filterAlerts() {
        switch selectedFilter {
        case .all:
            filteredAlerts = alerts
        case .high:
            filteredAlerts = alerts.filter { $0.priority == "high" }
        case .medium:
            filteredAlerts = alerts.filter { $0.priority == "medium" }
        case .low:
            filteredAlerts = alerts.filter { $0.priority == "low" }
        case .weather:
            filteredAlerts = alerts.filter { $0.type == "weather" }
        case .traffic:
            filteredAlerts = alerts.filter { $0.type == "traffic" }
        case .permits:
            filteredAlerts = alerts.filter { $0.type == "permit" }
        case .maintenance:
            filteredAlerts = alerts.filter { $0.type == "maintenance" }
        case .fuel:
            filteredAlerts = alerts.filter { $0.type == "fuel" }
        case .compliance:
            filteredAlerts = alerts.filter { $0.type == "compliance" }
        }
    }
    
    private func getFilterCount(_ filter: AlertFilter) -> Int {
        switch filter {
        case .all: return alerts.count
        case .high: return alerts.filter { $0.priority == "high" }.count
        case .medium: return alerts.filter { $0.priority == "medium" }.count
        case .low: return alerts.filter { $0.priority == "low" }.count
        case .weather: return alerts.filter { $0.type == "weather" }.count
        case .traffic: return alerts.filter { $0.type == "traffic" }.count
        case .permits: return alerts.filter { $0.type == "permit" }.count
        case .maintenance: return alerts.filter { $0.type == "maintenance" }.count
        case .fuel: return alerts.filter { $0.type == "fuel" }.count
        case .compliance: return alerts.filter { $0.type == "compliance" }.count
        }
    }
    
    private func handleAlertAction(_ alert: PredictiveAlert) {
        // TODO: Implement alert-specific actions
        print("Alert action: \(alert.action ?? "none")")
    }
    
    private func generateSampleAlerts() -> [PredictiveAlert] {
        return [
            PredictiveAlert(
                type: "weather",
                priority: "high",
                title: "Condiciones Climáticas Adversas",
                message: "Se acerca una tormenta invernal. Temperatura 28°F con nieve. Reduce velocidad y mantén distancia.",
                action: "check_weather_route",
                location: appState.currentLocation
            ),
            PredictiveAlert(
                type: "traffic",
                priority: "medium",
                title: "Tráfico Intenso Detectado",
                message: "Retraso estimado de 45 minutos en tu ruta actual debido a accidente en I-75.",
                action: "reroute",
                location: appState.currentLocation
            ),
            PredictiveAlert(
                type: "permit",
                priority: "high",
                title: "Permiso por Vencer",
                message: "Permiso de Kentucky vence en 2 días. Renovación requerida para continuar operaciones.",
                action: "renew_permit",
                daysRemaining: 2
            ),
            PredictiveAlert(
                type: "maintenance",
                priority: "medium",
                title: "Mantenimiento Programado",
                message: "Vehículo necesita servicio. Han pasado más de 10,000 millas desde el último servicio.",
                action: "schedule_maintenance"
            ),
            PredictiveAlert(
                type: "fuel",
                priority: "low",
                title: "Precio de Combustible Alto",
                message: "Precio actual $3.89/gal está 12% por encima del promedio regional.",
                action: "find_cheaper_fuel"
            )
        ]
    }
}

// MARK: - Priority Indicator Component
struct PriorityIndicator: View {
    let count: Int
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(label): \(count)")
                .font(Typography.caption)
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color.dnaSurfaceLight)
        .cornerRadius(6)
    }
}

// MARK: - Filter Tab Component
struct FilterTab: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(Typography.buttonSmall)
                    .foregroundColor(isSelected ? .dnaBackground : .dnaTextSecondary)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSelected ? .dnaBackground : .dnaTextSecondary.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.dnaBackground.opacity(0.3) : Color.dnaTextSecondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.dnaOrange : Color.dnaSurfaceLight)
            .cornerRadius(16)
        }
    }
}

// MARK: - Alert Row View Component
struct AlertRowView: View {
    let alert: PredictiveAlert
    let onAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: getAlertIcon())
                        .font(.system(size: 16))
                        .foregroundColor(getAlertColor())
                    
                    Text(alert.title)
                        .font(Typography.h4)
                        .foregroundColor(.dnaTextSecondary)
                }
                
                Spacer()
                
                // Priority Badge
                Text(alert.priority.uppercased())
                    .font(Typography.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(getPriorityColor(alert.priority))
                    .cornerRadius(12)
            }
            
            // Message
            Text(alert.message)
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary.opacity(0.9))
                .multilineTextAlignment(.leading)
            
            // Additional Info
            if let daysRemaining = alert.daysRemaining {
                HStack {
                    Text("Días restantes: \(daysRemaining)")
                        .font(Typography.caption)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    Spacer()
                }
            }
            
            if let location = alert.location {
                HStack {
                    Image(systemName: "location")
                        .font(.system(size: 12))
                        .foregroundColor(.dnaTextSecondary.opacity(0.6))
                    
                    Text(location)
                        .font(Typography.caption)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    Spacer()
                }
            }
            
            // Action Button
            if let action = alert.action {
                Button("Ejecutar Acción") {
                    onAction()
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaBackground)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.dnaOrange)
                .cornerRadius(16)
            }
        }
        .padding()
        .background(Color.dnaSurfaceLight)
        .cornerRadius(12)
    }
    
    private func getAlertIcon() -> String {
        switch alert.type {
        case "weather": return "cloud.sun"
        case "traffic": return "car"
        case "permit": return "doc.text"
        case "maintenance": return "wrench"
        case "fuel": return "fuelpump"
        case "compliance": return "checkmark.shield"
        default: return "bell"
        }
    }
    
    private func getAlertColor() -> Color {
        switch alert.type {
        case "weather": return .blue
        case "traffic": return .orange
        case "permit": return .red
        case "maintenance": return .purple
        case "fuel": return .green
        case "compliance": return .red
        default: return .yellow
        }
    }
    
    private func getPriorityColor(_ priority: String) -> Color {
        switch priority {
        case "high": return .red
        case "medium": return .yellow
        case "low": return .green
        default: return .gray
        }
    }
}

#Preview {
    AlertsView()
        .environmentObject(AuthManager())
        .environmentObject(AppState())
}
