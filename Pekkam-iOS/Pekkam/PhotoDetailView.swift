import SwiftUI
import Photos
import MapKit
import CoreLocation

struct PhotoDetailView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    @State private var location: CLLocation?
    @State private var heading: Double?
    @State private var direction: String?
    @State private var floor: Int?
    @State private var room: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let location = location {
                        Section(header: Text("GPS").font(.headline)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Breddegrad:")
                                    Spacer()
                                    Text(String(format: "%.6f", location.coordinate.latitude))
                                        .monospaced()
                                }
                                HStack {
                                    Text("Lengdegrad:")
                                    Spacer()
                                    Text(String(format: "%.6f", location.coordinate.longitude))
                                        .monospaced()
                                }
                                HStack {
                                    Text("Nøyaktighet:")
                                    Spacer()
                                    Text(String(format: "±%.0f m", location.horizontalAccuracy))
                                }
                            }
                            .font(.caption)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    if let heading = heading, let direction = direction {
                        Section(header: Text("Kompass").font(.headline)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Retning:")
                                    Spacer()
                                    Text(String(format: "%.0f° %@", heading, direction))
                                }
                            }
                            .font(.caption)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    if let floor = floor {
                        Section(header: Text("Innvendig").font(.headline)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Etasje:")
                                    Spacer()
                                    Text(String(floor))
                                }
                                if let room = room, !room.isEmpty {
                                    HStack {
                                        Text("Rom:")
                                        Spacer()
                                        Text(room)
                                    }
                                }
                            }
                            .font(.caption)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    if let location = location {
                        Section(header: Text("Kart").font(.headline)) {
                            MapSnapshot(coordinate: location.coordinate)
                                .frame(height: 200)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadPhotoDetails)
    }
    
    private func loadPhotoDetails() {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .default,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                self.image = image
            }
        }
        
        location = asset.location

        // Try to extract EXIF metadata
        let exifOptions = PHImageRequestOptions()
        exifOptions.isSynchronous = false
        exifOptions.isNetworkAccessAllowed = false
        PHImageManager.default().requestImageDataAndOrientation(
            for: asset,
            options: exifOptions
        ) { data, _, _, _ in
            // Metadata extraction placeholder - heading/floor stored in UserComment
        }
    }
}

struct MapSnapshot: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Text("Kart")
                .foregroundColor(.gray)
        }
    }
}
