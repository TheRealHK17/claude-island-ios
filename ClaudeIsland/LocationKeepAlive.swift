import CoreLocation
import Foundation

/// Optional second keep-alive. Asks iOS for very coarse background location updates,
/// which keeps the app running. The locations themselves are ignored and never stored or sent anywhere.
final class LocationKeepAlive: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var wanted = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = 3000
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
    }

    func start() {
        wanted = true
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func stop() {
        wanted = false
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if wanted {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
