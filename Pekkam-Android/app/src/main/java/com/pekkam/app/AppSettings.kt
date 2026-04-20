package com.pekkam.app

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Brukerens valg om hvilke opplåste funksjoner som er aktive.
 * Tilsvarer iOS AppSettings.swift – kan slås av/på i sidemenyen uavhengig av kjøpt abonnement.
 */
class AppSettings(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("pekkam_settings", Context.MODE_PRIVATE)

    private val _gpsActive     = MutableStateFlow(prefs.getBoolean("setting_gps",     true))
    val gpsActive: StateFlow<Boolean> = _gpsActive

    private val _compassActive = MutableStateFlow(prefs.getBoolean("setting_compass", true))
    val compassActive: StateFlow<Boolean> = _compassActive

    private val _mapActive     = MutableStateFlow(prefs.getBoolean("setting_map",     true))
    val mapActive: StateFlow<Boolean> = _mapActive

    private val _indoorActive  = MutableStateFlow(prefs.getBoolean("setting_indoor",  true))
    val indoorActive: StateFlow<Boolean> = _indoorActive

    // "system" | "light" | "dark"
    private val _appAppearance = MutableStateFlow(
        prefs.getString("app_appearance", "system") ?: "system"
    )
    val appAppearance: StateFlow<String> = _appAppearance

    fun setGpsActive(v: Boolean) {
        _gpsActive.value = v
        prefs.edit().putBoolean("setting_gps", v).apply()
    }

    fun setCompassActive(v: Boolean) {
        _compassActive.value = v
        prefs.edit().putBoolean("setting_compass", v).apply()
    }

    fun setMapActive(v: Boolean) {
        _mapActive.value = v
        prefs.edit().putBoolean("setting_map", v).apply()
    }

    fun setIndoorActive(v: Boolean) {
        _indoorActive.value = v
        prefs.edit().putBoolean("setting_indoor", v).apply()
    }

    fun setAppAppearance(v: String) {
        _appAppearance.value = v
        prefs.edit().putString("app_appearance", v).apply()
    }

    // Helpers: kombinerer «abonnementet gir tilgang» + «brukeren har skrudd den på»
    fun useGPS(tier: AppTier):     Boolean = tier.hasGPS          && gpsActive.value
    fun useCompass(tier: AppTier): Boolean = tier.hasCompass       && compassActive.value
    fun useMap(tier: AppTier):     Boolean = tier.hasMapView       && mapActive.value
    fun useIndoor(tier: AppTier):  Boolean = tier.hasIndoorPanel   && indoorActive.value
}
