import SwiftUI
import Photos

struct GalleryView: View {
    @State private var assets: [PHAsset] = []
    @State private var selectedAsset: PHAsset?
    @Environment(\.displayScale) var displayScale
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(assets, id: \.localIdentifier) { asset in
                        NavigationLink(destination: PhotoDetailView(asset: asset)) {
                            AssetThumbnailView(asset: asset)
                                .frame(height: 100)
                                .clipped()
                        }
                    }
                }
                .padding(12)
            }
            .navigationTitle("Galleriet")
            .onAppear(perform: fetchAssets)
        }
    }
    
    private func fetchAssets() {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        
        let albumFetch = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any, options: PHFetchOptions()
        )
        
        var pekkamAssets: [PHAsset] = []
        albumFetch.enumerateObjects { collection, _, _ in
            if collection.localizedTitle == "Pekkam" {
                let assetsFetch = PHAsset.fetchAssets(in: collection, options: options)
                assetsFetch.enumerateObjects { asset, _, _ in
                    pekkamAssets.append(asset)
                }
            }
        }
        
        self.assets = pekkamAssets.sorted { $0.creationDate ?? Date() > $1.creationDate ?? Date() }
    }
}

struct AssetThumbnailView: View {
    let asset: PHAsset
    @State private var image: Image?
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
            }
        }
        .onAppear(perform: loadThumbnail)
    }
    
    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 100, height: 100),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.image = Image(uiImage: image)
                }
            }
        }
    }
}
