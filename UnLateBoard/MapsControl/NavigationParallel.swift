//
//  NavigationParallel.swift
//  UnLateBoard
//
//  Created by Hayden Supple on 6/22/25.
//

import SwiftUI
import CoreLocation
import MapKit

// MARK: - Shared Navigation State Manager
class NavigationStateManager: ObservableObject {
    
    @Published var currentDirections: [DirectionStep] = []
    @Published var isNavigating: Bool = false
    @Published var totalDuration: String = ""
    @Published var currentStepIndex: Int = 0
    @Published var destination: MKMapItem?
    @Published var startHeading: Double = 0
    
    var locationManager = LocationManager()
    
    func startNavigation(directions: [DirectionStep], duration: String, to destination: MKMapItem) {
        DispatchQueue.main.async {
            self.currentDirections = directions
            self.totalDuration = duration
            self.isNavigating = true
            self.currentStepIndex = 0
            self.destination = destination
        }
    }
    
    func stopNavigation() {
        DispatchQueue.main.async {
            self.currentDirections = []
            self.isNavigating = false
            self.totalDuration = ""
            self.currentStepIndex = 0
            self.destination = nil
        }
    }
    
    func advanceToNextStep() {
        DispatchQueue.main.async {
            if self.currentStepIndex < self.currentDirections.count - 1 {
                self.currentStepIndex += 1
            }
        }
    }
    
    func calcInitHeading() {
        guard let currentLocation = locationManager.userLocation else {
            print("Current location not available")
            return
        }
        
        // Convert degrees to radians
        let lat1 = currentLocation.latitude * .pi / 180
        let lon1 = currentLocation.longitude * .pi / 180
        let lat2 = currentDirections[0].latitude * .pi / 180
        let lon2 = currentDirections[0].longitude * .pi / 180
        
        let deltaLon = lon2 - lon1
        
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let initialBearingRadians = atan2(y, x)
        
        // Convert to degrees
        var initialBearingDegrees = initialBearingRadians * 180 / .pi
        
        // Normalize to 0-360 degrees
        initialBearingDegrees = (initialBearingDegrees + 360).truncatingRemainder(dividingBy: 360)
        DispatchQueue.main.async {
            self.startHeading = initialBearingDegrees
        }
        print("Initial bearing: \(initialBearingDegrees)°")
    }
    
    var currentStep: DirectionStep? {
        if currentStepIndex == 1 { calcInitHeading() }
        guard currentStepIndex < currentDirections.count else { return nil }
        return currentDirections[currentStepIndex]
    }
    
    var hasMoreSteps: Bool {
        return currentStepIndex < currentDirections.count
    }
}
