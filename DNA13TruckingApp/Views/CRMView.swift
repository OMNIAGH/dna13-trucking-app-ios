import SwiftUI
import Charts

// MARK: - CRM Operational View
struct CRMView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    @State private var selectedPeriod: TimePeriod = .thisWeek
    @State private var selectedMetric: CRMMetric = .revenue
    @State private var crmData: CRMData = CRMData()
    @State private var isLoading = false
    
    enum TimePeriod: String, CaseIterable {
        case thisWeek = "Esta Semana"
        case thisMonth = "Este Mes"
        case lastMonth = "Mes Pasado"
        case thisQuarter = "Este Trimestre"
        case yearToDate = "YTD"
    }
    
    enum CRMMetric: String, CaseIterable {
        case revenue = "Ingresos"
        case miles = "Millas"
        case fuel = "Combustible"
        case maintenance = "Mantenimiento"
        case efficiency = "Eficiencia"
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with Period Selector
                        headerView
                        
                        // Key Performance Indicators
                        kpiCardsView
                        
                        // Charts Section
                        chartsSectionView
                        
                        // Fleet Overview
                        fleetOverviewView
                        
                        // Recent Activity
                        recentActivityView
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("CRM Operacional")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Exportar") {
                        exportData()
                    }
                    .font(Typography.buttonSmall)
                    .foregroundColor(.dnaOrange)
                }
            }
        }
        .onAppear {
            loadCRMData()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard CRM")
                    .font(Typography.h1)
                    .foregroundColor(.dnaTextSecondary)
                
                Text("Análisis operacional en tiempo real")
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary.opacity(0.8))
            }
            
            Spacer()
            
            Picker("Período", selection: $selectedPeriod) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .font(Typography.buttonSmall)
            .foregroundColor(.dnaOrange)
            .padding(8)
            .background(Color.dnaSurface)
            .cornerRadius(8)
        }
    }
    
    // MARK: - KPI Cards View
    private var kpiCardsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            KPICard(
                title: "Ingresos Totales",
                value: "$45,280",
                change: "+12.5%",
                trend: .up,
                color: .dnaSuccess
            )
            
            KPICard(
                title: "Millas Totales",
                value: "12,450",
                change: "+8.2%",
                trend: .up,
                color: .dnaTrip
            )
            
            KPICard(
                title: "Costo Combustible",
                value: "$3,240",
                change: "-5.1%",
                trend: .down,
                color: .dnaWarning
            )
            
            KPICard(
                title: "MPG Promedio",
                value: "6.8",
                change: "+0.3",
                trend: .up,
                color: .dnaMaintenance
            )
            
            KPICard(
                title: "Viajes Completados",
                value: "24",
                change: "+3",
                trend: .up,
                color: .dnaFuel
            )
            
            KPICard(
                title: "Tiempo en Ruta",
                value: "156 hrs",
                change: "+12 hrs",
                trend: .up,
                color: .dnaOrange
            )
        }
    }
    
    // MARK: - Charts Section View
    private var chartsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart Type Selector
            HStack {
                Text("Análisis de Datos")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Picker("Métrica", selection: $selectedMetric) {
                    ForEach(CRMMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .background(Color.dnaSurface)
                .cornerRadius(8)
            }
            
            // Revenue Chart (Placeholder - in real app would use Charts framework)
            chartView
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Chart View
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tendencias de \(selectedMetric.rawValue)")
                .font(Typography.h4)
                .foregroundColor(.dnaTextSecondary)
            
            // Placeholder for chart - in real app would integrate with Charts framework
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.dnaSurfaceLight)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundColor(.dnaTextSecondary.opacity(0.5))
                        
                        Text("Gráfico de \(selectedMetric.rawValue)")
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    }
                )
            
            // Chart Legend
            HStack {
                ForEach(0..<4) { index in
                    HStack {
                        Circle()
                            .fill(Color.dnaOrange.opacity(Double(index) * 0.25 + 0.25))
                            .frame(width: 8, height: 8)
                        
                        Text("Semana \(index + 1)")
                            .font(Typography.caption)
                            .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    }
                }
            }
        }
    }
    
    // MARK: - Fleet Overview View
    private var fleetOverviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Estado de Flota")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Text("2 Vehículos")
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary.opacity(0.8))
            }
            
            // Vehicle Status Cards
            ForEach(appState.selectedVehicle != nil ? [appState.selectedVehicle!] : [], id: \.id) { vehicle in
                VehicleStatusCard(vehicle: vehicle)
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Recent Activity View
    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actividad Reciente")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            // Activity Items
            ForEach(0..<5, id: \.self) { index in
                ActivityItemView(
                    icon: activityIcons[index],
                    title: activityTitles[index],
                    subtitle: activitySubtitles[index],
                    timestamp: activityTimestamps[index],
                    color: activityColors[index]
                )
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Data Management
    private func loadCRMData() {
        isLoading = true
        
        // Simulate data loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // In real app, would load from Supabase
            isLoading = false
        }
    }
    
    private func exportData() {
        // TODO: Implement data export
    }
    
    // MARK: - Sample Data
    private let activityIcons = ["truck.box", "fuelpump", "wrench", "doc.text", "bell"]
    private let activityTitles = ["Viaje completado", "Combustible registrado", "Mantenimiento programado", "Documento escaneado", "Alerta procesada"]
    private let activitySubtitles = ["Atlanta → Miami", "Shell Station - 148.8 gal", "Servicio 10K millas", "BOL #12345", "Clima adverso"]
    private let activityTimestamps = ["2h", "4h", "1d", "2d", "3d"]
    private let activityColors: [Color] = [.dnaTrip, .dnaFuel, .dnaMaintenance, .dnaOrange, .dnaAlert]
}

