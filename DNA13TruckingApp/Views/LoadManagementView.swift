import SwiftUI

// MARK: - Load Management View
struct LoadManagementView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var appState: AppState
    @State private var loads: [Load] = []
    @State private var proactiveSuggestions: [ProactiveSuggestion] = []
    @State private var isLoading = false
    @State private var searchOrigin = ""
    @State private var searchDestination = ""
    @State private var maxDistance: Int = 500
    @State private var selectedLoad: Load?
    @State private var showingLoadDetails = false
    @State private var showingProactiveSearch = false
    
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
                    // Search Controls
                    searchControlsView
                    
                    // Filters and Options
                    filtersView
                    
                    // Proactive Search Results
                    if showingProactiveSearch && !proactiveSuggestions.isEmpty {
                        proactiveSearchView
                    }
                    
                    // Loads List
                    if isLoading {
                        loadingView
                    } else if loads.isEmpty {
                        emptyStateView
                    } else {
                        loadsListView
                    }
                }
            }
            .navigationTitle("Gestión de Cargas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("IA Proactiva") {
                        showingProactiveSearch = true
                        Task {
                            await searchProactiveLoads()
                        }
                    }
                    .font(Typography.buttonSmall)
                    .foregroundColor(.dnaOrange)
                }
            }
            .sheet(isPresented: $showingLoadDetails) {
                if let load = selectedLoad {
                    LoadDetailsView(load: load) {
                        showingLoadDetails = false
                    }
                }
            }
        }
        .onAppear {
            if appState.selectedVehicle != nil {
                loadRecommendedLoads()
            }
        }
    }
    
    // MARK: - Search Controls View
    private var searchControlsView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Origen")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    TextField("Ciudad de origen", text: $searchOrigin)
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Destino")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    TextField("Ciudad de destino", text: $searchDestination)
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distancia Máxima (millas)")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    TextField("500", value: $maxDistance, format: .number)
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary)
                        .textFieldStyle(PlainTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                Spacer()
                
                Button("Buscar Cargas") {
                    Task {
                        await searchLoads()
                    }
                }
                .font(Typography.button)
                .foregroundColor(.dnaBackground)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.dnaOrange)
                .cornerRadius(8)
                .disabled(isLoading)
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Filters View
    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(title: "Todas las cargas", isSelected: true) { }
                FilterChip(title: "Alta rentabilidad", isSelected: false) { }
                FilterChip(title: "Carga completa", isSelected: false) { }
                FilterChip(title: "Refrigerado", isSelected: false) { }
                FilterChip(title: "Hazmat", isSelected: false) { }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Proactive Search View
    private var proactiveSearchView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sugerencias Proactivas de IA")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Button("Cerrar") {
                    showingProactiveSearch = false
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaOrange)
            }
            
            ForEach(proactiveSuggestions, id: \.type) { suggestion in
                ProactiveSuggestionView(suggestion: suggestion)
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .dnaOrange))
                .scaleEffect(1.5)
            
            Text("Buscando cargas...")
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.dnaTextSecondary.opacity(0.5))
            
            Text("No se encontraron cargas")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
            
            Text("Intenta ajustar los filtros o usar la búsqueda proactiva de IA")
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Button("Buscar con IA Proactiva") {
                showingProactiveSearch = true
                Task {
                    await searchProactiveLoads()
                }
            }
            .font(Typography.button)
            .foregroundColor(.dnaBackground)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.dnaOrange)
            .cornerRadius(8)
        }
        .padding()
    }
    
    // MARK: - Loads List View
    private var loadsListView: some View {
        List {
            ForEach(loads, id: \.id) { load in
                LoadRowView(load: load) {
                    selectedLoad = load
                    showingLoadDetails = true
                }
                .listRowBackground(Color.dnaBackground)
                .listRowSeparatorTint(.dnaTextSecondary.opacity(0.2))
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Search Functions
    private func loadRecommendedLoads() {
        guard let vehicle = appState.selectedVehicle else { return }
        
        isLoading = true
        Task {
            await searchLoads()
        }
    }
    
    private func searchLoads() async {
        guard let user = authManager.currentUser,
              let vehicle = appState.selectedVehicle else { return }
        
        isLoading = true
        
        do {
            let response = try await SupabaseService.shared.searchLoads(
                origin: searchOrigin.isEmpty ? nil : searchOrigin,
                destination: searchDestination.isEmpty ? nil : searchDestination,
                currentLocation: appState.currentLocation,
                vehicleId: vehicle.id,
                userId: user.id,
                maxDistance: maxDistance
            )
            
            await MainActor.run {
                self.loads = response.data.loads
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                // Handle error
            }
        }
    }
    
    private func searchProactiveLoads() async {
        guard let user = authManager.currentUser,
              let vehicle = appState.selectedVehicle else { return }
        
        showingProactiveSearch = true
        
        do {
            let response = try await SupabaseService.shared.searchLoads(
                origin: nil, // Let AI decide
                destination: nil, // Let AI decide
                currentLocation: appState.currentLocation,
                vehicleId: vehicle.id,
                userId: user.id,
                maxDistance: maxDistance
            )
            
            await MainActor.run {
                self.proactiveSuggestions = response.data.proactiveSuggestions
            }
        } catch {
            // Handle error
        }
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.buttonSmall)
                .foregroundColor(isSelected ? .dnaBackground : .dnaTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.dnaOrange : Color.dnaSurfaceLight)
                .cornerRadius(16)
        }
    }
}

