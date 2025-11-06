import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    @State private var showingSettings = false
    @State private var showingVehicleSelection = false
    @State private var showingAISettings = false
    @State private var showingAdminSettings = false
    
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
                        // Profile Header
                        profileHeaderView
                        
                        // User Information
                        userInfoView
                        
                        // Vehicle Selection
                        if let vehicle = appState.selectedVehicle {
                            vehicleInfoView(vehicle)
                        } else {
                            noVehicleSelectedView
                        }
                        
                        // App Settings
                        appSettingsView
                        
                        // AI Configuration
                        if authManager.canAccessAdminSettings {
                            aiConfigurationView
                        }
                        
                        // Administrative Settings
                        if authManager.canAccessAdminSettings {
                            adminSettingsView
                        }
                        
                        // Account Actions
                        accountActionsView
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingVehicleSelection) {
                VehicleSelectionView { vehicle in
                    appState.setSelectedVehicle(vehicle)
                    showingVehicleSelection = false
                }
            }
            .sheet(isPresented: $showingAISettings) {
                AISettingsView()
            }
            .sheet(isPresented: $showingAdminSettings) {
                AdminSettingsView()
            }
        }
    }
    
    // MARK: - Profile Header View
    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.dnaSurface)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.dnaOrange, lineWidth: 3)
                    )
                
                if let user = authManager.currentUser {
                    Text(getInitials(from: user.fullName))
                        .font(Typography.h1)
                        .foregroundColor(.dnaTextSecondary)
                } else {
                    Image(systemName: "person.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.dnaTextSecondary.opacity(0.5))
                }
            }
            
            // User Name and Role
            if let user = authManager.currentUser {
                VStack(spacing: 4) {
                    Text(user.fullName)
                        .font(Typography.h2)
                        .foregroundColor(.dnaTextSecondary)
                    
                    Text(UserRole(rawValue: user.role)?.displayName ?? "Usuario")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary.opacity(0.8))
                    
                    Text(user.email)
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - User Info View
    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Información Personal")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Button("Editar") {
                    showingSettings = true
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaOrange)
            }
            
            if let user = authManager.currentUser {
                userInfoRow(title: "Nombre", value: user.fullName)
                userInfoRow(title: "Email", value: user.email)
                userInfoRow(title: "Rol", value: UserRole(rawValue: user.role)?.displayName ?? "Usuario")
                userInfoRow(title: "Miembro desde", value: user.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Vehicle Info View
    private func vehicleInfoView(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vehículo Asignado")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Button("Cambiar") {
                    showingVehicleSelection = true
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaOrange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(vehicle.unitNumber)
                        .font(Typography.h4)
                        .foregroundColor(.dnaOrange)
                    
                    Spacer()
                    
                    HStack {
                        Circle()
                            .fill(vehicle.status == "active" ? .green : .yellow)
                            .frame(width: 8, height: 8)
                        
                        Text(vehicle.status)
                            .font(Typography.bodySmall)
                            .foregroundColor(.dnaTextSecondary.opacity(0.8))
                    }
                }
                
                Text("\(vehicle.make) \(vehicle.model ?? "") (\(vehicle.year))")
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary.opacity(0.9))
                
                Text("VIN: \(vehicle.vin)")
                    .font(Typography.caption)
                    .foregroundColor(.dnaTextSecondary.opacity(0.7))
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - No Vehicle Selected View
    private var noVehicleSelectedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vehículo Asignado")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            VStack(spacing: 12) {
                Image(systemName: "truck")
                    .font(.system(size: 48))
                    .foregroundColor(.dnaTextSecondary.opacity(0.5))
                
                Text("No hay vehículo asignado")
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary.opacity(0.8))
                
                Button("Seleccionar Vehículo") {
                    showingVehicleSelection = true
                }
                .font(Typography.button)
                .foregroundColor(.dnaBackground)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.dnaOrange)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - App Settings View
    private var appSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuración de la App")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            // Dark/Light Mode Toggle
            HStack {
                Image(systemName: appState.isDarkMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.dnaOrange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Modo Oscuro")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                    
                    Text("Interfaz optimizada para operación nocturna")
                        .font(Typography.caption)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                }
                
                Spacer()
                
                Toggle("", isOn: $appState.isDarkMode)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .dnaOrange))
                    .onChange(of: appState.isDarkMode) { _ in
                        appState.toggleDarkMode()
                    }
            }
            
            // Location Services
            HStack {
                Image(systemName: appState.isLocationEnabled ? "location.fill" : "location")
                    .font(.system(size: 20))
                    .foregroundColor(.dnaOrange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Servicios de Ubicación")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                    
                    Text("Habilitar para navegación y tracking")
                        .font(Typography.caption)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                }
                
                Spacer()
                
                Toggle("", isOn: $appState.isLocationEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .dnaOrange))
            }
            
            // Notifications
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.dnaOrange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notificaciones")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                    
                    Text("Alertas de clima, tráfico y mantenimiento")
                        .font(Typography.caption)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(true))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .dnaOrange))
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - AI Configuration View
    private var aiConfigurationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Configuración de IA")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Button("Configurar") {
                    showingAISettings = true
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaOrange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain")
                        .font(.system(size: 16))
                        .foregroundColor(.dnaMaintenance)
                    
                    Text("Búsqueda Proactiva de Cargas")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                }
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16))
                        .foregroundColor(.dnaMaintenance)
                    
                    Text("Optimización de Rutas")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                }
                
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 16))
                        .foregroundColor(.dnaMaintenance)
                    
                    Text("Alertas Predictivas")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Admin Settings View
    private var adminSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Configuración Administrativa")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Button("Administrar") {
                    showingAdminSettings = true
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaOrange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                adminSettingRow(icon: "users", title: "Gestión de Usuarios", description: "Administrar roles y permisos")
                adminSettingRow(icon: "truck.box.badge.clockwise", title: "Gestión de Vehículos", description: "Flota y mantenimiento")
                adminSettingRow(icon: "doc.text.badge.plus", title: "Configuración de APIs", description: "Integraciones externas")
                adminSettingRow(icon: "chart.bar", title: "Reportes y Analytics", description: "Análisis operacional")
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Account Actions View
    private var accountActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Acciones de Cuenta")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            VStack(spacing: 12) {
                // Refresh Data Button
                Button(action: {
                    appState.refreshData()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                        
                        Text("Actualizar Datos")
                            .font(Typography.button)
                            .foregroundColor(.dnaOrange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.dnaSurfaceLight)
                    .cornerRadius(8)
                }
                
                // Support Button
                Button(action: {
                    // TODO: Open support
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16))
                        
                        Text("Soporte Técnico")
                            .font(Typography.button)
                            .foregroundColor(.dnaTextSecondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.dnaSurfaceLight)
                    .cornerRadius(8)
                }
                
                // Sign Out Button
                Button(action: {
                    Task {
                        try? await authManager.signOut()
                    }
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16))
                        
                        Text("Cerrar Sesión")
                            .font(Typography.button)
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.dnaSurfaceLight)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }
        return String(initials.prefix(2))
    }
    
    private func userInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private func adminSettingRow(icon: String, title: String, description: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary)
                
                Text(description)
                    .font(Typography.caption)
                    .foregroundColor(.dnaTextSecondary.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.dnaTextSecondary.opacity(0.6))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Vehicle Selection View
