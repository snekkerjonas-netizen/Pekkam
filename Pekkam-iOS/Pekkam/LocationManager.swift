import Foundation
import CoreLocation

enum AccuracyCategory: Equatable {
    case gps      // <15m - green
    case wifi     // 15-100m - yellow
    case cell     // >100m - orange
    case none     // no signal - red
    
    init(accuracy: CLLocationAccuracy) {
        if accuracy < 0 {
            self = .none
        } else if accuracy < 15 {
            self = .gps
        } else if accuracy <= 100 {
            self = .wifi
        } else {
            self = .cell
        }
    }
    
    var color: String {
        switch self {
        case .gps: return "green"
        case .wifi: return "yellow"
        case .cell: return "orange"
        case .none: return "red"
        }
    }
}

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var accuracy: CLLocationAccuracy = -1
    @Published var floor: Int?
    @Published var accuracyCategory: AccuracyCategory = .none
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5
        requestAuthorization()
    }
    
    func requestAuthorization() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        default:
            break
        }
    }
    
    func startUpdating() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.location = location
            self.accuracy = location.horizontalAccuracy
            self.accuracyCategory = AccuracyCategory(accuracy: location.horizontalAccuracy)
            if #available(iOS 18.0, *) {
                self.floor = location.floor?.level
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Location error: \(error.localizedDescription)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdating()
            default:
                self.stopUpdating()
            }
        }
    }
}