// MARK: - Proactive Suggestion View Component
struct ProactiveSuggestionView: View {
    let suggestion: ProactiveSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.title)
                    .font(Typography.h4)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Text(suggestion.priority.uppercased())
                    .font(Typography.caption)
                    .foregroundColor(
                        suggestion.priority == "high" ? .red :
                        suggestion.priority == "medium" ? .yellow : .green
                    )
            }
            
            Text(suggestion.description)
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
            
            if let action = suggestion.action {
                Button("Ejecutar Acción") {
                    // TODO: Implement action
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaBackground)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.dnaOrange)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.dnaSurfaceLight)
        .cornerRadius(8)
    }
}

// MARK: - Load Row View Component
struct LoadRowView: View {
    let load: Load
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with Load ID and Status
                HStack {
                    Text("Carga #\(load.id)")
                        .font(Typography.h4)
                        .foregroundColor(.dnaTextSecondary)
                    
                    Spacer()
                    
                    if let aiRank = load.aiRank {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            
                            Text("IA #\(aiRank)")
                                .font(Typography.caption)
                                .foregroundColor(.dnaTextSecondary)
                        }
                    }
                }
                
                // Route Information
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Origen")
                            .font(Typography.bodySmall)
                            .foregroundColor(.dnaTextSecondary.opacity(0.7))
                        
                        Text(load.origin)
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary)
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(.dnaTextSecondary.opacity(0.6))
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Destino")
                            .font(Typography.bodySmall)
                            .foregroundColor(.dnaTextSecondary.opacity(0.7))
                        
                        Text(load.destination)
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary)
                    }
                }
                
                // Load Details
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Distancia")
                            .font(Typography.bodySmall)
                            .foregroundColor(.dnaTextSecondary.opacity(0.7))
                        
                        Text("\(load.distance) mi")
                            .font(Typography.body)
                            .foregroundColor(.dnaTrip)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Tarifa")
                            .font(Typography.bodySmall)
                            .foregroundColor(.dnaTextSecondary.opacity(0.7))
                        
                        Text("$\(String(format: "%.2f", load.rate))/mi")
                            .font(Typography.body)
                            .foregroundColor(.dnaOrange)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Total")
                            .font(Typography.bodySmall)
                            .foregroundColor(.dnaTextSecondary.opacity(0.7))
                        
                        Text("$\(String(format: "%.0f", load.total))")
                            .font(Typography.body)
                            .foregroundColor(.dnaSuccess)
                    }
                }
                
                // Load Info
                HStack {
                    Text("• \(load.commodity)")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    Spacer()
                    
                    Text("Pickup: \(load.pickupDate)")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.6))
                }
                
                // AI Reasoning (if available)
                if let reasoning = load.aiReasoning {
                    Text(reasoning)
                        .font(Typography.caption)
                        .foregroundColor(.dnaTextSecondary.opacity(0.8))
                        .italic()
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Load Details View
struct LoadDetailsView: View {
    let load: Load
    let onClose: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detalle de Carga")
                            .font(Typography.h2)
                            .foregroundColor(.dnaTextSecondary)
                        
                        Text("Carga #\(load.id)")
                            .font(Typography.h3)
                            .foregroundColor(.dnaOrange)
                    }
                    
                    // Route
                    routeDetailCard
                    
                    // Financial Details
                    financialDetailCard
                    
                    // Load Details
                    loadDetailCard
                    
                    // Contact Information
                    contactDetailCard
                    
                    // Notes
                    if !load.notes.isEmpty {
                        notesCard
                    }
                }
                .padding()
            }
            .navigationTitle("Carga #\(load.id)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        onClose()
                        dismiss()
                    }
                    .font(Typography.button)
                    .foregroundColor(.dnaOrange)
                }
            }
        }
    }
    
    private var routeDetailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ruta")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                detailRow(title: "Origen", value: load.origin)
                detailRow(title: "Destino", value: load.destination)
                detailRow(title: "Distancia", value: "\(load.distance) millas")
                
                HStack {
                    Text("Fechas")
                        .font(Typography.body)
                        .foregroundColor(.dnaTextSecondary.opacity(0.8))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Recogida: \(load.pickupDate)")
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary)
                        
                        Text("Entrega: \(load.deliveryDate)")
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    private var financialDetailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Información Financiera")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                detailRow(title: "Tarifa por Milla", value: "$\(String(format: "%.2f", load.rate))/mi")
                detailRow(title: "Monto Total", value: "$\(String(format: "%.0f", load.total))")
                
                if let aiRank = load.aiRank {
                    HStack {
                        Text("Ranking de IA")
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary.opacity(0.8))
                        
                        Spacer()
                        
                        HStack {
                            Text("Posición #\(aiRank)")
                                .font(Typography.body)
                                .foregroundColor(.dnaTextSecondary)
                            
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    private var loadDetailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalles de la Carga")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                detailRow(title: "Commodity", value: load.commodity)
                detailRow(title: "Peso", value: "\(load.weight) lbs")
                detailRow(title: "Piezas", value: "\(load.pieces)")
                detailRow(title: "Plataforma", value: load.source)
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    private var contactDetailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Información de Contacto")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                detailRow(title: "Broker", value: load.broker)
                detailRow(title: "Contacto", value: load.contact)
            }
            
            HStack {
                Button("Llamar") {
                    // TODO: Implement phone call
                }
                .font(Typography.button)
                .foregroundColor(.dnaBackground)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.dnaOrange)
                .cornerRadius(8)
                
                Spacer()
                
                Button("Email") {
                    // TODO: Implement email
                }
                .font(Typography.button)
                .foregroundColor(.dnaOrange)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.dnaSurfaceLight)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notas Adicionales")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            Text(load.notes)
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.dnaSurface)
        .cornerRadius(12)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary)
        }
    }
}

#Preview {
    LoadManagementView()
        .environmentObject(AuthManager())
        .environmentObject(AppState())
}
