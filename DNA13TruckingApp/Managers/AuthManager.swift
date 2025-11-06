import Foundation
import SwiftUI

// MARK: - Authentication Manager
@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService: SupabaseService
    
    init() {
        self.supabaseService = SupabaseService.shared
    }
    
    static let shared = AuthManager()
    
    func checkAuthStatus() {
        Task {
            await checkAuthStatusAsync()
        }
    }
    
    private func checkAuthStatusAsync() async {
        isLoading = true
        
        do {
            if let user = try await supabaseService.getCurrentUser() {
                let profile = try await supabaseService.getUserProfile(userId: user.id)
                
                await MainActor.run {
                    currentUser = profile
                    isAuthenticated = true
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isAuthenticated = false
                    currentUser = nil
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                isAuthenticated = false
                currentUser = nil
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func signUp(email: String, password: String, fullName: String, role: UserRole = .driver) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await supabaseService.signUp(
                email: email,
                password: password,
                fullName: fullName,
                role: role
            )
            
            let profile = try await supabaseService.getUserProfile(userId: user.id)
            
            await MainActor.run {
                currentUser = profile
                isAuthenticated = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await supabaseService.signIn(email: email, password: password)
            let profile = try await supabaseService.getUserProfile(userId: user.id)
            
            await MainActor.run {
                currentUser = profile
                isAuthenticated = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signOut() async throws {
        isLoading = true
        
        do {
            try await supabaseService.signOut()
            
            await MainActor.run {
                isAuthenticated = false
                currentUser = nil
                isLoading = false
                errorMessage = nil
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func hasRole(_ role: UserRole) -> Bool {
        return currentUser?.role == role.rawValue
    }
    
    func hasAnyRole(_ roles: [UserRole]) -> Bool {
        return roles.contains { role in
            currentUser?.role == role.rawValue
        }
    }
    
    var canAccessAdminSettings: Bool {
        return hasAnyRole([.admin, .manager])
    }
    
    var canCreateTrips: Bool {
        return hasAnyRole([.admin, .manager, .dispatcher])
    }
    
    var canViewAllReports: Bool {
        return hasAnyRole([.admin, .manager])
    }
}

// MARK: - App State Manager
@MainActor
class AppState: ObservableObject {
    @Published var selectedVehicle: Vehicle?
    @Published var currentTrip: Trip?
    @Published var currentLocation: String = "Ubicación no disponible"
    @Published var isLocationEnabled = false
    @Published var isDarkMode = true
    
    // Dashboard metrics
    @Published var totalMilesToday: Double = 0
    @Published var fuelGallonsToday: Double = 0
    @Published var fuelCostToday: Double = 0
    @Published var driveTimeHours: Double = 0
    @Published var currentMPG: Double = 0
    
    // Real-time data
    @Published var recentAlerts: [Notification] = []
    @Published var isOnline = true
    
    private let supabaseService: SupabaseService
    
    init() {
        self.supabaseService = SupabaseService.shared
        loadAppState()
    }
    
    private func loadAppState() {
        // Load saved preferences
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        if let savedVehicleId = UserDefaults.standard.string(forKey: "selectedVehicleId") {
            // Will be loaded when vehicles are fetched
        }
    }
    
    func saveAppState() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        if let vehicleId = selectedVehicle?.id.uuidString {
            UserDefaults.standard.set(vehicleId, forKey: "selectedVehicleId")
        }
    }
    
    func setSelectedVehicle(_ vehicle: Vehicle) {
        selectedVehicle = vehicle
        saveAppState()
        
        Task {
            await loadVehicleData(vehicle)
        }
    }
    
    private func loadVehicleData(_ vehicle: Vehicle) async {
        do {
            // Load current trip
            let trip = try await supabaseService.getCurrentTrip(vehicleId: vehicle.id)
            await MainActor.run {
                currentTrip = trip
            }
            
            // Load trip metrics if trip exists
            if let trip = trip {
                let metrics = try await supabaseService.getTripMetrics(tripId: trip.id)
                await MainActor.run {
                    updateMetrics(with: metrics)
                }
            }
            
            // Load fuel records
            let fuelRecords = try await supabaseService.getFuelRecords(vehicleId: vehicle.id, limit: 5)
            await MainActor.run {
                updateFuelData(with: fuelRecords)
            }
            
            // Load alerts if user is logged in
            if let user = AuthManager.shared.currentUser {
                let alerts = try await supabaseService.getRecentAlerts(userId: user.id, limit: 10)
                await MainActor.run {
                    recentAlerts = alerts
                }
            }
        } catch {
            print("Error loading vehicle data: \(error)")
        }
    }
    
    private func updateMetrics(with metrics: TripMetrics?) {
        guard let metrics = metrics else { return }
        
        totalMilesToday = metrics.totalMiles
        driveTimeHours = Double(metrics.driveTimeMinutes) / 60.0
        fuelGallonsToday = metrics.fuelVolumeGal
        fuelCostToday = metrics.fuelCost
        
        if metrics.mpg > 0 {
            currentMPG = metrics.mpg
        }
    }
    
    private func updateFuelData(with fuelRecords: [FuelRecord]) {
        let today = Calendar.current.startOfDay(for: Date())
        let todayRecords = fuelRecords.filter { fuelRecord in
            Calendar.current.isDate(fuelRecord.date, inSameDayAs: today)
        }
        
        fuelGallonsToday = todayRecords.reduce(0) { $0 + $1.gallons }
        fuelCostToday = todayRecords.reduce(0) { $0 + $1.amount }
        
        if fuelGallonsToday > 0 && totalMilesToday > 0 {
            currentMPG = totalMilesToday / fuelGallonsToday
        }
    }
    
    func updateLocation(_ location: String) {
        currentLocation = location
        isLocationEnabled = true
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        saveAppState()
    }
    
    func refreshData() {
        if let vehicle = selectedVehicle {
            Task {
                await loadVehicleData(vehicle)
            }
        }
    }
}

// MARK: - Supabase Service Extension for Shared Instance
extension SupabaseService {
    static let shared = SupabaseService()
}
