import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0, green: 0.11, blue: 0.18)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
                
                // Logo
                VStack(spacing: 8) {
                    Text("PEKKAM")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    Text("Dokumenterings kamera")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Tier cards
                ScrollView {
                    VStack(spacing: 12) {
                        TierCard(
                            title: "Gratis",
                            price: "0 kr",
                            features: ["Kamera", "Vannmerke"],
                            isSelected: purchaseManager.currentTier == .free,
                            isActive: true
                        ) { }
                        
                        TierCard(
                            title: "Kompass",
                            price: "39 kr",
                            features: ["Kamera", "Kompass overlay", "Uten vannmerke"],
                            isSelected: purchaseManager.currentTier == .compass,
                            isActive: purchaseManager.currentTier.rawValue <= "compass"
                        ) {
                            Task {
                                try? await purchaseManager.purchase("com.pekkam.compass")
                            }
                        }
                        
                        TierCard(
                            title: "Full",
                            price: "49 kr",
                            features: ["Alle Kompass funksjoner", "GPS i EXIF", "Kart visning", "Galleriet detaljer", "Innvendig panel"],
                            isSelected: purchaseManager.currentTier == .full,
                            isActive: purchaseManager.currentTier == .free
                        ) {
                            Task {
                                try? await purchaseManager.purchase("com.pekkam.full")
                            }
                        }
                    }
                }
                
                // Upgrade button for compass users
                if purchaseManager.currentTier == .compass {
                    Button(action: {
                        Task {
                            try? await purchaseManager.purchase("com.pekkam.upgrade_to_full")
                        }
                    }) {
                        Text("Oppgrader til Full (10 kr)")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color(red: 0, green: 0.71, blue: 0.85))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(16)
                }
                
                Spacer()
                
                // Restore purchases
                Button(action: {
                    Task {
                        await purchaseManager.restorePurchases()
                    }
                }) {
                    Text("Gjenopprett kjøp")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(16)
            }
        }
    }
}

struct TierCard: View {
    let title: String
    let price: String
    let features: [String]
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(price)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0, green: 0.71, blue: 0.85))
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundColor(Color(red: 0, green: 0.71, blue: 0.85))
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            
            if isActive && !isSelected {
                Button(action: action) {
                    Text("Kjøp")
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color(red: 0, green: 0.71, blue: 0.85))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .border(
            isSelected ? Color(red: 0, green: 0.71, blue: 0.85) : Color.white.opacity(0.1),
            width: isSelected ? 2 : 1
        )
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}
