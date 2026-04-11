package com.pekkam.app

import android.content.Context
import android.location.Location
import android.os.Looper
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

enum class AccuracyCategory {
    GPS, WIFI, CELL, NONE;

    companion object {
        fun fromAccuracy(accuracy: Float): AccuracyCategory = when {
            accuracy < 0 -> NONE
            accuracy < 15 -> GPS
            accuracy <= 100 -> WIFI
            else -> CELL
        }
    }
}

class LocationRepository(context: Context) {
    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    data class LocationData(
        val location: Location?,
        val accuracy: Float,
        val category: AccuracyCategory
    )

    fun getLocationUpdates(): Flow<LocationData> = callbackFlow {
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000)
            .setMinUpdateDistanceMeters(5f)
            .build()

        val locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                val location = locationResult.lastLocation
                if (location != null) {
                    val accuracy = location.accuracy
                    val category = AccuracyCategory.fromAccuracy(accuracy)
                    trySend(LocationData(location, accuracy, category))
                }
            }
        }

        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
        } catch (e: SecurityException) {
            trySend(LocationData(null, -1f, AccuracyCategory.NONE))
        }

        awaitClose {
            fusedLocationClient.removeLocationUpdates(locationCallback)
        }
    }
}
