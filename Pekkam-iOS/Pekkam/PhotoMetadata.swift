import Foundation
import CoreLocation
import Photos
import ImageIO
import UIKit

struct PhotoMetadata {
    static func addMetadata(to photoData: Data,
                            location: CLLocation?,
                            heading: CLHeading?,
                            floor: Int?,
                            room: String?) -> Data {
        guard let imageSource = CGImageSourceCreateWithData(photoData as CFData, nil),
              let type = CGImageSourceGetType(imageSource) else {
            return photoData
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, type, 1, nil) else {
            return photoData
        }

        var properties: [String: Any] = [:]

        // GPS metadata
        if let location = location {
            let gpsDict: [String: Any] = [
                kCGImagePropertyGPSLatitude as String: abs(location.coordinate.latitude),
                kCGImagePropertyGPSLatitudeRef as String: location.coordinate.latitude >= 0 ? "N" : "S",
                kCGImagePropertyGPSLongitude as String: abs(location.coordinate.longitude),
                kCGImagePropertyGPSLongitudeRef as String: location.coordinate.longitude >= 0 ? "E" : "W",
                kCGImagePropertyGPSAltitude as String: max(0, location.altitude),
                kCGImagePropertyGPSAltitudeRef as String: location.altitude < 0 ? 1 : 0
            ]
            properties[kCGImagePropertyGPSDictionary as String] = gpsDict
        }

        // Store heading, floor, room in EXIF UserComment
        var userCommentParts: [String] = []
        if let heading = heading {
            userCommentParts.append("Heading:\(String(format: "%.1f", heading.trueHeading))")
        }
        if let floor = floor {
            userCommentParts.append("Floor:\(floor)")
        }
        if let room = room, !room.isEmpty {
            userCommentParts.append("Room:\(room)")
        }
        if !userCommentParts.isEmpty {
            properties[kCGImagePropertyExifDictionary as String] = [
                kCGImagePropertyExifUserComment as String: userCommentParts.joined(separator: ",")
            ]
        }

        // Merge with existing source properties
        let sourceProperties = (CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any]) ?? [:]
        let mergedProperties = sourceProperties.merging(properties) { _, new in new }

        CGImageDestinationAddImageFromSource(destination, imageSource, 0, mergedProperties as CFDictionary)
        CGImageDestinationFinalize(destination)

        return mutableData as Data
    }

    static func saveToAlbum(_ data: Data,
                            location: CLLocation?,
                            heading: CLHeading?,
                            floor: Int?,
                            room: String?) {
        let processedData = addMetadata(to: data, location: location, heading: heading, floor: floor, room: room)

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }

            let albumName = "Pekkam"
            var albumCollection: PHAssetCollection?

            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            albumCollection = PHAssetCollection.fetchAssetCollections(
                with: .album, subtype: .any, options: fetchOptions).firstObject

            PHPhotoLibrary.shared().performChanges({
                if albumCollection == nil {
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                }
            }) { _, _ in
                // Re-fetch after creation
                let fetchOptions2 = PHFetchOptions()
                fetchOptions2.predicate = NSPredicate(format: "title = %@", albumName)
                let collection = PHAssetCollection.fetchAssetCollections(
                    with: .album, subtype: .any, options: fetchOptions2).firstObject

                PHPhotoLibrary.shared().performChanges({
                    guard let collection = collection else { return }
                    guard let image = UIImage(data: processedData) else { return }
                    let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    if let location = location {
                        request.location = location
                    }
                    if let placeholder = request.placeholderForCreatedAsset,
                       let collectionRequest = PHAssetCollectionChangeRequest(for: collection) {
                        collectionRequest.addAssets([placeholder] as NSArray)
                    }
                })
            }
        }
    }
}
