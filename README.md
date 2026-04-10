# Pekkam - Professional Camera Documentation App

Pekkam er en profesjonell dokumentasjonskamera-app for iOS og Android, designet for håndverkere og inspektører. Appen legger automatisk inn GPS, kompass, og innvendig lokasjondata i fotene dine.

## Funksjoner

### Gratis versjon
- Kamera med full kontroll
- Vannmerke på bilder ("PEKKAM PRØVEVERSJON")

### Kompass-versjon (39 kr)
- Alt fra gratis
- Kompass-pil overlay på bilder
- Fjernet vannmerke

### Full-versjon (49 kr)
- Alt fra kompass
- GPS-koordinater lagret i EXIF
- Kart-visning med 40° retningsvinkel
- Galleriet med detaljer
- Innvendig lokalisering (etasje og romnavn)

### Oppgraderinger
- Fra Kompass til Full: 10 kr

## Mappestruktur

```
Pekkam/
├── Pekkam-iOS/
│   ├── Pekkam/
│   │   ├── PekkamApp.swift
│   │   ├── ContentView.swift
│   │   ├── AppTier.swift
│   │   ├── PurchaseManager.swift
│   │   ├── GlassModifier.swift
│   │   ├── LocationManager.swift
│   │   ├── CompassManager.swift
│   │   ├── CameraManager.swift
│   │   ├── PhotoMetadata.swift
│   │   ├── ImageOverlayRenderer.swift
│   │   ├── CameraPreviewView.swift
│   │   ├── CameraView.swift
│   │   ├── IndoorAnnotationPanel.swift
│   │   ├── DirectionMapView.swift
│   │   ├── GalleryView.swift
│   │   ├── PhotoDetailView.swift
│   │   └── PaywallView.swift
│   ├── Info.plist
│   ├── Resources/
│   │   └── Assets.xcassets/
│   └── Pekkam.xcodeproj/
├── Pekkam-Android/
│   ├── app/src/main/
│   │   ├── java/com/pekkam/app/
│   │   │   ├── MainActivity.kt
│   │   │   ├── AppTier.kt
│   │   │   ├── PurchaseManager.kt
│   │   │   ├── GlassSurface.kt
│   │   │   ├── LocationRepository.kt
│   │   │   ├── CompassRepository.kt
│   │   │   ├── CameraViewModel.kt
│   │   │   ├── ImageOverlayRenderer.kt
│   │   │   ├── CameraScreen.kt
│   │   │   ├── DirectionMapScreen.kt
│   │   │   ├── GalleryScreen.kt
│   │   │   ├── PaywallScreen.kt
│   │   │   └── ui/theme/
│   │   ├── res/values/
│   │   └── AndroidManifest.xml
│   ├── app/build.gradle.kts
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   └── gradle.properties
└── README.md
```

## Setup - iOS

### Forutsetninger
- Xcode 16+
- iOS 17.0+
- Swift 5.0+

### StoreKit 2 Setup
1. Åpne Pekkam.xcodeproj i Xcode
2. Gå til Target → Signing & Capabilities
3. Legg til In-App Purchase capability
4. Konfigurer disse produkt-IDs i App Store Connect:
   - `com.pekkam.compass` (39 kr)
   - `com.pekkam.full` (49 kr)
   - `com.pekkam.upgrade_to_full` (10 kr)

### Build & Run
```bash
cd Pekkam-iOS
xcode Pekkam.xcodeproj
# Trykk Play i Xcode
```

## Setup - Android

### Forutsetninger
- Android Studio 2023.1+
- Android SDK 26+
- Kotlin 1.9+

### Google Play Billing Setup
1. Opprett Google Play-konsoll-konto
2. Opprett app-listin i Google Play
3. Konfigurer disse IAP-produktene:
   - `com.pekkam.compass` (39 kr)
   - `com.pekkam.full` (49 kr)
   - `com.pekkam.upgrade_to_full` (10 kr)

### Google Maps API Key
1. Gå til Google Cloud Console
2. Opprett API-nøkkel for Android
3. Åpne `AndroidManifest.xml`
4. Erstatt `YOUR_GOOGLE_MAPS_API_KEY` med din nøkkel

### Build & Run
```bash
cd Pekkam-Android
./gradlew build
# Åpne i Android Studio og kjør på emulator eller enhet
```

## Design System

### Farger
- **Primær**: Ocean Blue `#00B4D8`
- **Sekundær**: Dark Marine `#001B2E`
- **Accent**: Light Blue `#90CAF9`

### Glass Effect
- iOS 26+: `.glassEffect()` modifier
- iOS 17-25: `.ultraThinMaterial` fallback
- Android 12+: `blur(20.dp)` med translucent bakgrunn
- Android < 12: Translucent fallback

## Tillatelser

### iOS (Info.plist)
- NSCameraUsageDescription
- NSLocationWhenInUseUsageDescription
- NSPhotoLibraryUsageDescription
- NSPhotoLibraryAddOnlyUsageDescription

### Android (AndroidManifest.xml)
- CAMERA
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- INTERNET
- BILLING

## Foto-lagring

### iOS
Bilder lagres automatisk i "Pekkam"-albumet i Fotos-appen med EXIF-metadata:
- GPS-koordinater
- Kompass-retning
- Etasje og romnavn (hvis Full-versjon)

### Android
Bilder lagres i `DCIM/Pekkam/` med samme EXIF-metadata via ExifInterface.

## EXIF Metadata

Både iOS og Android lagrer følgende data:
- **GPSLatitude/Longitude**: Fra LocationManager/FusedLocationProvider
- **GPSAccuracy**: Nøyaktighetsestimat
- **PekkamHeading**: Kompass-retning (grader)
- **PekkamFloor**: Etasjennummer
- **PekkamRoom**: Romnavn

## In-App Purchases

### iOS (StoreKit 2)
- Automatic receipt validation
- Persistent tier storage i UserDefaults
- Restore purchases via AppStore.sync()

### Android (Google Play Billing 6.x)
- BillingClient for IAP-håndtering
- SharedPreferences for persistent tier storage
- Automatic purchase verification

## Utvikling

### iOS
- SwiftUI for UI
- @MainActor for thread safety
- async/await for async operations
- AVFoundation for kamera
- CoreLocation for GPS og kompass
- MapKit for kart

### Android
- Jetpack Compose for UI
- CameraX for kamera
- FusedLocationProviderClient for GPS
- SensorManager for kompass
- Google Maps Compose for kart
- Coroutines for async operations

## Build & Distribution

### iOS
```bash
# Archiving for App Store
xcodebuild -scheme Pekkam -configuration Release -archivePath build/Pekkam.xcarchive archive
```

### Android
```bash
# Build signed APK
cd Pekkam-Android
./gradlew assembleRelease
# Output: app/build/outputs/apk/release/app-release.apk
```

## Lisens

Proprietary - Alle rettigheter forbeholdt

## Support

For support eller spørsmål, kontakt utvikleren.
