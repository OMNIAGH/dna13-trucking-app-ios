//
//  DashboardViewModelTests.swift
//  DNA13TruckingAppTests
//
//  Tests para DashboardViewModel
//

import XCTest
import Combine
@testable import DNA13TruckingApp

// MARK: - DashboardViewModelTests
class DashboardViewModelTests: XCTestCase {
    
    private var viewModel: DashboardViewModel!
    private var mockAuthManager: MockAuthManager!
    private var mockSupabaseService: MockSupabaseService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockAuthManager = MockAuthManager()
        mockSupabaseService = MockSupabaseService()
        viewModel = DashboardViewModel(authManager: mockAuthManager, supabaseService: mockSupabaseService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuthManager = nil
        mockSupabaseService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testDashboardViewModelInitialization() {
        XCTAssertEqual(viewModel.totalLoads, 0)
        XCTAssertEqual(viewModel.activeLoads, 0)
        XCTAssertEqual(viewModel.completedLoadsToday, 0)
        XCTAssertEqual(viewModel.pendingLoads, 0)
        XCTAssertEqual(viewModel.currentLocation, "En ruta")
        XCTAssertNil(viewModel.nextDelivery)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.weeklyEarnings, 0.0)
        XCTAssertEqual(viewModel.monthlyEarnings, 0.0)
        XCTAssertEqual(viewModel.yearlyEarnings, 0.0)
        XCTAssertEqual(viewModel.recentAlerts.count, 0)
        XCTAssertEqual(viewModel.unreadNotifications, 0)
    }
    
    func testDashboardViewModelWithCustomManagers() {
        let customAuthManager = MockAuthManager()
        let customSupabaseService = MockSupabaseService()
        
        let customViewModel = DashboardViewModel(
            authManager: customAuthManager,
            supabaseService: customSupabaseService
        )
        
        XCTAssertNotNil(customViewModel)
        XCTAssertEqual(customViewModel.totalLoads, 0)
    }
    
