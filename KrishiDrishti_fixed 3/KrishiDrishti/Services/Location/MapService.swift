// Services/Location/MapService.swift
// KrishiDrishti — Map routing, geocoding wrappers, and searching for nearby agricultural stores

import MapKit
import CoreLocation

protocol MapServiceProtocol: Sendable {
    func searchNearbyAgriCenters(near coordinate: CLLocationCoordinate2D) async throws -> [MKMapItem]
    func calculateRoute(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute
}

final class MapService: MapServiceProtocol {
    init() {}

    func searchNearbyAgriCenters(near coordinate: CLLocationCoordinate2D) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Agricultural Center"
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)

        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    }

    func calculateRoute(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        guard let route = response.routes.first else {
            throw NSError(domain: "MapService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No routes found"])
        }
        return route
    }
}
