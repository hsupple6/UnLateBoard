//
//  CoordGetter.swift
//  UnLateBoard
//
//  Created by Hayden Supple on 6/21/25.
//
import CoreLocation

class LocationHandler: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let locationManager = CLLocationManager()
    var currentCoordinate: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Delegate method called when location updates arrive
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        
        currentCoordinate = latestLocation.coordinate
        
        print("Latitude: \(latestLocation.coordinate.latitude), Longitude: \(latestLocation.coordinate.longitude)")
        
    }
    func isNear(to coordinate: CLLocationCoordinate2D, within meters: Double) -> Bool {
        guard let current = currentCoordinate else {
            print("Current location unknown")
            return false
        }
        
        let currentLocation = CLLocation(latitude: current.latitude, longitude: current.longitude)
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        let distance = currentLocation.distance(from: targetLocation) // meters
        
        print("Distance to target: \(distance) meters")
        return distance <= meters
    }
}