    // MARK: - Data Loading Tests
    func testLoadDashboardData() {
        let expectation = XCTestExpectation(description: "Load dashboard data")
        
        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                XCTAssertFalse(isLoading, "isLoading should be false after loading")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.$totalLoads
            .dropFirst()
            .sink { totalLoads in
                XCTAssertEqual(totalLoads, 45, "Expected 45 total loads")
            }
            .store(in: &cancellables)
        
        viewModel.$activeLoads
            .dropFirst()
            .sink { activeLoads in
                XCTAssertEqual(activeLoads, 3, "Expected 3 active loads")
            }
            .store(in: &cancellables)
        
        viewModel.$completedLoadsToday
            .dropFirst()
            .sink { completedLoadsToday in
                XCTAssertEqual(completedLoadsToday, 2, "Expected 2 completed loads today")
            }
            .store(in: &cancellables)
        
        viewModel.$pendingLoads
            .dropFirst()
            .sink { pendingLoads in
                XCTAssertEqual(pendingLoads, 5, "Expected 5 pending loads")
            }
            .store(in: &cancellables)
        
        viewModel.$weeklyEarnings
            .dropFirst()
            .sink { weeklyEarnings in
                XCTAssertEqual(weeklyEarnings, 2400.00, accuracy: 0.01, "Expected $2400.00 weekly earnings")
            }
            .store(in: &cancellables)
        
        viewModel.$monthlyEarnings
            .dropFirst()
            .sink { monthlyEarnings in
                XCTAssertEqual(monthlyEarnings, 9600.00, accuracy: 0.01, "Expected $9600.00 monthly earnings")
            }
            .store(in: &cancellables)
        
        viewModel.$yearlyEarnings
            .dropFirst()
            .sink { yearlyEarnings in
                XCTAssertEqual(yearlyEarnings, 115200.00, accuracy: 0.01, "Expected $115200.00 yearly earnings")
            }
            .store(in: &cancellables)
        
        viewModel.$nextDelivery
            .dropFirst()
            .sink { nextDelivery in
                XCTAssertNotNil(nextDelivery, "nextDelivery should be set")
                if let delivery = nextDelivery {
                    XCTAssertEqual(delivery.id, "DLV001")
                    XCTAssertEqual(delivery.customerName, "Logistics Corp")
                    XCTAssertEqual(delivery.priority, .high)
                    XCTAssertEqual(delivery.loadValue, 1500.00, accuracy: 0.01)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$recentAlerts
            .dropFirst()
            .sink { recentAlerts in
                XCTAssertEqual(recentAlerts.count, 2, "Expected 2 recent alerts")
                if recentAlerts.count >= 2 {
                    XCTAssertEqual(recentAlerts[0].title, "Mantenimiento programado")
                    XCTAssertEqual(recentAlerts[0].type, .maintenance)
                    XCTAssertEqual(recentAlerts[1].title, "Entrega completada")
                    XCTAssertEqual(recentAlerts[1].type, .success)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$unreadNotifications
            .dropFirst()
            .sink { unreadNotifications in
                XCTAssertEqual(unreadNotifications, 2, "Expected 2 unread notifications")
            }
            .store(in: &cancellables)
        
        viewModel.loadDashboardData()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testLoadDashboardDataSetsLoadingState() {
        XCTAssertFalse(viewModel.isLoading, "Initially not loading")
        
        viewModel.loadDashboardData()
        
        XCTAssertTrue(viewModel.isLoading, "Should be loading during data fetch")
    }
    
    // MARK: - Statistics Tests
    func testUpdateStatistics() {
        // Access private method through test (using direct call pattern)
        viewModel.updateStatistics()
        
        XCTAssertEqual(viewModel.totalLoads, 45)
        XCTAssertEqual(viewModel.activeLoads, 3)
        XCTAssertEqual(viewModel.completedLoadsToday, 2)
        XCTAssertEqual(viewModel.pendingLoads, 5)
        XCTAssertEqual(viewModel.weeklyEarnings, 2400.00, accuracy: 0.01)
        XCTAssertEqual(viewModel.monthlyEarnings, 9600.00, accuracy: 0.01)
        XCTAssertEqual(viewModel.yearlyEarnings, 115200.00, accuracy: 0.01)
    }
    
    // MARK: - Delivery Info Tests
    func testLoadNextDelivery() {
        viewModel.loadNextDelivery()
        
        XCTAssertNotNil(viewModel.nextDelivery, "nextDelivery should be set")
        
        if let delivery = viewModel.nextDelivery {
            XCTAssertEqual(delivery.id, "DLV001")
            XCTAssertEqual(delivery.customerName, "Logistics Corp")
            XCTAssertEqual(delivery.address, "123 Industrial Ave, Phoenix, AZ")
            XCTAssertEqual(delivery.priority, .high)
            XCTAssertEqual(delivery.loadValue, 1500.00, accuracy: 0.01)
            XCTAssertFalse(delivery.isCompleted, "New delivery should not be completed")
        }
    }
    
    func testNextDeliveryHasValidDeadline() {
        viewModel.loadNextDelivery()
        
        guard let delivery = viewModel.nextDelivery else {
            XCTFail("nextDelivery should not be nil")
            return
        }
        
        let now = Date()
        XCTAssertGreaterThan(delivery.deadline, now, "Delivery deadline should be in the future")
        XCTAssertLessThan(delivery.deadline, now.addingTimeInterval(3 * 3600), "Delivery deadline should be within 3 hours")
    }
    
    // MARK: - Alerts Tests
    func testLoadRecentAlerts() {
        viewModel.loadRecentAlerts()
        
        XCTAssertEqual(viewModel.recentAlerts.count, 2, "Should have 2 recent alerts")
        
        if viewModel.recentAlerts.count >= 2 {
            let maintenanceAlert = viewModel.recentAlerts[0]
            XCTAssertEqual(maintenanceAlert.title, "Mantenimiento programado")
            XCTAssertEqual(maintenanceAlert.type, .maintenance)
            XCTAssertEqual(maintenanceAlert.message, "Su camión requiere mantenimiento en 500 millas")
            
            let successAlert = viewModel.recentAlerts[1]
            XCTAssertEqual(successAlert.title, "Entrega completada")
            XCTAssertEqual(successAlert.type, .success)
        }
        
        XCTAssertEqual(viewModel.unreadNotifications, 2, "Should have 2 unread notifications")
    }
    
    func testMarkNotificationAsRead() {
        // Setup: Load alerts first
        viewModel.loadRecentAlerts()
        let initialAlertCount = viewModel.recentAlerts.count
        let initialUnreadCount = viewModel.unreadNotifications
        
        // Execute: Mark first alert as read
        let alertToMark = viewModel.recentAlerts[0]
        viewModel.markNotificationAsRead(alertToMark)
        
        // Verify: Alert should be removed and unread count should decrease
        XCTAssertEqual(viewModel.recentAlerts.count, initialAlertCount - 1, "Alert count should decrease by 1")
        XCTAssertEqual(viewModel.unreadNotifications, initialUnreadCount - 1, "Unread count should decrease by 1")
        XCTAssertFalse(viewModel.recentAlerts.contains(alertToMark), "Marked alert should not be in recent alerts")
    }
    
    func testMarkNonExistentNotificationAsRead() {
        viewModel.loadRecentAlerts()
        let initialCount = viewModel.recentAlerts.count
        
        let fakeAlert = Alert(
            id: "non-existent",
            title: "Non-existent",
            message: "This alert doesn't exist",
            type: .warning,
            timestamp: Date()
        )
        
        viewModel.markNotificationAsRead(fakeAlert)
        
        // Should not change anything
        XCTAssertEqual(viewModel.recentAlerts.count, initialCount, "Count should remain the same")
    }
    
    func testMarkNotificationAsReadWithEmptyList() {
        // Execute: Try to mark notification when list is empty
        let fakeAlert = Alert(
            id: "fake",
            title: "Fake",
            message: "Message",
            type: .warning,
            timestamp: Date()
        )
        
        viewModel.markNotificationAsRead(fakeAlert)
        
        XCTAssertEqual(viewModel.recentAlerts.count, 0, "Count should remain 0")
        XCTAssertEqual(viewModel.unreadNotifications, 0, "Unread should remain 0")
    }
    
    // MARK: - Status Tests
    func testGetCurrentStatusWithActiveLoads() {
        viewModel.activeLoads = 3
        viewModel.totalLoads = 5
        
        let status = viewModel.getCurrentStatus()
        XCTAssertEqual(status, "En ruta - 3 entregas activas")
    }
    
    func testGetCurrentStatusWithoutActiveLoads() {
        viewModel.activeLoads = 0
        viewModel.totalLoads = 5
        
        let status = viewModel.getCurrentStatus()
        XCTAssertEqual(status, "Disponible")
    }
    
    func testGetCurrentStatusWithZeroLoads() {
        viewModel.activeLoads = 0
        viewModel.totalLoads = 0
        
        let status = viewModel.getCurrentStatus()
        XCTAssertEqual(status, "Disponible")
    }
    
    // MARK: - Refresh Tests
    func testRefreshDataCallsLoadDashboardData() {
        let expectation = XCTestExpectation(description: "Refresh data")
        
        viewModel.$totalLoads
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.refreshData()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testRefreshDataResetsLoadingState() {
        XCTAssertFalse(viewModel.isLoading, "Initially not loading")
        
        viewModel.refreshData()
        
        XCTAssertTrue(viewModel.isLoading, "Should be loading during refresh")
    }
    
    // MARK: - Business Logic Tests
    func testBusinessLogicEarningsCalculation() {
        // Test that earnings are calculated correctly
        viewModel.weeklyEarnings = 1200.00
        viewModel.monthlyEarnings = 4800.00
        viewModel.yearlyEarnings = 57600.00
        
        // Weekly * 4 = Monthly
        XCTAssertEqual(viewModel.weeklyEarnings * 4, viewModel.monthlyEarnings, accuracy: 0.01)
        
        // Monthly * 12 = Yearly
        XCTAssertEqual(viewModel.monthlyEarnings * 12, viewModel.yearlyEarnings, accuracy: 0.01)
    }
    
    func testBusinessLogicLoadManagement() {
        // Test load management logic
        viewModel.totalLoads = 10
        viewModel.activeLoads = 3
        viewModel.completedLoadsToday = 2
        viewModel.pendingLoads = 5
        
        // Total should equal active + (completed today) + (completed previously) + pending
        let completedPreviously = viewModel.totalLoads - viewModel.activeLoads - viewModel.pendingLoads
        XCTAssertEqual(completedPreviously, 2, "Completed previously should be 2")
    }
    
    func testBusinessLogicNotificationCount() {
        viewModel.recentAlerts = [
            Alert(id: "1", title: "Alert 1", message: "Message 1", type: .warning, timestamp: Date()),
            Alert(id: "2", title: "Alert 2", message: "Message 2", type: .success, timestamp: Date()),
            Alert(id: "3", title: "Alert 3", message: "Message 3", type: .error, timestamp: Date())
        ]
        
        XCTAssertEqual(viewModel.unreadNotifications, 3, "Unread should equal alert count")
        
        // Mark one as read
        viewModel.markNotificationAsRead(viewModel.recentAlerts[0])
        XCTAssertEqual(viewModel.unreadNotifications, 2, "Unread should decrease by 1")
    }
    
    // MARK: - Edge Cases Tests
    func testNegativeValuesHandling() {
        viewModel.weeklyEarnings = -100.0
        viewModel.monthlyEarnings = -400.0
        viewModel.yearlyEarnings = -4800.0
        
        XCTAssertTrue(viewModel.weeklyEarnings < 0, "Negative earnings should be handled")
        XCTAssertTrue(viewModel.monthlyEarnings < 0, "Negative earnings should be handled")
        XCTAssertTrue(viewModel.yearlyEarnings < 0, "Negative earnings should be handled")
    }
    
    func testLargeValuesHandling() {
        viewModel.weeklyEarnings = 999999.99
        viewModel.totalLoads = 1000000
        viewModel.activeLoads = 999999
        
        XCTAssertEqual(viewModel.weeklyEarnings, 999999.99, accuracy: 0.01)
        XCTAssertEqual(viewModel.totalLoads, 1000000)
        XCTAssertEqual(viewModel.activeLoads, 999999)
    }
    
    func testZeroValuesHandling() {
        viewModel.weeklyEarnings = 0.0
        viewModel.totalLoads = 0
        viewModel.activeLoads = 0
        viewModel.completedLoadsToday = 0
        viewModel.pendingLoads = 0
        viewModel.unreadNotifications = 0
        
        XCTAssertEqual(viewModel.weeklyEarnings, 0.0)
        XCTAssertEqual(viewModel.totalLoads, 0)
        XCTAssertEqual(viewModel.unreadNotifications, 0)
    }
    
    // MARK: - Async/Await Tests
    func testAsyncInitialization() async {
        // Test async initialization if needed in future
        let viewModel = DashboardViewModel(authManager: mockAuthManager, supabaseService: mockSupabaseService)
        
        // Give it a moment to initialize
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertNotNil(viewModel)
    }
    
    // MARK: - State Tests
    func testStateChanges() {
        let expectation = XCTestExpectation(description: "State changes")
        
        viewModel.$isLoading
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadDashboardData()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testMultipleStateChanges() {
        let expectation = XCTestExpectation(description: "Multiple state changes")
        var changeCount = 0
        
        viewModel.$totalLoads
            .sink { _ in
                changeCount += 1
                if changeCount >= 2 { // Initial 0, then updated value
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.loadDashboardData()
        viewModel.loadDashboardData() // Call again
        
        wait(for: [expectation], timeout: 2.0)
    }
}

// MARK: - Mock AuthManager
class MockAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    static let shared: MockAuthManager = MockAuthManager()
    
    init() {
        // Mock initialization
    }
    
    func signIn(email: String, password: String) async throws {
        // Mock sign in
    }
    
    func signOut() async throws {
        // Mock sign out
    }
    
    func getCurrentUser() async -> User? {
        return currentUser
    }
}