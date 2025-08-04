import SwiftUI
import GoogleMaps
import CoreLocation
import MapKit

// MARK: - Your LocationManager for current user location

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var markers: [GMSMarker] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            DispatchQueue.main.async {
                self.userLocation = location.coordinate
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error)")
    }
}

// MARK: - Google MapViewController wrapper

class MapViewController: UIViewController {
    let map = GMSMapView(frame: .zero)
    var currentPolyline: GMSPolyline?

    override func loadView() {
        self.view = map
    }

    func moveToLocation(_ coordinate: CLLocationCoordinate2D, zoom: Float = 14) {
        let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: zoom)
        map.animate(to: camera)
    }
    
    func addPolyline(path: GMSPath) {
        // Remove existing polyline
        currentPolyline?.map = nil
        
        // Create new polyline
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = UIColor.systemBlue
        polyline.strokeWidth = 4.0
        polyline.map = map
        currentPolyline = polyline
    }
    
    func clearPolyline() {
        currentPolyline?.map = nil
        currentPolyline = nil
    }
}

// MARK: - UIViewControllerRepresentable bridge for SwiftUI

struct MapViewControllerBridge: UIViewControllerRepresentable {
    
    @Binding var selectedMarker: GMSMarker?
    @Binding var polylinePath: GMSPath?
    @Binding var shouldRealignToUser: Bool // Add this binding
    var onAnimationEnded: () -> Void
    var mapViewWillMove: (Bool) -> Void
    @Binding var userLocation: CLLocationCoordinate2D?

    func makeUIViewController(context: Context) -> MapViewController {
        let controller = MapViewController()
        controller.map.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        // Handle realignment trigger
        if shouldRealignToUser, let userLoc = userLocation {
            uiViewController.moveToLocation(userLoc)
            DispatchQueue.main.async {
                shouldRealignToUser = false // Reset the trigger
            }
        }

        // Show selected marker on the map
        selectedMarker?.map = uiViewController.map
        
        if let selected = selectedMarker {
            uiViewController.map.selectedMarker = selected
        }
        
        // Handle polyline updates
        if let path = polylinePath {
            uiViewController.addPolyline(path: path)
        } else {
            uiViewController.clearPolyline()
        }
    }

    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator(self)
    }

    class MapViewCoordinator: NSObject, GMSMapViewDelegate {
        var parent: MapViewControllerBridge

        init(_ parent: MapViewControllerBridge) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            parent.mapViewWillMove(gesture)
        }
    }
}

// MARK: - Place search using MKLocalSearch

func searchPlaces(lat: Double, lon: Double, query: String, completion: @escaping ([MKMapItem]) -> Void) {
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    request.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                        latitudinalMeters: 4000,
                                        longitudinalMeters: 4000)

    let search = MKLocalSearch(request: request)
    search.start { response, error in
        if let error = error {
            print("Search error: \(error.localizedDescription)")
            completion([])
            return
        }
        
        guard let response = response else {
            completion([])
            return
        }
        completion(response.mapItems)
    }
}

// MARK: - Directions fetching (async/await)

struct DirectionStep: Codable, Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let instruction: String
    let distance: String
    let duration: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Search Bar Component
struct SearchBarView: View {
    @Binding var query: String
    let onQueryChange: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
                .opacity(0.25)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                .frame(width: 300, height: 50)
            
            TextField("Search places near you", text: $query)
                .onChange(of: query) { _ in onQueryChange() }
                .padding(.horizontal, 20)
                .frame(width: 300, height: 50)
                .foregroundColor(.primary)
        }
        .frame(width: 300, height: 50)
    }
}