struct VehicleSelectionView: View {
    let onVehicleSelect: (Vehicle) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var vehicles: [Vehicle] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.dnaBackground, .dnaGreenDark.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List {
                    ForEach(vehicles) { vehicle in
                        Button(action: {
                            onVehicleSelect(vehicle)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vehicle.unitNumber)
                                    .font(Typography.h4)
                                    .foregroundColor(.dnaTextSecondary)
                                
                                Text("\(vehicle.make) \(vehicle.model ?? "") (\(vehicle.year))")
                                    .font(Typography.body)
                                    .foregroundColor(.dnaTextSecondary.opacity(0.8))
                                
                                HStack {
                                    Text("Estado: \(vehicle.status)")
                                        .font(Typography.caption)
                                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                                    
                                    Spacer()
                                    
                                    Circle()
                                        .fill(vehicle.status == "active" ? .green : .yellow)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(PlainListStyle())
                .onAppear {
                    loadVehicles()
                }
            }
            .navigationTitle("Seleccionar Vehículo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .font(Typography.button)
                    .foregroundColor(.dnaOrange)
                }
            }
        }
    }
    
    private func loadVehicles() {
        Task {
            do {
                let loadedVehicles = try await SupabaseService.shared.getVehicles()
                await MainActor.run {
                    self.vehicles = loadedVehicles
                }
            } catch {
                // Handle error or show sample data
                vehicles = [
                    Vehicle(
                        id: UUID(),
                        unitNumber: "115A",
                        vin: "4V4NC9TG6DN563822",
                        make: "Volvo",
                        model: "VNL 670",
                        year: 2013,
                        status: "active",
                        currentMileage: 245000,
                        currentLocation: "Atlanta, GA",
                        lastServiceAt: Date().addingTimeInterval(-30 * 24 * 3600)
                    ),
                    Vehicle(
                        id: UUID(),
                        unitNumber: "305",
                        vin: "1XKYAP9X2EJ386743",
                        make: "Kenworth",
                        model: "T680",
                        year: 2014,
                        status: "active",
                        currentMileage: 198000,
                        currentLocation: "Miami, FL",
                        lastServiceAt: Date().addingTimeInterval(-45 * 24 * 3600)
                    )
                ]
            }
        }
    }
}

