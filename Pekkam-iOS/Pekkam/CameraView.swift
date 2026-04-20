import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var compassManager = CompassManager()
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var appSettings: AppSettings

    @State private var showPaywall = false
    @State private var showMap = false
    @State private var showIndoorPanel = false
    @State private var showSettings = false
    @State private var floor: Int?
    @State private var room = ""

    var body: some View {
        ZStack {
            // Camera preview (full screen)
            CameraPreviewView(previewLayer: cameraManager.previewLayer)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top bar ──────────────────────────────────────────────
                topBar

                Spacer()

                // ── Zoom level selector ──────────────────────────────────
                zoomBar

                // ── Bottom control bar ───────────────────────────────────
                bottomBar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Indoor floating button (top-trailing)
            if appSettings.useIndoor(tier: purchaseManager.currentTier) {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showIndoorPanel = true }) {
                            Image(systemName: "building.2.crop.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .padding(12)
                                .glassPanel()
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 80) // clear the top bar
                    }
                    Spacer()
                }
            }

            // Settings side-drawer overlay
            if showSettings {
                settingsOverlay
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
        .sheet(isPresented: $showMap) {
            if let location = locationManager.location,
               let heading = compassManager.heading {
                DirectionMapViewWrapper(location: location, heading: heading)
            }
        }
        .sheet(isPresented: $showIndoorPanel) {
            IndoorAnnotationPanel(floor: $floor, room: $room)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // Settings / menu button
            Button(action: { withAnimation(.spring(response: 0.35)) { showSettings = true } }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            }

            // GPS indicator
            if appSettings.useGPS(tier: purchaseManager.currentTier), let _ = locationManager.location {
                HStack(spacing: 6) {
                    Circle()
                        .fill(colorForAccuracy(locationManager.accuracyCategory))
                        .frame(width: 9, height: 9)
                    Text(String(format: "±%.0fm", locationManager.accuracy))
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .glassPanel()
            }

            // Compass indicator
            if appSettings.useCompass(tier: purchaseManager.currentTier), let heading = compassManager.heading {
                HStack(spacing: 6) {
                    Image(systemName: "location.north.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(heading.trueHeading))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(format: "%.0f°", heading.trueHeading))
                            .font(.caption2).fontWeight(.bold)
                        Text(compassManager.cardinalDirection(from: heading.trueHeading))
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    if let _ = compassManager.compassWarning {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .glassPanel()
            }

            Spacer()

            // Flash button
            Button(action: { cameraManager.cycleFlash() }) {
                Image(systemName: flashIconName)
                    .font(.system(size: 20))
                    .foregroundColor(cameraManager.flashMode == .off ? .white : .yellow)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Zoom bar

    private var zoomBar: some View {
        let factors = cameraManager.availableZoomFactors

        return HStack(spacing: 8) {
            ForEach(factors, id: \.self) { factor in
                Button(action: { cameraManager.setZoom(factor) }) {
                    Text(zoomLabel(for: factor))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isActiveZoom(factor) ? .black : .white)
                        .frame(minWidth: 44, minHeight: 32)
                        .background(
                            Capsule()
                                .fill(isActiveZoom(factor)
                                      ? Color.white
                                      : Color.black.opacity(0.45))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 20) {
            // Map button
            if appSettings.useMap(tier: purchaseManager.currentTier) {
                Button(action: { showMap = true }) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.black.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
                }
            } else {
                Button(action: { showPaywall = true }) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 50, height: 50)
                        .background(Color.black.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
                }
            }

            Spacer()

            // Shutter button
            Button(action: capturePhoto) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 3)
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 66, height: 66)
                }
            }

            Spacer()

            // Flip camera button
            Button(action: { cameraManager.flipCamera() }) {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    // MARK: - Settings overlay (side drawer from left)

    private var settingsOverlay: some View {
        ZStack(alignment: .leading) {
            // Dimmed backdrop
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.spring(response: 0.35)) { showSettings = false } }

            // Drawer panel
            SettingsMenuView(
                onClose: { withAnimation(.spring(response: 0.35)) { showSettings = false } },
                onUpgrade: {
                    showSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPaywall = true
                    }
                }
            )
            .environmentObject(purchaseManager)
            .frame(width: UIScreen.main.bounds.width * 0.78)
            .background(
                // Blur + tint panel behind the content
                ZStack {
                    Color.black.opacity(0.7)
                    Color.white.opacity(0.07)
                }
                .ignoresSafeArea()
            )
            .transition(.move(edge: .leading))
        }
    }

    // MARK: - Helpers

    private var flashIconName: String {
        switch cameraManager.flashMode {
        case .on:   return "bolt.fill"
        case .auto: return "bolt.badge.a.fill"
        default:    return "bolt.slash.fill"
        }
    }

    private func zoomLabel(for factor: CGFloat) -> String {
        factor == 0.5 ? ".5×" : "\(Int(factor))×"
    }

    private func isActiveZoom(_ factor: CGFloat) -> Bool {
        abs(cameraManager.zoomFactor - factor) < 0.15
    }

    private func capturePhoto() {
        cameraManager.capturePhoto()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let photoData = cameraManager.capturedPhotoData else { return }
            var processedData = photoData

            if purchaseManager.currentTier.hasWatermark,
               let image = UIImage(data: photoData) {  // vannmerke er alltid på for gratis, ikke togglebar
                let watermarked = ImageOverlayRenderer.addWatermark(to: image)
                processedData = watermarked.jpegData(compressionQuality: 0.95) ?? photoData
            }

            if appSettings.useCompass(tier: purchaseManager.currentTier),
               let image = UIImage(data: processedData),
               let heading = compassManager.heading {
                let direction = compassManager.cardinalDirection(from: heading.trueHeading)
                let composited = ImageOverlayRenderer.addCompassOverlay(
                    to: image,
                    heading: heading.trueHeading,
                    direction: direction
                )
                processedData = composited.jpegData(compressionQuality: 0.95) ?? processedData
            }

            PhotoMetadata.saveToAlbum(
                processedData,
                location: appSettings.useGPS(tier: purchaseManager.currentTier) ? locationManager.location : nil,
                heading: appSettings.useCompass(tier: purchaseManager.currentTier) ? compassManager.heading : nil,
                floor: appSettings.useIndoor(tier: purchaseManager.currentTier) ? floor : nil,
                room: appSettings.useIndoor(tier: purchaseManager.currentTier) ? room : nil
            )
        }
    }

    private func colorForAccuracy(_ category: AccuracyCategory) -> Color {
        switch category {
        case .gps:  return .green
        case .wifi: return .yellow
        case .cell: return .orange
        case .none: return .red
        }
    }
}
