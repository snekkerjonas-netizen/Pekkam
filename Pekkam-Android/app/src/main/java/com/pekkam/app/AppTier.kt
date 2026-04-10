package com.pekkam.app

sealed class AppTier(
    val hasCompass: Boolean,
    val hasGPS: Boolean,
    val hasMapView: Boolean,
    val hasGalleryDetail: Boolean,
    val hasIndoorPanel: Boolean,
    val hasWatermark: Boolean
) {
    object Free : AppTier(
        hasCompass = false,
        hasGPS = false,
        hasMapView = false,
        hasGalleryDetail = false,
        hasIndoorPanel = false,
        hasWatermark = true
    )

    object Compass : AppTier(
        hasCompass = true,
        hasGPS = false,
        hasMapView = false,
        hasGalleryDetail = false,
        hasIndoorPanel = false,
        hasWatermark = false
    )

    object Full : AppTier(
        hasCompass = true,
        hasGPS = true,
        hasMapView = true,
        hasGalleryDetail = true,
        hasIndoorPanel = true,
        hasWatermark = false
    )

    companion object {
        fun fromName(name: String): AppTier = when (name) {
            "compass" -> Compass
            "full" -> Full
            else -> Free
        }

        fun toName(tier: AppTier): String = when (tier) {
            is Compass -> "compass"
            is Full -> "full"
            else -> "free"
        }
    }
}