// MARK: - AI Settings View
struct AISettingsView: View {
    @State private var proactiveSearchEnabled = true
    @State private var routeOptimizationEnabled = true
    @State private var predictiveAlertsEnabled = true
    @State private var autoLoadSearch = false
    @State private var alertFrequency: AlertFrequency = .realTime
    
    enum AlertFrequency: String, CaseIterable {
        case realTime = "Tiempo Real"
        case hourly = "Cada Hora"
        case daily = "Diario"
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
                
                List {
                    Section("Configuración General") {
                        SettingToggle(
                            title: "Búsqueda Proactiva de Cargas",
                            description: "La IA busca automáticamente cargas que se adapten a tu ruta",
                            isOn: $proactiveSearchEnabled
                        )
                        
                        SettingToggle(
                            title: "Optimización de Rutas",
                            description: "Calcular rutas óptimas considerando tráfico y clima",
                            isOn: $routeOptimizationEnabled
                        )
                        
                        SettingToggle(
                            title: "Alertas Predictivas",
                            description: "Notificaciones proactivas sobre condiciones del viaje",
                            isOn: $predictiveAlertsEnabled
                        )
                    }
                    
                    Section("Búsqueda Automática") {
                        SettingToggle(
                            title: "Búsqueda Automática de Cargas",
                            description: "Buscar cargas cada 30 minutos mientras estás en ruta",
                            isOn: $autoLoadSearch
                        )
                    }
                    
                    Section("Frecuencia de Alertas") {
                        Picker("Frecuencia", selection: $alertFrequency) {
                            ForEach(AlertFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.rawValue).tag(frequency)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Configuración de IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        // TODO: Save settings
                    }
                    .font(Typography.button)
                    .foregroundColor(.dnaOrange)
                }
            }
        }
    }
}

// MARK: - Admin Settings View
struct AdminSettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Gestión de Usuarios") {
                    adminRow(title: "Roles y Permisos", icon: "users", description: "Administrar roles del sistema")
                    adminRow(title: "Invitar Usuario", icon: "person.badge.plus", description: "Añadir nuevo usuario")
                }
                
                Section("Configuración del Sistema") {
                    adminRow(title: "APIs Externas", icon: "globe", description: "Configurar integraciones")
                    adminRow(title: "Configuración de Base de Datos", icon: "server.rack", description: "Gestión de datos")
                    adminRow(title: "Respaldos", icon: "externaldrive", description: "Respaldos y restauraciones")
                }
                
                Section("Analytics y Reportes") {
                    adminRow(title: "Dashboard de Analytics", icon: "chart.bar", description: "Métricas del sistema")
                    adminRow(title: "Reportes Personalizados", icon: "doc.text", description: "Generar reportes")
                }
            }
            .navigationTitle("Configuración Administrativa")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func adminRow(title: String, icon: String, description: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary)
                
                Text(description)
                    .font(Typography.caption)
                    .foregroundColor(.dnaTextSecondary.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.dnaTextSecondary.opacity(0.6))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Setting Toggle Component
struct SettingToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary)
                
                Text(description)
                    .font(Typography.caption)
                    .foregroundColor(.dnaTextSecondary.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .dnaOrange))
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(AppState())
}