// MARK: - Place Row Component
struct PlaceRowView: View {
    let place: MKMapItem
    let userLocation: CLLocationCoordinate2D?
    let isLoadingDirections: Bool
    let onShowOnMap: () -> Void
    let onGetDirections: () -> Void
    let isLast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(place.name ?? "Unnamed")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let address = place.placemark.title {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 16) {
                Button("Show on Map", action: onShowOnMap)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                if userLocation != nil {
                    Button(action: onGetDirections) {
                    
                        HStack(spacing: 4) {
                            if isLoadingDirections {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "location.north.fill")
                            }
                            Text("Directions")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .disabled(isLoadingDirections)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .frame(maxHeight: 175)
        .overlay(
            Group {
                if !isLast {
                    VStack {
                        Spacer()
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
        )
    }
}

// MARK: - Search Results Component
struct SearchResultsView: View {
    let searchResults: [MKMapItem]
    let userLocation: CLLocationCoordinate2D?
    let isLoadingDirections: Bool
    let onShowOnMap: (MKMapItem) -> Void
    let onGetDirections: (MKMapItem) -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(searchResults.indices, id: \.self) { index in
                        let place = searchResults[index]
                        PlaceRowView(
                            place: place,
                            userLocation: userLocation,
                            isLoadingDirections: isLoadingDirections,
                            onShowOnMap: { onShowOnMap(place) },
                            onGetDirections: { onGetDirections(place) },
                            isLast: index == searchResults.count - 1
                        )
                    }
                }
            }
            .frame(maxHeight: 175)
        }
        .padding(.horizontal)
        .frame(width: 300)
        
    }
}

// MARK: - Direction Step Component
struct DirectionStepView: View {
    let step: DirectionStep
    let isLast: Bool
    
    var sign: String {
            switch step.instruction.lowercased() {
            case let str where str.contains("left"):
                return "arrow.turn.up.left"
            case let str where str.contains("right"):
                return "arrow.turn.up.right"
            case let str where str.contains("straight"):
                return "arrow.up"
            default:
                return "location.fill"
            }
        }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: sign)
                    .foregroundColor(.blue)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.instruction)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(step.distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(step.duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            if !isLast {
                Divider()
                    .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Directions Panel Component
struct DirectionsPanelView: View {
    let directions: [DirectionStep]
    let totalDuration: String
    let onClear: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .frame(maxHeight: 175)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Directions")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Clear", action: onClear)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Text("Est Time: " + totalDuration)

                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                
                DirectionStepView(
                    step: directions[0],
                    isLast: false
                )
            }
        }
        .padding(.horizontal)
        .frame(width: 300)
    }
}

// MARK: - Google Maps Content View
struct GoogleMapsContentView: View {
    
    @StateObject var locationManager = LocationManager()
    @EnvironmentObject var navigationState: NavigationStateManager
    
    @State private var query: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMarker: GMSMarker?
    @State private var errorMessage: String?
    @State private var polylinePath: GMSPath?
    @State private var isLoadingDirections = false
    @StateObject private var locationHandler = LocationHandler()
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var shouldRealignToUser = false

