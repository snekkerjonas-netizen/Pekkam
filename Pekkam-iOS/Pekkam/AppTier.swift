import Foundation

enum AppTier: String, Codable {
    case free
    case compass
    case full

    var hasCompass: Bool { self == .compass || self == .full }
    var hasGPS: Bool { self == .full }
    var hasMapView: Bool { self == .full }
    var hasGalleryDetail: Bool { self == .full }
    var hasIndoorPanel: Bool { self == .full }
    var hasWatermark: Bool { self == .free }
}
