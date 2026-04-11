import SwiftUI
import AuthenticationServices

// MARK: - Model

struct PekkamUser: Codable {
    let id: String
    var name: String
    var email: String
    let provider: String  // "apple" | "google"

    var displayName: String { name.isEmpty ? email : name }
    var providerIcon: String { provider == "apple" ? "apple.logo" : "g.circle.fill" }
}

// MARK: - AuthManager

class AuthManager: NSObject, ObservableObject {
    @Published var currentUser: PekkamUser?
    @Published var isLoading = false
    @Published var error: String?

    private let userKey = "pekkam_auth_user"

    override init() {
        super.init()
        loadStoredUser()
    }

    // MARK: Sign In with Apple

    func signInWithApple() {
        isLoading = true
        error = nil
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    // MARK: Google Sign-In (fremtidig – trenger OAuth-klient-ID fra Google Cloud Console)
    // Funksjon kalles fra SettingsMenuView. Krever GoogleSignIn SDK + klient-ID.
    // Til iOS: legg til GoogleSignIn-iOS via Swift Package Manager
    // og fyll inn GIDClientID i Info.plist.
    func signInWithGoogle() {
        // TODO: Implementer med GoogleSignIn SDK etter Google Cloud OAuth-oppsett
        // GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in ... }
        self.error = "Google-innlogging krever konfigurering av Google Cloud OAuth-klient-ID. Bruk Apple-innlogging inntil videre."
    }

    // MARK: Sign Out

    func signOut() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    // MARK: Persistence

    private func save(_ user: PekkamUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    private func loadStoredUser() {
        guard let data = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(PekkamUser.self, from: data) else { return }
        currentUser = user
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        isLoading = false
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        // Apple sender navn kun ved første innlogging – fall tilbake til lagret navn
        let parts = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }.filter { !$0.isEmpty }
        let existingName = currentUser?.name ?? ""
        let displayName = parts.isEmpty ? existingName : parts.joined(separator: " ")
        let email = credential.email ?? currentUser?.email ?? ""

        let user = PekkamUser(id: credential.user,
                              name: displayName,
                              email: email,
                              provider: "apple")
        DispatchQueue.main.async {
            self.currentUser = user
            self.save(user)
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        isLoading = false
        let nsError = error as NSError
        if nsError.code != ASAuthorizationError.canceled.rawValue {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
    }
}
