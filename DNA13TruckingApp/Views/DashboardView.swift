import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [.dnaBackground, .dnaGreenDark.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with User Info
                        headerView
                        
                        // Current Vehicle Info
                        vehicleInfoView
                        
                        // Current Trip Status
                        if let trip = appState.currentTrip {
                            currentTripView(trip)
                        }
                        
                        // Metrics Grid
                        metricsGridView
                        
                        // Quick Actions
                        quickActionsView
                        
                        // Recent Alerts
                        if !appState.recentAlerts.isEmpty {
                            recentAlertsView
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await refreshData() } }) {
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .dnaOrange))
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("¡Hola!")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Text(authManager.currentUser?.fullName ?? "Usuario")
                    .font(Typography.h1)
                    .foregroundColor(.dnaOrange)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Estado")
                    .font(Typography.bodySmall)
                    .foregroundColor(.dnaTextSecondary.opacity(0.7))
                
                HStack {
                    Circle()
                        .fill(appState.isOnline ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text(appState.isOnline ? "En línea" : "Desconectado")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary)
                }
            }
        }
    }
    
    // MARK: - Vehicle Info View
    private var vehicleInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vehículo Actual")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                if let vehicle = appState.selectedVehicle {
                    Text(vehicle.unitNumber)
                        .font(Typography.h2)
                        .foregroundColor(.dnaOrange)
                        .fontWeight(.bold)
                } else {
                    Button("Seleccionar") {
                        // TODO: Show vehicle selection
                    }
                    .font(Typography.button)
                    .foregroundColor(.dnaOrange)
                }
            }
            
            if let vehicle = appState.selectedVehicle {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(vehicle.make) \(vehicle.model ?? "") \(vehicle.year)")
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary.opacity(0.8))
                        
                        Text("VIN: \(vehicle.vin)")
                            .font(Typography.caption)
                            .foregroundColor(.dnaTextSecondary.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Estado")
                            .font(Typography.caption)
                            .foregroundColor(.dnaTextSecondary.opacity(0.7))
                        
                        Text(vehicle.status)
                            .font(Typography.button)
                            .foregroundColor(vehicle.status == "active" ? .green : .yellow)
                    }
                }
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Current Trip View
    private func currentTripView(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Viaje Actual")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Text(trip.status.displayName)
                    .font(Typography.buttonSmall)
                    .foregroundColor(trip.status.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(trip.status.color.opacity(0.2))
                    .cornerRadius(20)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Origen")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    Text("\(trip.originCity), \(trip.originState)")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                }
                
                Image(systemName: "arrow.right")
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary.opacity(0.6))
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Destino")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    Text("\(trip.destCity), \(trip.destState)")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                }
            }
            
            if let distance = trip.distanceMiles {
                HStack {
                    Text("Distancia")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(String(format: "%.0f", distance)) millas")
                        .font(Typography.body)
                        .foregroundColor(.dnaOrange)
                }
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Metrics Grid View
    private var metricsGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Millas Hoy",
                value: String(format: "%.0f", appState.totalMilesToday),
                unit: "mi",
                icon: "location",
                color: .dnaTrip
            )
            
            MetricCard(
                title: "Combustible",
                value: String(format: "%.1f", appState.fuelGallonsToday),
                unit: "gal",
                icon: "fuelpump",
                color: .dnaFuel
            )
            
            MetricCard(
                title: "Costo Combustible",
                value: String(format: "$%.2f", appState.fuelCostToday),
                unit: "",
                icon: "dollarsign.circle",
                color: .dnaWarning
            )
            
            MetricCard(
                title: "Tiempo Conducción",
                value: String(format: "%.1f", appState.driveTimeHours),
                unit: "hrs",
                icon: "clock",
                color: .dnaMaintenance
            )
            
            MetricCard(
                title: "MPG Actual",
                value: String(format: "%.1f", appState.currentMPG),
                unit: "mpg",
                icon: "speedometer",
                color: .dnaSuccess
            )
        }
    }
    
    // MARK: - Quick Actions View
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Acciones Rápidas")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Escanear BOL",
                    icon: "doc.text.viewfinder",
                    color: .dnaOrange
                ) {
                    // TODO: Navigate to document scan
                }
                
                QuickActionButton(
                    title: "Buscar Cargas",
                    icon: "magnifyingglass",
                    color: .dnaTrip
                ) {
                    // TODO: Navigate to load search
                }
                
                QuickActionButton(
                    title: "Chat IA",
                    icon: "message.circle",
                    color: .dnaMaintenance
                ) {
                    // TODO: Navigate to AI chat
                }
                
                QuickActionButton(
                    title: "Ver Alertas",
                    icon: "bell",
                    color: .dnaAlert
                ) {
                    // TODO: Navigate to alerts
                }
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Recent Alerts View
    private var recentAlertsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Alertas Recientes")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Button("Ver todas") {
                    // TODO: Navigate to alerts view
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaOrange)
            }
            
            ForEach(appState.recentAlerts.prefix(3), id: \.id) { alert in
                AlertItemView(alert: alert)
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Refresh Data
    private func refreshData() async {
        isRefreshing = true
        appState.refreshData()
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        isRefreshing = false
    }
}

// MARK: - Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .metricText()
                .foregroundColor(.dnaTextSecondary)
            
            HStack {
                Text(title)
                    .font(Typography.bodySmall)
                    .foregroundColor(.dnaTextSecondary.opacity(0.7))
                
                Spacer()
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(Typography.caption)
                        .foregroundColor(.dnaTextSecondary.opacity(0.5))
                }
            }
        }
        .padding()
        .background(Color.dnaSurfaceLight)
        .cornerRadius(12)
    }
}

// MARK: - Quick Action Button Component
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(Typography.buttonSmall)
                    .foregroundColor(.dnaTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.dnaSurfaceLight)
            .cornerRadius(8)
        }
    }
}

// MARK: - Alert Item View Component
struct AlertItemView: View {
    let alert: Notification
    
    var body: some View {
        HStack {
            Image(systemName: getAlertIcon())
                .font(.system(size: 16))
                .foregroundColor(getAlertColor())
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.payload["title"] as? String ?? "Alerta")
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary)
                    .lineLimit(1)
                
                Text(alert.payload["message"] as? String ?? "Mensaje no disponible")
                    .font(Typography.caption)
                    .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(alert.status)
                .font(Typography.caption)
                .foregroundColor(alert.status == "pending" ? .yellow : .green)
        }
        .padding()
        .background(Color.dnaSurfaceLight)
        .cornerRadius(8)
    }
    
    private func getAlertIcon() -> String {
        let type = alert.type
        switch type {
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
        let type = alert.type
        switch type {
        case "weather": return .blue
        case "traffic": return .orange
        case "permit": return .red
        case "maintenance": return .purple
        case "fuel": return .green
        case "compliance": return .red
        default: return .yellow
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager())
        .environmentObject(AppState())
}
