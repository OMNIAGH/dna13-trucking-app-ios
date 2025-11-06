import SwiftUI
import MapKit
import CoreLocation

// MARK: - Map View
struct MapView: View {
    @EnvironmentObject var appState: AppState
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .region(.user))
    @State private var selectedAnnotation: MapAnnotation?
    @State private var showingRouteDetails = false
    @State private var currentRoute: MKRoute?
    @State private var mapStyle: MapStyle = .standard
    @State private var showSatelliteView = false
    
    // Sample locations for demonstration
    private let locations = [
        LocationAnnotation(
            id: "current",
            title: "Posición Actual",
            subtitle: appState.currentLocation,
            coordinate: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880), // Atlanta, GA
            type: .current
        ),
        LocationAnnotation(
            id: "pickup",
            title: "Punto de Recogida",
            subtitle: "Atlanta, GA",
            coordinate: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
            type: .pickup
        ),
        LocationAnnotation(
            id: "destination",
            title: "Destino",
            subtitle: "Miami, FL",
            coordinate: CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918),
            type: .destination
        ),
        LocationAnnotation(
            id: "fuel",
            title: "Estación de Combustible",
            subtitle: "Shell - Prix",
            coordinate: CLLocationCoordinate2D(latitude: 32.0835, longitude: -81.0998), // Savannah, GA
            type: .fuel
        ),
        LocationAnnotation(
            id: "rest",
            title: "Área de Descanso",
            subtitle: "Piedmont Rest Area",
            coordinate: CLLocationCoordinate2D(latitude: 31.1898, longitude: -81.7273), // Brunswick, GA
            type: .rest
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(position: $cameraPosition) {
                    // User location
                    UserAnnotation()
                    
                    // Route annotations
                    ForEach(locations) { location in
                        Annotation(location.title, coordinate: location.coordinate) {
                            LocationMarkerView(location: location)
                                .onTapGesture {
                                    selectedAnnotation = location
                                    showingRouteDetails = true
                                }
                        }
                    }
                    
                    // Route polyline
                    if let route = currentRoute {
                        MapPolyline(route.polyline)
                            .stroke(.blue, lineWidth: 4)
                    }
                }
                .mapStyle(showSatelliteView ? .satellite : .standard)
                .ignoresSafeArea()
                
                VStack {
                    // Map Controls
                    mapControlsView
                    
                    Spacer()
                    
                    // Route Information Card
                    if let route = currentRoute {
                        routeInfoCard
                    } else {
                        // No route card
                        noRouteCard
                    }
                }
                .padding()
            }
            .navigationTitle("Mapa de Rutas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleMapView) {
                        Image(systemName: showSatelliteView ? "map" : "satellite")
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.dnaOrange)
                }
            }
            .sheet(isPresented: $showingRouteDetails) {
                RouteDetailsView(
                    annotation: selectedAnnotation,
                    route: currentRoute
                )
            }
        }
    }
    
    // MARK: - Map Controls View
    private var mapControlsView: some View {
        HStack {
            // Current Location Button
            Button(action: centerOnUser) {
                Image(systemName: "location.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.dnaBackground)
                    .frame(width: 44, height: 44)
                    .background(Color.dnaOrange)
                    .cornerRadius(22)
            }
            
            Spacer()
            
            // Zoom Controls
            VStack(spacing: 8) {
                Button(action: zoomIn) {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                        .foregroundColor(.dnaTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.dnaSurface)
                        .cornerRadius(16)
                }
                
                Button(action: zoomOut) {
                    Image(systemName: "minus")
                        .font(.system(size: 16))
                        .foregroundColor(.dnaTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.dnaSurface)
                        .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Route Information Card
    private var routeInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ruta Activa")
                    .font(Typography.h3)
                    .foregroundColor(.dnaTextSecondary)
                
                Spacer()
                
                Button("Detalles") {
                    showingRouteDetails = true
                }
                .font(Typography.buttonSmall)
                .foregroundColor(.dnaOrange)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distancia")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    Text(formatDistance(currentRoute?.distance ?? 0))
                        .font(Typography.h2)
                        .foregroundColor(.dnaOrange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Tiempo Estimado")
                        .font(Typography.bodySmall)
                        .foregroundColor(.dnaTextSecondary.opacity(0.7))
                    
                    Text(formatDuration(currentRoute?.expectedTravelTime ?? 0))
                        .font(Typography.h2)
                        .foregroundColor(.dnaTrip)
                }
            }
            
            // Route Progress
            VStack(alignment: .leading, spacing: 8) {
                Text("Progreso del Viaje")
                    .font(Typography.body)
                    .foregroundColor(.dnaTextSecondary)
                
                ProgressView(value: 0.65) // Example progress
                    .tint(.dnaOrange)
                    .background(Color.dnaSurface)
            }
        }
        .padding()
        .background(Color.dnaBackground.opacity(0.9))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.dnaTextSecondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - No Route Card
    private var noRouteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sin Ruta Activa")
                .font(Typography.h3)
                .foregroundColor(.dnaTextSecondary)
            
            Text("No hay un viaje en curso. Selecciona un viaje o crea uno nuevo para ver la ruta.")
                .font(Typography.body)
                .foregroundColor(.dnaTextSecondary.opacity(0.8))
                .multilineTextAlignment(.leading)
            
            if let vehicle = appState.selectedVehicle {
                Text("Vehículo: \(vehicle.unitNumber)")
                    .font(Typography.bodySmall)
                    .foregroundColor(.dnaTextSecondary.opacity(0.7))
            }
        }
        .padding()
        .background(Color.dnaBackground.opacity(0.9))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.dnaTextSecondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Map Control Functions
    private func centerOnUser() {
        cameraPosition = .userLocation(fallback: .region(.user))
    }
    
    private func zoomIn() {
        // This would typically use MapKit's zoom functionality
        // For now, we'll just move to a closer region
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880), span: span)
        cameraPosition = .region(region)
    }
    
    private func zoomOut() {
        let span = MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880), span: span)
        cameraPosition = .region(region)
    }
    
    private func toggleMapView() {
        showSatelliteView.toggle()
    }
    
    // MARK: - Utility Functions
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let miles = distance / 1609.34
        return String(format: "%.0f mi", miles)
    }
    
    private func formatDuration(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Location Annotation Model
struct LocationAnnotation: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let type: LocationType
}

