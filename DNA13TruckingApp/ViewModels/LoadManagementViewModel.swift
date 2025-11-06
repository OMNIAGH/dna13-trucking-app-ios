import Foundation
import Combine
import SwiftUI

class LoadManagementViewModel: ObservableObject {
    @Published var loads: [Load] = []
    @Published var filteredLoads: [Load] = []
    @Published var selectedLoad: Load?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Filtros
    @Published var filterStatus: LoadStatusFilter = .all
    @Published var searchText: String = ""
    @Published var sortOption: LoadSortOption = .priority
    
    // Estadísticas
    @Published var totalActiveLoads: Int = 0
    @Published var completedThisWeek: Int = 0
    @Published var pendingApprovals: Int = 0
    @Published var weeklyRevenue: Double = 0.0
    
    // Estados de carga
    @Published var availableLoads: [Load] = []
    @Published var assignedLoads: [Load] = []
    @Published var inTransitLoads: [Load] = []
    @Published var completedLoads: [Load] = []
    
    private let supabaseService: SupabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadLoads()
    }
    
    private func setupBindings() {
        // Combinar filtros
        Publishers.CombineLatest(
            $loads,
            Publishers.CombineLatest3($searchText, $filterStatus, $sortOption)
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .map { loads, filters in
            let (searchText, filterStatus, sortOption) = filters
            self.applyFilters(loads, searchText: searchText, filter: filterStatus, sort: sortOption)
        }
        .assign(to: \.filteredLoads, on: self)
        .store(in: &cancellables)
    }
    
    private func applyFilters(_ loads: [Load], searchText: String, filter: LoadStatusFilter, sort: LoadSortOption) -> [Load] {
        var filtered = loads
        
        // Aplicar filtro de estado
        switch filter {
        case .all:
            break
        case .available:
            filtered = filtered.filter { $0.status == .available }
        case .assigned:
            filtered = filtered.filter { $0.status == .assigned }
        case .inTransit:
            filtered = filtered.filter { $0.status == .inTransit }
        case .completed:
            filtered = filtered.filter { $0.status == .completed }
        case .pending:
            filtered = filtered.filter { $0.status == .pending }
        }
        
        // Aplicar búsqueda de texto
        if !searchText.isEmpty {
            filtered = filtered.filter { load in
                load.customerName.localizedCaseInsensitiveContains(searchText) ||
                load.pickupLocation.localizedCaseInsensitiveContains(searchText) ||
                load.deliveryLocation.localizedCaseInsensitiveContains(searchText) ||
                load.id.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Aplicar ordenamiento
        switch sort {
        case .priority:
            filtered.sort { $0.priority.rawValue > $1.priority.rawValue }
        case .deadline:
            filtered.sort { $0.deadline < $1.deadline }
        case .revenue:
            filtered.sort { $0.rate > $1.rate }
        case .date:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .customer:
            filtered.sort { $0.customerName < $1.customerName }
        }
        
        return filtered
    }
    
    private func loadLoads() {
        isLoading = true
        
        // Simular carga de datos
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.loadSampleLoads()
            self.updateStatistics()
            self.isLoading = false
        }
    }
    
    private func loadSampleLoads() {
        let sampleLoads: [Load] = [
            Load(
                id: "LD001",
                customerName: "Logistics Corp",
                pickupLocation: "Phoenix, AZ",
                deliveryLocation: "Dallas, TX",
                pickupDate: Date().addingTimeInterval(6 * 3600),
                deadline: Date().addingTimeInterval(48 * 3600),
                rate: 1500.00,
                weight: 2500,
                pieces: 15,
                status: .available,
                priority: .high,
                createdAt: Date().addingTimeInterval(-3600),
                equipment: .dryVan,
                specialInstructions: "Handle with care - fragile items",
                documents: ["BOL", "Insurance"],
                distance: 876,
                estimatedTime: 14
            ),
            Load(
                id: "LD002",
                customerName: "ABC Manufacturing",
                pickupLocation: "Houston, TX",
                deliveryLocation: "Chicago, IL",
                pickupDate: Date().addingTimeInterval(24 * 3600),
                deadline: Date().addingTimeInterval(72 * 3600),
                rate: 2300.00,
                weight: 3200,
                pieces: 22,
                status: .assigned,
                priority: .medium,
                createdAt: Date().addingTimeInterval(-7200),
                equipment: .refrigerated,
                specialInstructions: "Keep temperature at 35°F",
                documents: ["CMR", "Temperature Log"],
                distance: 1087,
                estimatedTime: 18
            ),
            Load(
                id: "LD003",
                customerName: "XYZ Distribution",
                pickupLocation: "Los Angeles, CA",
                deliveryLocation: "Seattle, WA",
                pickupDate: Date().addingTimeInterval(12 * 3600),
                deadline: Date().addingTimeInterval(36 * 3600),
                rate: 1800.00,
                weight: 1800,
                pieces: 8,
                status: .inTransit,
                priority: .high,
                createdAt: Date().addingTimeInterval(-14400),
                equipment: .flatbed,
                specialInstructions: "Requires tarping",
                documents: ["BOL", "Permits"],
                distance: 1135,
                estimatedTime: 20
            ),
            Load(
                id: "LD004",
                customerName: "Global Shipping Co",
                pickupLocation: "Miami, FL",
                deliveryLocation: "Atlanta, GA",
                pickupDate: Date().addingTimeInterval(2 * 3600),
                deadline: Date().addingTimeInterval(18 * 3600),
                rate: 950.00,
                weight: 1200,
                pieces: 12,
                status: .pending,
                priority: .low,
                createdAt: Date().addingTimeInterval(-1800),
                equipment: .dryVan,
                specialInstructions: "Standard delivery",
                documents: ["BOL"],
                distance: 662,
                estimatedTime: 10
            ),
            Load(
                id: "LD005",
                customerName: "Industrial Supply",
                pickupLocation: "Denver, CO",
                deliveryLocation: "Kansas City, MO",
                pickupDate: Date().addingTimeInterval(48 * 3600),
                deadline: Date().addingTimeInterval(96 * 3600),
                rate: 1200.00,
                weight: 2800,
                pieces: 18,
                status: .completed,
                priority: .medium,
                createdAt: Date().addingTimeInterval(-86400),
                equipment: .dryVan,
                specialInstructions: "Liftgate required at delivery",
                documents: ["BOL", "POD"],
                distance: 557,
                estimatedTime: 9
            )
        ]
        
        loads = sampleLoads
        categorizeLoads()
    }
    
    private func categorizeLoads() {
        availableLoads = loads.filter { $0.status == .available }
        assignedLoads = loads.filter { $0.status == .assigned }
        inTransitLoads = loads.filter { $0.status == .inTransit }
        completedLoads = loads.filter { $0.status == .completed }
    }
    
    private func updateStatistics() {
        totalActiveLoads = assignedLoads.count + inTransitLoads.count
        completedThisWeek = completedLoads.filter {
            Calendar.current.isDate($0.completedAt ?? Date(), equalTo: Date(), toGranularity: .weekOfYear)
        }.count
        pendingApprovals = loads.filter { $0.status == .pending }.count
        weeklyRevenue = completedLoads
            .filter {
                Calendar.current.isDate($0.completedAt ?? Date(), equalTo: Date(), toGranularity: .weekOfYear)
            }
            .reduce(0) { $0 + $1.rate }
    }
    
    func selectLoad(_ load: Load) {
        selectedLoad = load
    }
    
    func acceptLoad(_ load: Load) {
        if let index = loads.firstIndex(where: { $0.id == load.id }) {
            loads[index].status = .assigned
            loads[index].assignedDate = Date()
            categorizeLoads()
            updateStatistics()
        }
    }
    
    func declineLoad(_ load: Load) {
        if let index = loads.firstIndex(where: { $0.id == load.id }) {
            loads[index].status = .declined
            categorizeLoads()
        }
    }
    
    func startLoad(_ load: Load) {
        if let index = loads.firstIndex(where: { $0.id == load.id }) {
            loads[index].status = .inTransit
            loads[index].startedAt = Date()
            categorizeLoads()
            updateStatistics()
        }
    }
    
    func completeLoad(_ load: Load) {
        if let index = loads.firstIndex(where: { $0.id == load.id }) {
            loads[index].status = .completed
            loads[index].completedAt = Date()
            categorizeLoads()
            updateStatistics()
        }
    }
    
    func calculateProfitMargin(for load: Load) -> Double {
        // Simular costos operativos
        let fuelCost = load.distance * 0.35 // $0.35 por milla
        let driverCost = load.estimatedTime * 25 // $25 por hora
        let otherExpenses = 150.0 // Costos adicionales
        
        let totalCosts = fuelCost + driverCost + otherExpenses
        return ((load.rate - totalCosts) / load.rate) * 100
    }
    
    func getLoadStatusColor(_ status: LoadStatus) -> Color {
        switch status {
        case .available: return .green
        case .assigned: return .blue
        case .inTransit: return .orange
        case .completed: return .gray
        case .pending: return .yellow
        case .declined: return .red
        }
    }
    
    func getPriorityIcon(_ priority: LoadPriority) -> String {
        switch priority {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.circle.fill"
        }
    }
    
    func refreshLoads() {
        loadLoads()
    }
    
    func filterByStatus(_ status: LoadStatusFilter) {
        filterStatus = status
    }
    
    func sortBy(_ option: LoadSortOption) {
        sortOption = option
    }
    
    func search(_ text: String) {
        searchText = text
    }
    
    func clearFilters() {
        searchText = ""
        filterStatus = .all
        sortOption = .priority
    }
    
    func getLoadDetails(_ load: Load) -> LoadDetails {
        return LoadDetails(
            load: load,
            profitMargin: calculateProfitMargin(for: load),
            fuelEstimate: load.distance * 0.35,
            driverPay: load.estimatedTime * 25,
            documentsStatus: getDocumentStatus(for: load),
            trackingInfo: getTrackingInfo(for: load)
        )
    }
    
    private func getDocumentStatus(for load: Load) -> DocumentStatus {
        let totalDocs = load.documents.count
        let completedDocs = Int.random(in: 1...totalDocs)
        
        return DocumentStatus(
            total: totalDocs,
            completed: completedDocs,
            pending: totalDocs - completedDocs
        )
    }
    
    private func getTrackingInfo(for load: Load) -> TrackingInfo {
        return TrackingInfo(
            currentLocation: "En ruta - \(Int.random(in: 1...load.distance)) millas completadas",
            estimatedArrival: load.deadline,
            delayMinutes: Int.random(in: 0...30),
            lastUpdate: Date().addingTimeInterval(-300) // 5 minutos atrás
        )
    }
}

// MARK: - Models
struct Load: Identifiable {
    let id: String
    let customerName: String
    let pickupLocation: String
    let deliveryLocation: String
    let pickupDate: Date
    let deadline: Date
    let rate: Double
    let weight: Int
    let pieces: Int
    var status: LoadStatus
    let priority: LoadPriority
    let createdAt: Date
    
    var assignedDate: Date?
    var startedAt: Date?
    var completedAt: Date?
    
    let equipment: EquipmentType
    let specialInstructions: String
    let documents: [String]
    let distance: Int
    let estimatedTime: Int
}

enum LoadStatus: String, CaseIterable {
    case available = "Disponible"
    case assigned = "Asignada"
    case inTransit = "En Tránsito"
    case completed = "Completada"
    case pending = "Pendiente"
    case declined = "Rechazada"
}

enum LoadStatusFilter: String, CaseIterable {
    case all = "Todas"
    case available = "Disponibles"
    case assigned = "Asignadas"
    case inTransit = "En Tránsito"
    case completed = "Completadas"
    case pending = "Pendientes"
}

enum LoadSortOption: String, CaseIterable {
    case priority = "Prioridad"
    case deadline = "Fecha Límite"
    case revenue = "Ingresos"
    case date = "Fecha"
    case customer = "Cliente"
}

enum LoadPriority: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4
}

enum EquipmentType: String, CaseIterable {
    case dryVan = "Dry Van"
    case refrigerated = "Refrigerado"
    case flatbed = "Flatbed"
    case stepDeck = "Step Deck"
    case lowboy = "Lowboy"
    case container = "Container"
}

struct LoadDetails {
    let load: Load
    let profitMargin: Double
    let fuelEstimate: Double
    let driverPay: Double
    let documentsStatus: DocumentStatus
    let trackingInfo: TrackingInfo
}

struct DocumentStatus {
    let total: Int
    let completed: Int
    let pending: Int
}

struct TrackingInfo {
    let currentLocation: String
    let estimatedArrival: Date
    let delayMinutes: Int
    let lastUpdate: Date
}