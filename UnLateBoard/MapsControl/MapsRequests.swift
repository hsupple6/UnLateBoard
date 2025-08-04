//
//  MapsRequests.swift
//  UnLateBoard
//
//  Created by Hayden Supple on 6/21/25.
//

import CoreLocation
import GoogleMaps

func getDirections(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async throws -> (steps: [DirectionStep], polylinePoints: String, totalDuration: String) {
    let API_KEY = "AIzaSyA1FLqbSOzAkxXpy1PxN0205kcQeicBTbY" // Replace with your Google Maps Directions API key

    let urlStr = "https://maps.googleapis.com/maps/api/directions/json?origin=\(start.latitude),\(start.longitude)&destination=\(end.latitude),\(end.longitude)&mode=walking&key=\(API_KEY)"
    
    guard let url = URL(string: urlStr) else {
        throw URLError(.badURL)
    }

    let (data, _) = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(DirectionsResponse.self, from: data)
    
    guard let firstRoute = response.routes.first,
          let firstLeg = firstRoute.legs.first else {
        return (steps: [], polylinePoints: "", totalDuration: "0")
    }
    
    var steps: [DirectionStep] = []
    for step in firstLeg.steps {
        let cleanInstruction = step.html_instructions.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        steps.append(DirectionStep(latitude: step.start_location.lat,
                                   longitude: step.start_location.lng,
                                   instruction: cleanInstruction,
                                   distance: step.distance.text,
                                   duration: step.duration.text))
    }
    
    return (steps: steps, polylinePoints: firstRoute.overview_polyline.points, totalDuration: firstLeg.duration.text)
}

func decodePolyline(_ encoded: String) -> [CLLocationCoordinate2D] {
    var coords = [CLLocationCoordinate2D]()
    var index = encoded.startIndex
    var lat = 0
    var lon = 0
    
    while index < encoded.endIndex {
        var b: Int
        var shift = 0
        var result = 0
        
        repeat {
            b = Int(encoded[index].asciiValue ?? 63) - 63
            result |= (b & 0x1F) << shift
            shift += 5
            index = encoded.index(after: index)
        } while b >= 0x20 && index < encoded.endIndex
        
        let deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
        lat += deltaLat
        
        shift = 0
        result = 0
        
        repeat {
            b = Int(encoded[index].asciiValue ?? 63) - 63
            result |= (b & 0x1F) << shift
            shift += 5
            index = encoded.index(after: index)
        } while b >= 0x20 && index < encoded.endIndex
        
        let deltaLon = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
        lon += deltaLon
        
        let finalLat = Double(lat) * 1e-5
        let finalLon = Double(lon) * 1e-5
        
        coords.append(CLLocationCoordinate2D(latitude: finalLat, longitude: finalLon))
    }
    
    return coords
}

func fetchDirections(to destination: CLLocationCoordinate2D, from userLocation: CLLocationCoordinate2D) async throws -> (steps: [DirectionStep], path: GMSMutablePath) {
    let result = try await getDirections(from: userLocation, to: destination)
    
    let coordinates = decodePolyline(result.polylinePoints)
    let path = GMSMutablePath()
    for coordinate in coordinates {
        path.add(coordinate)
    }
    
    return (steps: result.steps, path: path)
}

private struct DirectionsResponse: Codable {
    struct Route: Codable {
        struct Leg: Codable {
            struct Step: Codable {
                let html_instructions: String
                let distance: Distance
                let duration: Duration
                let start_location: Location
                let end_location: Location
                let polyline: Polyline
                
                struct Distance: Codable { let text: String }
                struct Duration: Codable { let text: String }
                struct Location: Codable { let lat: Double, lng: Double }
                struct Polyline: Codable { let points: String }
            }

            let steps: [Step]
            let distance: Distance
            let duration: Duration

            struct Distance: Codable { let text: String }
            struct Duration: Codable { let text: String }
        }

        let legs: [Leg]
        let overview_polyline: OverviewPolyline

        struct OverviewPolyline: Codable {
            let points: String
        }
    }

    let routes: [Route]
}
