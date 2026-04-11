import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var compassManager = CompassManager()
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @State private var showPaywall = false
    @State private var showMap = false
    @State private var showIndoorPanel = false
    @State private var floor: Int?
    @State private var room = ""
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(previewLayer: cameraManager.previewLayer)
                .ignoresSafeArea()
            
            VStack {
                // Top HUD with GPS and Compass
                if purchaseManager.currentTier.hasGPS || purchaseManager.currentTier.hasCompass {
                    HStack(spacing: 16) {
                        // GPS indicator
                        if purchaseManager.currentTier.hasGPS, let location = locationManager.location {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(colorForAccuracy(locationManager.accuracyCategory))
                                    .frame(width: 10, height: 10)
                                Text(String(format: "±%.0fm", locationManager.accuracy))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            .padding(8)
                            .glassPanel()
                        }
                        
                        // Compass indicator
                        if purchaseManager.currentTier.hasCompass, let heading = compassManager.heading {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(format: "%.0f°", heading.trueHeading))
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                    Text(compassManager.cardinalDirection(from: heading.trueHeading))
                                        .font(.caption2)
                                }
                                
                                if let warning = compassManager.compassWarning {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                            }
                            .padding(8)
                            .glassPanel()
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                }
                
                Spacer()
                
                // Bottom control bar
                HStack(spacing: 20) {
                    // Map button
                    if purchaseManager.currentTier.hasMapView {
                        Button(action: { showMap = true }) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    } else {
                        Button(action: { showPaywall = true }) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Shutter button
                    Button(action: capturePhoto) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                    .frame(width: 80, height: 80)
                            )
                    }
                    
                    Spacer()
                    
                    // Flip camera button
                    Button(action: { cameraManager.flipCamera() }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
            }
            .padding(12)
            
            // Indoor button (floating)
            if locationManager.floor != nil || purchaseManager.currentTier.hasIndoorPanel {
                VStack {
                    HStack {
                        Spacer()
                        if purchaseManager.currentTier.hasIndoorPanel {
                            Button(action: { showIndoorPanel = true }) {
                                Image(systemName: "building.2.crop.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .glassPanel()
                            }
                        }
                    }
                    .padding(12)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
        .sheet(isPresented: $showMap) {
            if let location = locationManager.location, let heading = compassManager.heading {
                DirectionMapViewWrapper(location: location, heading: heading)
            }
        }
        .sheet(isPresented: $showIndoorPanel) {
            IndoorAnnotationPanel(floor: $floor, room: $room)
        }
    }
    
    private func capturePhoto() {
        cameraManager.capturePhoto()
        
        if let photoData = cameraManager.capturedPhotoData {
            var processedData = photoData
            
            // Add watermark if free tier
            if purchaseManager.currentTier.hasWatermark,
               let image = UIImage(data: photoData) {
                let watermarkedImage = ImageOverlayRenderer.addWatermark(to: image)
                processedData = watermarkedImage.jpegData(compressionQuality: 0.95) ?? photoData
            }
            
            // Add compass overlay if has compass
            if purchaseManager.currentTier.hasCompass,
               let image = UIImage(data: processedData),
               let heading = compassManager.heading {
                let direction = compassManager.cardinalDirection(from: heading.trueHeading)
                let compassedImage = ImageOverlayRenderer.addCompassOverlay(
                    to: image,
                    heading: heading.trueHeading,
                    direction: direction
                )
                processedData = compassedImage.jpegData(compressionQuality: 0.95) ?? processedData
            }
            
            // Save to album
            PhotoMetadata.saveToAlbum(
                processedData,
                location: purchaseManager.currentTier.hasGPS ? locationManager.location : nil,
                heading: purchaseManager.currentTier.hasCompass ? compassManager.heading : nil,
                floor: purchaseManager.currentTier.hasIndoorPanel ? floor : nil,
                room: purchaseManager.currentTier.hasIndoorPanel ? room : nil
            )
        }
    }
    
    private func colorForAccuracy(_ category: AccuracyCategory) -> Color {
        switch category {
        case .gps: return .green
        case .wifi: return .yellow
        case .cell: return .orange
        case .none: return .red
        }
    }
}
