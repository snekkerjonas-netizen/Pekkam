import SwiftUI

struct SettingsMenuView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    var onClose: () -> Void
    var onUpgrade: () -> Void

    // DEV MODE – fjernes før lansering
    @State private var titleTapCount = 0
    @State private var showDevBanner = false
    // END DEV MODE

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "camera.aperture")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                // DEV MODE – trykk 5 ganger for å låse opp Full (fjernes før lansering)
                Text("Pekkam")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .onTapGesture {
                        titleTapCount += 1
                        if titleTapCount >= 5 {
                            titleTapCount = 0
                            purchaseManager.devModeUnlock()
                            showDevBanner = true
                        }
                    }
                // END DEV MODE
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, purchaseManager.devModeActive ? 8 : 24)

            // DEV MODE banner – fjernes før lansering
            if purchaseManager.devModeActive || showDevBanner {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.fill")
                    Text("DEV: Full-versjon aktiv")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.yellow)
                .padding(.bottom, 8)
            }
            // END DEV MODE

            Divider().overlay(Color.white.opacity(0.15))

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Innlogging ────────────────────────────────────
                    sectionHeader("Konto")
                    authSection

                    Divider()
                        .overlay(Color.white.opacity(0.12))
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                    // ── Abonnement ────────────────────────────────────
                    sectionHeader("Abonnement")

                    tierCard

                    if purchaseManager.currentTier != .full {
                        upgradeButton
                    }

                    sectionHeader("Aktive funksjoner")

                    featureToggle(
                        icon: "location.fill",
                        title: "GPS-metadata",
                        subtitle: "Legger posisjon inn i bildet",
                        unlocked: purchaseManager.currentTier.hasGPS,
                        isOn: $appSettings.gpsActive
                    )
                    featureToggle(
                        icon: "location.north.fill",
                        title: "Kompass-data",
                        subtitle: "Retning lagres med bildet",
                        unlocked: purchaseManager.currentTier.hasCompass,
                        isOn: $appSettings.compassActive
                    )
                    featureToggle(
                        icon: "map.fill",
                        title: "Kartvisning",
                        subtitle: "Vis kart over hvor bildet ble tatt",
                        unlocked: purchaseManager.currentTier.hasMapView,
                        isOn: $appSettings.mapActive
                    )
                    featureToggle(
                        icon: "building.2.fill",
                        title: "Innvendig lokasjon",
                        subtitle: "Etasje og rom-informasjon",
                        unlocked: purchaseManager.currentTier.hasIndoorPanel,
                        isOn: $appSettings.indoorActive
                    )
                    featureRow(
                        icon: "drop.slash.fill",
                        title: "Uten vannmerke",
                        subtitle: "Rene bilder uten logo",
                        unlocked: !purchaseManager.currentTier.hasWatermark
                    )

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

    private func featureToggle(icon: String, title: String, subtitle: String, unlocked: Bool, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(unlocked ? .blue : .white.opacity(0.3))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(unlocked ? .white : .white.opacity(0.45))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.35))
            }
            Spacer()
            if unlocked {
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(.blue)
            } else {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.2))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .disabled(!unlocked)
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

    // MARK: – Auth section

    private var authSection: some View {
        Group {
            if let user = authManager.currentUser {
                // Logged in state
                HStack(spacing: 14) {
                    Image(systemName: user.providerIcon)
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        Text(user.email.isEmpty ? user.provider.capitalized : user.email)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 6)

                HStack(spacing: 10) {
                    // Synk kjøp (restore)
                    Button(action: { Task { await purchaseManager.restorePurchases() } }) {
                        Label("Synk kjøp", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: { authManager.signOut() }) {
                        Text("Logg ut")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.red.opacity(0.85))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

            } else {
                // Not logged in
                if let err = authManager.error {
                    Text(err)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 6)
                }

                VStack(spacing: 10) {
                    // Sign in with Apple
                    Button(action: { authManager.signInWithApple() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Logg inn med Apple")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(authManager.isLoading)

                    // Sign in with Google
                    Button(action: { authManager.signInWithGoogle() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Logg inn med Google")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.26, green: 0.52, blue: 0.96))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(authManager.isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

                Text("Logg inn for å synkronisere kjøpene dine på tvers av enheter.")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)
            }
        }
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
