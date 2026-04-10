import Foundation
import CoreLocation
import Photos
import ImageIO

struct PhotoMetadata {
    static func addMetadata(to photoData: Data, 
                           location: CLLocation?,
                           heading: CLHeading?,
                           floor: Int?,
                           room: String?) -> Data {
        guard let imageSource = CGImageSourceCreateWithData(photoData as CFData, nil),
              let type = CGImageSourceGetType(imageSource),
              let mutableData = NSMutableData(data: photoData) else {
            return photoData
        }
        
        let metadata = CGImageSourceCopyMetadataAtIndex(imageSource, 0, nil)
        let mutableMetadata = CGImageMetadataCreateMutableCopy(metadata)
        
        if let mutableMetadata = mutableMetadata {
            // Add GPS metadata
            if let location = location {
                let gpsMetadata: [String: Any] = [
                    kCGImagePropertyGPSLatitude as String: abs(location.coordinate.latitude),
                    kCGImagePropertyGPSLatitudeRef as String: location.coordinate.latitude >= 0 ? "N" : "S",
                    kCGImagePropertyGPSLongitude as String: abs(location.coordinate.longitude),
                    kCGImagePropertyGPSLongitudeRef as String: location.coordinate.longitude >= 0 ? "E" : "W",
                    kCGImagePropertyGPSAltitude as String: location.altitude,
                    kCGImagePropertyGPSHorizontalAccuracy as String: location.horizontalAccuracy,
                ]
                CGImageMetadataSetValueWithPath(mutableMetadata, nil, 
                    kCGImagePropertyGPSDictionary as String, gpsMetadata as CFDictionary)
            }
            
            // Add EXIF metadata with heading and floor/room
            if let heading = heading {
                var exifDict = [String: Any]()
                exifDict["PekkamHeading"] = heading.trueHeading
                exifDict["PekkamHeadingAccuracy"] = heading.headingAccuracy
                if let floor = floor {
                    exifDict["PekkamFloor"] = floor
                }
                if let room = room {
                    exifDict["PekkamRoom"] = room
                }
                CGImageMetadataSetValueWithPath(mutableMetadata, nil,
                    kCGImagePropertyExifDictionary as String, exifDict as CFDictionary)
            }
        }
        
        if let destination = CGImageDestinationCreateWithData(mutableData, type, 1, nil) {
            CGImageDestinationAddImageFromSource(destination, imageSource, 0, mutableMetadata)
            CGImageDestinationFinalize(destination)
        }
        
        return mutableData as Data
    }
    
    static func saveToAlbum(_ data: Data,
                           location: CLLocation?,
                           heading: CLHeading?,
                           floor: Int?,
                           room: String?) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            let albumName = "Pekkam"
            var albumCollection: PHAssetCollection?
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            if let collection = PHAssetCollection.fetchAssetCollections(
                with: .album, subtype: .any, options: fetchOptions).firstObject {
                albumCollection = collection
            }
            
            PHPhotoLibrary.shared().performChanges({
                if let collection = albumCollection {
                    self.saveImage(data, to: collection, location: location, heading: heading, floor: floor, room: room)
                } else {
                    var albumCollectionPlaceholder: PHObjectPlaceholder?
                    let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                        withTitle: albumName)
                    albumCollectionPlaceholder = changeRequest.placeholderForCreatedAssetCollection
                    
                    if let placeholder = albumCollectionPlaceholder {
                        if let collection = PHAssetCollection.fetchAssetCollections(
                            withLocalIdentifiers: [placeholder.localIdentifier], options: nil).firstObject {
                            self.saveImage(data, to: collection, location: location, heading: heading, floor: floor, room: room)
                        }
                    }
                }
            })
        }
    }
    
    private static func saveImage(_ data: Data,
                                  to collection: PHAssetCollection,
                                  location: CLLocation?,
                                  heading: CLHeading?,
                                  floor: Int?,
                                  room: String?) {
        let changeRequest = PHAssetChangeRequest.creationRequestForAsset(from: UIImage(data: data) ?? UIImage())
        
        if let assetPlaceholder = changeRequest.placeholderForCreatedAsset {
            if let collectionChangeRequest = PHAssetCollectionChangeRequest(for: collection) {
                collectionChangeRequest.addAssets([assetPlaceholder] as NSArray)
            }
            
            // Add location metadata
            if let location = location {
                changeRequest.location = location
            }
        }
    }
}