    var body: some View {
        ZStack {
            mapView
            
            VStack {
                searchBar
                searchResultsList
                directionsPanel
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // Simply trigger the realignment
                        shouldRealignToUser = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 18, weight: .medium))
                        }
                    }
                    .buttonStyle(LocationButtonStyle()) // Add the button style for press effect
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .onChange(of: navigationState.isNavigating) { newValue in
            if newValue {
                hideKeyboard()
            }
        }
        .onAppear {
            shouldRealignToUser = true

            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                guard navigationState.isNavigating,
                      let currentStep = navigationState.currentStep else { return }

                if locationHandler.isNear(to: currentStep.coordinate, within: 25.0) {
                    navigationState.advanceToNextStep()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
        private var mapView: some View {
            GeometryReader { _ in
                MapViewControllerBridge(
                    selectedMarker: $selectedMarker,
                    polylinePath: $polylinePath,
                    shouldRealignToUser: $shouldRealignToUser, // Add this binding
                    onAnimationEnded: {},
                    mapViewWillMove: { _ in },
                    userLocation: $locationManager.userLocation
                )
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    
    @ViewBuilder
    private var searchBar: some View {
        SearchBarView(query: $query) {
            searchNearbyPlaces()
        }
    }
    
    @ViewBuilder
    private var searchResultsList: some View {
        // Hide search results when navigating
        if !searchResults.isEmpty && !navigationState.isNavigating {
            SearchResultsView(
                searchResults: searchResults,
                userLocation: locationManager.userLocation,
                isLoadingDirections: isLoadingDirections,
                onShowOnMap: selectPlaceOnMap,
                onGetDirections: { place in
                    if let userLoc = locationManager.userLocation {
                        Task {
                            await fetchDirections(to: place.placemark.coordinate, from: userLoc, destination: place)
                        }
                    }
                }
            )
        }
    }
    
    @ViewBuilder
    private var directionsPanel: some View {
        // Auto-show directions panel when navigationState has active navigation
        if navigationState.isNavigating && navigationState.hasMoreSteps {
            if let currentStep = navigationState.currentStep {
                DirectionsPanelView(
                    directions: [currentStep],
                    totalDuration: navigationState.totalDuration
                ) {
                    navigationState.stopNavigation()
                    polylinePath = nil
                }
                .offset(y: dragOffset)
                .opacity(isDragging ? 0.8 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: dragOffset)
                .animation(.easeInOut(duration: 0.2), value: isDragging)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            // Only allow upward dragging
                            if gesture.translation.height < 0 {
                                dragOffset = gesture.translation.height
                                isDragging = true
                            }
                        }
                        .onEnded { gesture in
                            isDragging = false
                            
                            // If dragged up more than 100 points, dismiss
                            if gesture.translation.height < -100 {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dragOffset = -500 // Animate off screen
                                }
                                
                                // Dismiss after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    navigationState.stopNavigation()
                                    polylinePath = nil
                                    dragOffset = 0
                                }
                            } else {
                                // Snap back to original position
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
        } else if navigationState.isNavigating && !navigationState.hasMoreSteps {
            Text("You have arrived! 🎉")
                .font(.headline)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding(.horizontal)
                .offset(y: dragOffset)
                .opacity(isDragging ? 0.8 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: dragOffset)
                .animation(.easeInOut(duration: 0.2), value: isDragging)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if gesture.translation.height < 0 {
                                dragOffset = gesture.translation.height
                                isDragging = true
                            }
                        }
                        .onEnded { gesture in
                            isDragging = false
                            
                            if gesture.translation.height < -100 {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dragOffset = -500
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    navigationState.stopNavigation()
                                    polylinePath = nil
                                    dragOffset = 0
                                }
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
        }
    }

    struct RoundedCorner: Shape {
        var radius: CGFloat = 25.0
        var corners: UIRectCorner = .allCorners

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            return Path(path.cgPath)
        }
    }
    
    struct LocationButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .opacity(configuration.isPressed ? 0.6 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    // MARK: - Helpers
    
    func searchNearbyPlaces() {
        guard let userLoc = locationManager.userLocation else {
            print("User location not available")
            return
        }
        
        searchPlaces(lat: userLoc.latitude, lon: userLoc.longitude, query: query) { results in
            DispatchQueue.main.async {
                self.searchResults = results
                self.selectedMarker = nil
                self.navigationState.stopNavigation() // Clear any existing navigation
                self.polylinePath = nil
            }
        }
    }
    
    func selectPlaceOnMap(_ place: MKMapItem) {
        let marker = GMSMarker(position: place.placemark.coordinate)
        marker.title = place.name
        marker.map = nil
        self.selectedMarker = marker
        self.navigationState.stopNavigation()
        self.polylinePath = nil
    }
    
    func fetchDirections(to destination: CLLocationCoordinate2D, from userLocation: CLLocationCoordinate2D, destination place: MKMapItem) async {
        DispatchQueue.main.async {
            self.isLoadingDirections = true
        }
        
        do {
            let result = try await getDirections(from: userLocation, to: destination)
            
            DispatchQueue.main.async {
                self.isLoadingDirections = false
                
                // Start navigation using shared state - this will auto-show the directions panel
                self.navigationState.startNavigation(
                    directions: result.steps,
                    duration: result.totalDuration,
                    to: place
                )
                
                // Create polyline path
                let coordinates = decodePolyline(result.polylinePoints)
                let path = GMSMutablePath()
                for coordinate in coordinates {
                    path.add(coordinate)
                }
                self.polylinePath = path
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch directions: \(error.localizedDescription)"
                self.isLoadingDirections = false
            }
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
