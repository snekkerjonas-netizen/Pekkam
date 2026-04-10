import SwiftUI
import MapKit
import CoreLocation

struct DirectionMapView: UIViewRepresentable {
    let location: CLLocation
    let heading: CLHeading
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.zoomEnabled = true
        mapView.scrollEnabled = true
        
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(region, animated: true)
        
        // Draw 40-degree cone
        let angle = heading.trueHeading
        let radius = 500.0 // meters
        
        let angleRad = (angle * .pi) / 180.0
        let coneAngle = 20.0 * .pi / 180.0 // 40 degrees total = 20 each side
        
        let left = angleRad - coneAngle
        let right = angleRad + coneAngle
        
        let leftLat = location.coordinate.latitude + (cos(left) * (radius / 111000))
        let leftLon = location.coordinate.longitude + (sin(left) * (radius / 111000))
        
        let rightLat = location.coordinate.latitude + (cos(right) * (radius / 111000))
        let rightLon = location.coordinate.longitude + (sin(right) * (radius / 111000))
        
        let points = [
            location.coordinate,
            CLLocationCoordinate2D(latitude: leftLat, longitude: leftLon),
            CLLocationCoordinate2D(latitude: rightLat, longitude: rightLon),
            location.coordinate
        ]
        
        let polygon = MKPolygon(coordinates: points, count: points.count)
        polygon.title = "Direction Cone"
        mapView.addOverlay(polygon)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        uiView.setRegion(region, animated: true)
    }
}

struct DirectionMapViewWrapper: View {
    let location: CLLocation
    let heading: CLHeading
    
    var body: some View {
        DirectionMapView(location: location, heading: heading)
            .ignoresSafeArea()
    }
}
