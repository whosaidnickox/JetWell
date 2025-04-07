import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var error: Error?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.authorizationStatus = locationManager.authorizationStatus
        print("LocationService: Initialized, current authorization status: \(self.authorizationStatus.rawValue)")
    }
    
    func requestPermission() {
        print("LocationService: Requesting permission to use geolocation")
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("LocationService: Status not determined, requesting permission")
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("LocationService: Access restricted or denied")
            self.error = NSError(
                domain: "com.jetwell.location",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Разрешите доступ к геолокации в настройках для получения данных о погоде"]
            )
        case .authorizedAlways, .authorizedWhenInUse:
            print("LocationService: Access granted, starting location updates")
            startUpdating()
        @unknown default:
            print("LocationService: Unknown authorization status")
            break
        }
    }
    
    func startUpdating() {
        print("LocationService: Starting location updates")
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        print("LocationService: New coordinates received: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        self.location = newLocation
        self.error = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService: Error getting location: \(error.localizedDescription)")
        self.error = error
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("LocationService: Authorization status changed to: \(manager.authorizationStatus.rawValue)")
        self.authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("LocationService: Authorization received, starting location updates")
            startUpdating()
        case .notDetermined:
            print("LocationService: Status still not determined, requesting permission again")
            requestPermission()
        case .denied, .restricted:
            print("LocationService: Access denied or restricted")
            self.error = NSError(
                domain: "com.jetwell.location",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Разрешите доступ к геолокации в настройках для получения данных о погоде"]
            )
        @unknown default:
            print("LocationService: Unknown authorization status")
            break
        }
    }
} 