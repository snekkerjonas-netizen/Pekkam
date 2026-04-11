import SwiftUI
import Combine

/// Brukerens valg om hvilke opplåste funksjoner som er aktive.
/// Kan slås av/på i sidemenyen uavhengig av kjøpt abonnement.
class AppSettings: ObservableObject {
    @AppStorage("setting_gps")      var gpsActive:     Bool = true
    @AppStorage("setting_compass")  var compassActive: Bool = true
    @AppStorage("setting_map")      var mapActive:     Bool = true
    @AppStorage("setting_indoor")   var indoorActive:  Bool = true

    /// Helpers: kombinerer "abonnementet gir tilgang" + "brukeren har skrudd den på"
    func useGPS(tier: AppTier)     -> Bool { tier.hasGPS          && gpsActive     }
    func useCompass(tier: AppTier) -> Bool { tier.hasCompass       && compassActive }
    func useMap(tier: AppTier)     -> Bool { tier.hasMapView       && mapActive     }
    func useIndoor(tier: AppTier)  -> Bool { tier.hasIndoorPanel   && indoorActive  }
}
