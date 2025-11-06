import Foundation
import Combine
import MapKit
import SwiftUI

class MapViewModel: ObservableObject {
    @Published var region: MKCoordinateRegion
    @Published var annotations: [CustomAnnotation] = []
    @Published var selectedAnnotation: CustomAnnotation?
    @Published var route: MKRoute?
    @Published var isLoadingRoute: Bool = false
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var isLocationTracking: Bool = false
    @Published var trafficEnabled: Bool = true
    @Published var mapType: MKMapType = .standard
    
    // Estados de la ruta
    @Published var currentRouteStep: RouteStep?
    @Published var remainingDistance: String = ""
    @Published var estimatedTimeOfArrival: String = ""
    @Published var navigationActive: Bool = false
    
    // Cargas en ruta
    @Published var activeDeliveries: [Delivery] = []
    @Published var nearbyGasStations: [GasStation] = []
    @Published var truckStops: [TruckStop] = []
    
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Configuración inicial del mapa (centro en Estados Unidos)
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
            span: MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 20.0)
        )
        
        setupLocationManager()
        loadSampleData()
    }
    
    private func setupLocationManager() {
        locationManager.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }
                
                self.currentLocation = location.coordinate
                
                if self.isLocationTracking {
                    // Actualizar región del mapa con la ubicación actual
                    self.region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadSampleData() {
        // Cargar cargas de ejemplo
        activeDeliveries = [
            Delivery(
                id: "DLV001",
                customerName: "Logistics Corp",
                address: "123 Industrial Ave, Phoenix, AZ 85001",
                coordinates: CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740),
                status: .inProgress,
                priority: .high,
                deadline: Date().addingTimeInterval(2 * 3600),
                loadValue: 1500.00,
                weight: 2500,
                pieces: 15
            ),
            Delivery(
                id: "DLV002",
                customerName: "ABC Manufacturing",
                address: "456 Warehouse Dr, Dallas, TX 75201",
                coordinates: CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970),
                status: .pending,
                priority: .medium,
                deadline: Date().addingTimeInterval(6 * 3600),
                loadValue: 2300.00,
                weight: 3200,
                pieces: 22
            ),
            Delivery(
                id: "DLV003",
                customerName: "XYZ Distribution",
                address: "789 Commerce St, Houston, TX 77001",
                coordinates: CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698),
                status: .scheduled,
                priority: .low,
                deadline: Date().addingTimeInterval(12 * 3600),
                loadValue: 1800.00,
                weight: 1800,
                pieces: 8
            )
        ]
        
        // Crear annotations
        updateAnnotations()
        
        // Cargar gasolineras y paradas de camiones
        loadNearbyFacilities()
    }
    
    private func updateAnnotations() {
        annotations = activeDeliveries.map { delivery in
            CustomAnnotation(
                coordinate: delivery.coordinates,
                type: .delivery,
                title: delivery.customerName,
                subtitle: delivery.address,
                identifier: delivery.id,
                data: delivery
            )
        }
        
        // Agregar paradas de camiones cercanas
        for station in nearbyGasStations {
            annotations.append(
                CustomAnnotation(
                    coordinate: station.coordinates,
                    type: .gasStation,
                    title: station.name,
                    subtitle: station.services.joined(separator: ", "),
                    identifier: station.id,
                    data: station
                )
            )
        }
        
        for stop in truckStops {
            annotations.append(
                CustomAnnotation(
                    coordinate: stop.coordinates,
                    type: .truckStop,
                    title: stop.name,
                    subtitle: "Restaurante • Duchas • WiFi",
                    identifier: stop.id,
                    data: stop
                )
            )
        }
    }
    
    private func loadNearbyFacilities() {
        // Gasolineras cercanas
        nearbyGasStations = [
            GasStation(
                id: "GS001",
                name: "Shell Truck Stop",
                coordinates: CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740),
                services: ["Diesel", "AdBlue", "Tienda"],
                pricePerGallon: 3.89,
                distance: 0.5
            ),
            GasStation(
                id: "GS002",
                name: "Pilot Flying J",
                coordinates: CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970),
                services: ["Diesel", "Duchas", "Restaurante"],
                pricePerGallon: 3.95,
                distance: 1.2
            )
        ]
        
        // Paradas de camiones
        truckStops = [
            TruckStop(
                id: "TS001",
                name: "Iowa 80 Truck Stop",
                coordinates: CLLocationCoordinate2D(latitude: 41.6005, longitude: -93.6091),
                services: ["Restaurante", "Duchas", "WiFi", "Mecánico"],
                rating: 4.5,
                amenities: ["Parking", "Zona de descanso", "Lavandería"]
            )
        ]
    }
    
    func startLocationTracking() {
        isLocationTracking = locationManager.requestLocationPermission()
    }
    
    func stopLocationTracking() {
        isLocationTracking = false
    }
    
    func centerOnCurrentLocation() {
        guard let currentLocation = currentLocation else { return }
        
        region = MKCoordinateRegion(
            center: currentLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    }
    
    func selectAnnotation(_ annotation: CustomAnnotation) {
        selectedAnnotation = annotation
        
        // Si es una entrega, mostrar detalles y preparar ruta
        if annotation.type == .delivery, let delivery = annotation.data as? Delivery {
            showDeliveryDetails(delivery)
        }
    }
    
    private func showDeliveryDetails(_ delivery: Delivery) {
        // Actualizar información de la entrega seleccionada
        print("Mostrando detalles de entrega: \(delivery.id)")
    }
    
    func getDirectionsToDelivery(_ delivery: Delivery) {
        guard let currentLocation = currentLocation else { return }
        
        isLoadingRoute = true
        
        let source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation))
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: delivery.coordinates))
        
        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let route = response?.routes.first {
                    self.route = route
                    self.updateRouteInformation(route, for: delivery)
                    self.startNavigation(route, to: delivery)
                }
                
                self.isLoadingRoute = false
            }
        }
    }
    
    private func updateRouteInformation(_ route: MKRoute, for delivery: Delivery) {
        let distanceInMiles = route.distance / 1609.34 // Convertir metros a millas
        let timeInMinutes = route.expectedTravelTime / 60
        
        remainingDistance = String(format: "%.1f mi", distanceInMiles)
        
        let eta = Date().addingTimeInterval(route.expectedTravelTime)
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        estimatedTimeOfArrival = timeFormatter.string(from: eta)
        
        // Calcular el primer paso de la ruta
        if let step = route.steps.first {
            currentRouteStep = RouteStep(
                instruction: step.instructions,
                distance: step.distance,
                expectedTime: step.expectedTravelTime
            )
        }
    }
    
    private func startNavigation(_ route: MKRoute, to delivery: Delivery) {
        navigationActive = true
        currentDelivery = delivery
    }
    
    func stopNavigation() {
        navigationActive = false
        route = nil
        currentRouteStep = nil
        remainingDistance = ""
        estimatedTimeOfArrival = ""
        currentDelivery = nil
    }
    
    @Published var currentDelivery: Delivery?
    
    func toggleTraffic() {
        trafficEnabled.toggle()
    }
    
    func changeMapType() {
        switch mapType {
        case .standard:
            mapType = .satellite
        case .satellite:
            mapType = .hybrid
        case .hybrid:
            mapType = .standard
        default:
            mapType = .standard
        }
    }
    
    func refreshDeliveries() {
        loadSampleData()
    }
    
    func markDeliveryAsCompleted(_ delivery: Delivery) {
        if let index = activeDeliveries.firstIndex(where: { $0.id == delivery.id }) {
            activeDeliveries[index].status = .completed
            
            // Actualizar annotations
            updateAnnotations()
            
            // Finalizar navegación si es la entrega actual
            if currentDelivery?.id == delivery.id {
                stopNavigation()
            }
        }
    }
    
    func findNearestGasStation() -> GasStation? {
        guard let currentLocation = currentLocation else { return nil }
        
        return nearbyGasStations.min { station1, station2 in
            let distance1 = distanceBetween(currentLocation, station1.coordinates)
            let distance2 = distanceBetween(currentLocation, station2.coordinates)
            return distance1 < distance2
        }
    }
    
    private func distanceBetween(_ loc1: CLLocationCoordinate2D, _ loc2: CLLocationCoordinate2D) -> Double {
        let loc1Point = CLLocation(latitude: loc1.latitude, longitude: loc1.longitude)
        let loc2Point = CLLocation(latitude: loc2.latitude, longitude: loc2.longitude)
        return loc1Point.distance(from: loc2Point)
    }
}

// MARK: - Models
struct CustomAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    let title: String?
    let subtitle: String?
    let identifier: String
    let data: Any?
}

enum AnnotationType {
    case delivery
    case gasStation
    case truckStop
    case currentLocation
    case waypoint
}

struct Delivery {
    let id: String
    let customerName: String
    let address: String
    let coordinates: CLLocationCoordinate2D
    let status: DeliveryStatus
    let priority: Priority
    let deadline: Date
    let loadValue: Double
    let weight: Int
    let pieces: Int
    var isCompleted: Bool = false
}

enum DeliveryStatus {
    case scheduled
    case inProgress
    case completed
    case pending
    case cancelled
}

struct RouteStep {
    let instruction: String
    let distance: CLLocationDistance
    let expectedTime: TimeInterval
}

struct GasStation {
    let id: String
    let name: String
    let coordinates: CLLocationCoordinate2D
    let services: [String]
    let pricePerGallon: Double
    let distance: Double
}

struct TruckStop {
    let id: String
    let name: String
    let coordinates: CLLocationCoordinate2D
    let services: [String]
    let rating: Double
    let amenities: [String]
}

// MARK: - Location Manager Helper
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() -> Bool {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}