// MARK: - KPI Card Component
struct KPICard: View {
    let title: String
    let value: String
    let change: String
    let trend: Trend
    let color: Color
    
    enum Trend {
        case up
        case down
        case neutral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(Typography.bodySmall)
                    .foregroundColor(.dnaTextSecondary.opacity(0.8))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: trend == .up ? "arrow.up" : trend == .down ? "arrow.down" : "minus")
                        .font(.system(size: 12))
                        .foregroundColor(trend == .up ? .green : trend == .down ? .red : .gray)
                    
                    Text(change)
                        .font(Typography.caption)
                        .foregroundColor(trend == .up ? .green : trend == .down ? .red : .gray)
                }
            }
            
            Text(value)
                .font(Typography.metricMedium)
                .foregroundColor(color)
        }
        .padding()
        .background(Color.dnaSurfaceLight)
        .cornerRadius(12)
    }
}

// MARK: - Vehicle Status Card Component
struct VehicleStatusCard: View {
    let vehicle: Vehicle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vehicle.unitNumber)
                        .font(Typography.h4)
                        .foregroundColor(.dnaTextSecondary)
                    
                    Text("\(vehicle.make) \(vehicle.model ?? "") (\(vehicle.year))")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Circle()
                        .fill(vehicle.status == "active" ? .green : .yellow)
                        .frame(width: 8, height: 8)
                    
                    Text(vehicle.status)
                        .font(Typography.caption)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                }
            }
            
            HStack {
                metricItem(title: "Millas", value: String(format: "%.0f", vehicle.currentMileage))
                metricItem(title: "Último Servicio", value: vehicle.lastServiceAt?.relativeTime ?? "N/A")
                metricItem(title: "Estado", value: "Operativo")
            }
        }
        .padding()
        .background(Color.dnaBackground)
        .cornerRadius(8)
    }
    
    private func metricItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Typography.caption)
                .foregroundColor(.dnaTextSecondary.opacity(0.7))
            
            Text(value)
                .font(Typography.bodySmall)
                .foregroundColor(.dnaTextSecondary)
        }
    }
}

// MARK: - Activity Item View Component
struct ActivityItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    let timestamp: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.dnaBackground)
                .frame(width: 32, height: 32)
                .background(color)
                .cornerRadius(16)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary)
                
                Text(subtitle)
                    .font(Typography.bodySmall)
                    .foregroundColor(.dnaTextSecondary.opacity(0.8))
            }
            
            Spacer()
            
            // Timestamp
            Text(timestamp)
                .font(Typography.caption)
                .foregroundColor(.dnaTextSecondary.opacity(0.6))
        }
        .padding()
        .background(Color.dnaSurfaceLight)
        .cornerRadius(8)
    }
}

// MARK: - CRM Data Model
struct CRMData: ObservableObject {
    // Placeholder for CRM data
    // In real app, this would contain actual data from Supabase
}

#Preview {
    CRMView()
        .environmentObject(AuthManager())
        .environmentObject(AppState())
}
