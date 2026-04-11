import SwiftUI

struct SettingsMenuView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    var onClose: () -> Void
    var onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "camera.aperture")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text("Pekkam")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 24)

            Divider().overlay(Color.white.opacity(0.15))

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Account / tier ───────────────────────────────
                    sectionHeader("Konto")

                    tierCard

                    if purchaseManager.currentTier != .full {
                        upgradeButton
                    }

                    sectionHeader("Funksjoner")

                    featureRow(icon: "location.fill",
                               title: "GPS-metadata",
                               subtitle: "Legger posisjon inn i bildet",
                               unlocked: purchaseManager.currentTier.hasGPS)

                    featureRow(icon: "location.north.fill",
                               title: "Kompass-data",
                               subtitle: "Retning lagres med bildet",
                               unlocked: purchaseManager.currentTier.hasCompass)

                    featureRow(icon: "map.fill",
                               title: "Kartvisning",
                               subtitle: "Se hvor bildet ble tatt",
                               unlocked: purchaseManager.currentTier.hasMapView)

                    featureRow(icon: "building.2.fill",
                               title: "Innvendig lokasjon",
                               subtitle: "Etasje og rom-informasjon",
                               unlocked: purchaseManager.currentTier.hasIndoorPanel)

                    featureRow(icon: "drop.slash.fill",
                               title: "Uten vannmerke",
                               subtitle: "Rene bilder uten logo",
                               unlocked: !purchaseManager.currentTier.hasWatermark)

                    sectionHeader("Utseende")

                    appearancePicker

                    sectionHeader("App")

                    menuRow(icon: "arrow.clockwise", title: "Gjenopprett kjøp") {
                        Task { await purchaseManager.restorePurchases() }
                    }

                    menuRow(icon: "info.circle", title: "Om Pekkam") { }

                }
                .padding(.bottom, 40)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: – Sub-views

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundColor(.white.opacity(0.45))
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 8)
    }

    private var tierCard: some View {
        HStack(spacing: 14) {
            Image(systemName: tierIcon)
                .font(.title2)
                .foregroundColor(tierColor)
                .frame(width: 40, height: 40)
                .background(tierColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(tierName)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(tierDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
    }

    private var upgradeButton: some View {
        Button(action: onUpgrade) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.black)
                Text(purchaseManager.currentTier == .compass ? "Oppgrader til Full" : "Kjøp Premium")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.black.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [Color(white: 0.96), Color(white: 0.88)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)
            .padding(.top, 10)
        }
        .buttonStyle(.plain)
    }

    private func featureRow(icon: String, title: String, subtitle: String, unlocked: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(unlocked ? .green : .white.opacity(0.3))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(unlocked ? .white : .white.opacity(0.5))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.35))
            }
            Spacer()
            Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.fill")
                .font(.caption)
                .foregroundColor(unlocked ? .green : .white.opacity(0.25))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    private func menuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 28)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: – Appearance picker

    private var appearancePicker: some View {
        let options: [(id: String, icon: String, label: String)] = [
            ("system", "circle.lefthalf.filled", "System"),
            ("light",  "sun.max.fill",           "Lyst"),
            ("dark",   "moon.fill",              "Mørkt"),
        ]
        return HStack(spacing: 0) {
            ForEach(options, id: \.id) { option in
                let isSelected = appAppearance == option.id
                Button(action: { appAppearance = option.id }) {
                    VStack(spacing: 4) {
                        Image(systemName: option.icon)
                            .font(.system(size: 15))
                            .foregroundColor(isSelected ? .black : .white)
                        Text(option.label)
                            .font(.caption2)
                            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color.white : Color.clear)
                }
                .buttonStyle(.plain)
                if option.id != options.last?.id {
                    Divider()
                        .frame(height: 30)
                        .overlay(Color.white.opacity(0.15))
                }
            }
        }
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

    // MARK: – Computed helpers

    private var tierName: String {
        switch purchaseManager.currentTier {
        case .free:    return "Gratisversjon"
        case .compass: return "Kompass-plan"
        case .full:    return "Full versjon"
        }
    }

    private var tierDescription: String {
        switch purchaseManager.currentTier {
        case .free:    return "Grunnleggende funksjoner med vannmerke"
        case .compass: return "GPS + kompass, ingen GPS-kart"
        case .full:    return "Alle funksjoner låst opp"
        }
    }

    private var tierIcon: String {
        switch purchaseManager.currentTier {
        case .free:    return "camera"
        case .compass: return "location.north.fill"
        case .full:    return "star.fill"
        }
    }

    private var tierColor: Color {
        switch purchaseManager.currentTier {
        case .free:    return .gray
        case .compass: return .blue
        case .full:    return .yellow
        }
    }
}
