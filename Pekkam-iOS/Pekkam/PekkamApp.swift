import SwiftUI

@main
struct PekkamApp: App {
    @StateObject var purchaseManager = PurchaseManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
        }
    }
}
