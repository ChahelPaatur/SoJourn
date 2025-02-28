import SwiftUI
import UIKit
import CoreLocation
import MapboxMaps

// Structure to define map markers
struct MapMarker {
    let coordinate: CLLocationCoordinate2D
    let title: String
}

// Implementation using Mapbox Maps SDK
struct MapboxMapView: UIViewRepresentable {
    var centerCoordinate: CLLocationCoordinate2D
    var zoomLevel: Double
    var markers: [MapMarker]
    var routeCoordinates: [CLLocationCoordinate2D]
    
    func makeUIView(context: Context) -> MapView {
        // Configure the map view with a simpler initialization
        let options = MapInitOptions(cameraOptions: CameraOptions(center: centerCoordinate, zoom: zoomLevel))
        let mapView = MapView(frame: .zero, mapInitOptions: options)
        mapView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        
        // Add the markers to the map
        addMarkersToMap(mapView)
        
        // Add the route to the map if there are coordinates
        if !routeCoordinates.isEmpty {
            addRouteToMap(mapView)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapView, context: Context) {
        // Update the camera position if needed
        mapView.camera.ease(to: CameraOptions(center: centerCoordinate, zoom: zoomLevel), duration: 0.5)
        
        // Clear existing annotations and add updated markers
        clearAnnotations(mapView)
        addMarkersToMap(mapView)
        
        // Add updated route
        if !routeCoordinates.isEmpty {
            addRouteToMap(mapView)
        }
    }
    
    private func addMarkersToMap(_ mapView: MapView) {
        // Create a point annotation manager
        let pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        
        // Create point annotations for each marker
        var pointAnnotations: [PointAnnotation] = []
        
        for marker in markers {
            var pointAnnotation = PointAnnotation(coordinate: marker.coordinate)
            pointAnnotation.textField = marker.title
            pointAnnotation.textColor = StyleColor(.black)
            pointAnnotation.textHaloColor = StyleColor(.white)
            pointAnnotation.textHaloWidth = 1.0
            
            // Use simple color-based styling that works in all versions
            pointAnnotation.iconColor = StyleColor(.blue)
            pointAnnotation.iconSize = 1.5
            
            pointAnnotations.append(pointAnnotation)
        }
        
        // Add the annotations to the manager
        pointAnnotationManager.annotations = pointAnnotations
    }
    
    private func addRouteToMap(_ mapView: MapView) {
        // Create a polyline annotation manager
        let polylineAnnotationManager = mapView.annotations.makePolylineAnnotationManager()
        
        // Create a polyline annotation for the route
        var polylineCoordinates: [CLLocationCoordinate2D] = []
        for coordinate in routeCoordinates {
            polylineCoordinates.append(coordinate)
        }
        
        var polylineAnnotation = PolylineAnnotation(lineCoordinates: polylineCoordinates)
        polylineAnnotation.lineColor = StyleColor(.blue)
        polylineAnnotation.lineWidth = 3.0
        
        // Add the annotation to the manager
        polylineAnnotationManager.annotations = [polylineAnnotation]
    }
    
    private func clearAnnotations(_ mapView: MapView) {
        // Since we can't access annotation managers directly, create new ones 
        // and set them to empty arrays
        
        // Clear point annotations if we have any
        let pointManager = mapView.annotations.makePointAnnotationManager()
        pointManager.annotations = []
        
        // Clear polyline annotations if we have any
        let polylineManager = mapView.annotations.makePolylineAnnotationManager()
        polylineManager.annotations = []
    }
    
    // Coordinator for handling map interactions
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: MapboxMapView
        
        init(_ parent: MapboxMapView) {
            self.parent = parent
        }
    }
}

// Preview
struct MapboxMapView_Previews: PreviewProvider {
    static var previews: some View {
        MapboxMapView(
            centerCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            zoomLevel: 12.0,
            markers: [
                MapMarker(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), title: "San Francisco"),
                MapMarker(coordinate: CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783), title: "Golden Gate Bridge")
            ],
            routeCoordinates: [
                CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                CLLocationCoordinate2D(latitude: 37.8199, longitude: -122.4783)
            ]
        )
        .frame(height: 300)
    }
} 