enum LocationType {
    case current
    case pickup
    case destination
    case fuel
    case rest
    case weighStation
    case maintenance
}

// MARK: - Location Marker View Component
struct LocationMarkerView: View {
    let location: LocationAnnotation
    
    var body: some View {
        ZStack {
            // Background circle with color based on type
            Circle()
                .fill(getMarkerColor())
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
            
            // Icon
            Image(systemName: getMarkerIcon())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private func getMarkerColor() -> Color {
        switch location.type {
        case .current: return .blue
        case .pickup: return .green
        case .destination: return .red
        case .fuel: return .orange
        case .rest: return .purple
        case .weighStation: return .yellow
        case .maintenance: return .gray
        }
    }
    
    private func getMarkerIcon() -> String {
        switch location.type {
        case .current: return "location"
        case .pickup: return "arrow.down.circle"
        case .destination: return "arrow.up.circle"
        case .fuel: return "fuelpump"
        case .rest: return "bed.double"
        case .weighStation: return "scalefor.horizontal"
        case .maintenance: return "wrench"
        }
    }
}

// MARK: - Route Details View
struct RouteDetailsView: View {
    let annotation: MapAnnotation?
    let route: MKRoute?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                if let annotation = annotation {
                    // Location Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(annotation.title)
                            .font(Typography.h2)
                            .foregroundColor(.dnaTextSecondary)
                        
                        Text(annotation.subtitle)
                            .font(Typography.body)
                            .foregroundColor(.dnaTextSecondary.opacity(0.8))
                        
                        Text(getLocationTypeDescription(annotation.type))
                            .font(Typography.caption)
                            .foregroundColor(.dnaTextSecondary.opacity(0.6))
                    }
                }
                
                if let route = route {
                    // Route Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detalles de Ruta")
                            .font(Typography.h3)
                            .foregroundColor(.dnaTextSecondary)
                        
                        detailRow(title: "Distancia", value: formatDistance(route.distance))
                        detailRow(title: "Tiempo Estimado", value: formatDuration(route.expectedTravelTime))
                        
                        if !route.advisoryNotices.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Avisos")
                                    .font(Typography.body)
                                    .foregroundColor(.dnaTextSecondary)
                                
                                ForEach(route.advisoryNotices, id: \.self) { notice in
                                    Text("• \(notice)")
                                        .font(Typography.bodySmall)
                                        .foregroundColor(.dnaTextSecondary.opacity(0.8))
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Detalles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .font(Typography.button)
                    .foregroundColor(.dnaOrange)
                }
            }
        }
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
    
    private func getLocationTypeDescription(_ type: LocationType) -> String {
        switch type {
        case .current: return "Tu ubicación actual"
        case .pickup: return "Punto de recogida de carga"
        case .destination: return "Destino final de la carga"
        case .fuel: return "Estación de combustible recomendada"
        case .rest: return "Área de descanso"
        case .weighStation: return "Estación de pesaje"
        case .maintenance: return "Centro de servicio y mantenimiento"
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let miles = distance / 1609.34
        return String(format: "%.1f millas", miles)
    }
    
    private func formatDuration(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            return "\(hours) horas \(minutes) minutos"
        } else {
            return "\(minutes) minutos"
        }
    }
}

// MARK: - Map Extension for User Region
extension MKCoordinateRegion {
    static let user = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
}

#Preview {
    MapView()
        .environmentObject(AppState())
}
