import SwiftUI

@main
struct PekkamApp: App {
    @StateObject var purchaseManager = PurchaseManager()
    @StateObject var appSettings = AppSettings()
    @StateObject var authManager = AuthManager()
    @AppStorage("appAppearance") var appAppearance: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .environmentObject(appSettings)
                .environmentObject(authManager)
                .preferredColorScheme(colorScheme(for: appAppearance))
        }
    }

    private func colorScheme(for value: String) -> ColorScheme? {
        switch value {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil   // nil = følg systemet
        }
    }
}
