import SwiftUI
import GoogleMaps
import CoreLocation
import MapKit

struct MapsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var navigationState: NavigationStateManager
    @StateObject private var locationManager = LocationManager()
    @State private var query: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMarker: GMSMarker?
    @State private var errorMessage: String?
    @State private var polylinePath: GMSPath?
    @State private var isLoadingDirections = false
    @StateObject private var locationHandler = LocationHandler()
    @State private var shouldRealignToUser = false
    
    var body: some View {
        NavigationView {
            ZStack {
                mapView
                VStack(spacing: 0) {
                    // Header with Back Button
                    HStack {
                        Button("Back") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        Spacer()
                        Text("Maps")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Text("Back")
                            .foregroundColor(.clear)
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    .background(BlurView(style: .systemMaterialDark))
                    .zIndex(2)
                    
                    searchBar
                        .padding(.top, 4)
                        .zIndex(2)
                    
                    if !searchResults.isEmpty && !navigationState.isNavigating {
                        searchResultsList
                            .zIndex(2)
                    }
                    if navigationState.isNavigating {
                        directionsPanel
                            .zIndex(2)
                    }
                    Spacer()
                }
                if let error = errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                shouldRealignToUser = true
            }
        }
    }
    
    // MARK: - Map View
    @ViewBuilder
    private var mapView: some View {
        GeometryReader { _ in
            MapViewControllerBridge(
                selectedMarker: $selectedMarker,
                polylinePath: $polylinePath,
                shouldRealignToUser: $shouldRealignToUser,
                onAnimationEnded: {},
                mapViewWillMove: { _ in },
                userLocation: $locationManager.userLocation
            )
            .cornerRadius(16)
            .padding(.horizontal, 0)
        }
    }
    // MARK: - Search Bar
    @ViewBuilder
    private var searchBar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
                .opacity(0.25)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                .frame(height: 50)
            TextField("Search places near you", text: $query)
                .onChange(of: query) { _ in searchNearbyPlaces() }
                .padding(.horizontal, 20)
                .frame(height: 50)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .frame(height: 50)
    }
    // MARK: - Search Results List
    @ViewBuilder
    private var searchResultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(searchResults, id: \.self) { place in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(place.name ?? "Unnamed")
                            .font(.headline)
                            .foregroundColor(.white)
                        if let address = place.placemark.title {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                        HStack(spacing: 16) {
                            Button("Show on Map") {
                                selectPlaceOnMap(place)
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            if locationManager.userLocation != nil {
                                Button(action: {
                                    if let userLoc = locationManager.userLocation {
                                        Task {
                                            await fetchDirections(to: place.placemark.coordinate, from: userLoc, destination: place)
                                        }
                                    }
                                }) {
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
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    Divider().background(Color.gray)
                }
            }
            .background(BlurView(style: .systemMaterialDark))
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .frame(maxHeight: 300)
    }
    // MARK: - Directions Panel
    @ViewBuilder
    private var directionsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.north.fill")
                    .foregroundColor(.blue)
                Text("Navigation Active")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("Stop") {
                    navigationState.stopNavigation()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.horizontal, 8)
            if let destination = navigationState.destination {
                HStack {
                    VStack(alignment: .leading) {
                        Text("To: \(destination.name ?? "Unknown")")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("ETA: \(navigationState.totalDuration)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(navigationState.currentDirections.count - navigationState.currentStepIndex) steps left")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
            }
            if let currentStep = navigationState.currentStep {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: directionIcon(for: currentStep.instruction))
                            .foregroundColor(.blue)
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentStep.instruction)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            HStack {
                                Text(currentStep.distance)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(currentStep.duration)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                }
            } else if navigationState.currentStepIndex >= navigationState.currentDirections.count {
                Text("🎉 You have arrived!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .background(BlurView(style: .systemMaterialDark))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    // MARK: - Helpers
    func searchNearbyPlaces() {
        guard let userLoc = locationManager.userLocation else { return }
        searchPlaces(lat: userLoc.latitude, lon: userLoc.longitude, query: query) { results in
            DispatchQueue.main.async {
                self.searchResults = results
                self.selectedMarker = nil
                self.navigationState.stopNavigation()
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
        DispatchQueue.main.async { self.isLoadingDirections = true }
        do {
            let result = try await getDirections(from: userLocation, to: destination)
            DispatchQueue.main.async {
                self.isLoadingDirections = false
                self.navigationState.startNavigation(
                    directions: result.steps,
                    duration: result.totalDuration,
                    to: place
                )
                let coordinates = decodePolyline(result.polylinePoints)
                let path = GMSMutablePath()
                for coordinate in coordinates { path.add(coordinate) }
                self.polylinePath = path
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch directions: \(error.localizedDescription)"
                self.isLoadingDirections = false
            }
        }
    }
    func directionIcon(for instruction: String) -> String {
        switch instruction.lowercased() {
        case let str where str.contains("left"): return "arrow.turn.up.left"
        case let str where str.contains("right"): return "arrow.turn.up.right"
        case let str where str.contains("straight"): return "arrow.up"
        default: return "location.fill"
        }
    }
}

// MARK: - BlurView Helper

