import SwiftUI

struct ContentView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var selectedTab = 0
    @State private var showPaywall = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Label("Kamera", systemImage: "camera.fill")
                }
                .tag(0)
            
            GalleryView()
                .tabItem {
                    Label("Galleriet", systemImage: "photo.on.rectangle.angled")
                }
                .tag(1)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseManager())
}
