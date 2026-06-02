// Services/Location/LocationManager.swift
// KrishiDrishti — Live location tracking and reverse geocoding

import CoreLocation
import Combine

protocol LocationManagerProtocol: Sendable {
    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }
    var authStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }
    func requestAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> CLPlacemark?
}

final class LocationManager: NSObject, LocationManagerProtocol, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    private let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    private let authStatusSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)

    var locationPublisher: AnyPublisher<CLLocation?, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    var authStatusPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        authStatusSubject.eraseToAnyPublisher()
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authStatusSubject.send(locationManager.authorizationStatus)
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> CLPlacemark? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return try await geocoder.reverseGeocodeLocation(location).first
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            locationSubject.send(location)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatusSubject.send(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
