import Foundation
import CoreLocation

enum CompassWarning: Equatable {
    case disturbed(degrees: Double)
    case needsCalibration
}

@MainActor
class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: CLHeading?
    @Published var headingAccuracy: CLLocationDegrees = -1
    @Published var compassWarning: CompassWarning?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = 1
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
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingHeading()
    }
    
    func cardinalDirection(from degrees: CLLocationDegrees) -> String {
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        let directions = ["Nord", "Nordøst", "Øst", "Sørøst", "Sør", "Sørvest", "Vest", "Nordvest"]
        let index = Int((normalized + 22.5) / 45) % 8
        return directions[index]
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            self.heading = newHeading
            self.headingAccuracy = newHeading.headingAccuracy
            
            if newHeading.headingAccuracy < 0 {
                self.compassWarning = .needsCalibration
            } else if newHeading.headingAccuracy > 30 {
                self.compassWarning = .disturbed(degrees: newHeading.headingAccuracy)
            } else {
                self.compassWarning = nil
            }
        }
    }
    
    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        Task { @MainActor in
            self.compassWarning = .needsCalibration
        }
        return true
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("Compass error: \(error.localizedDescription)")
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
