package com.pekkam.app

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.google.android.gms.maps.model.CameraUpdateFactory
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.LatLngBounds
import com.google.android.gms.maps.model.PolygonOptions
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.Polygon
import com.google.maps.android.compose.rememberCameraPositionState
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun DirectionMapScreen(latitude: Double, longitude: Double, heading: Float) {
    val cameraPositionState = rememberCameraPositionState {
        position = com.google.maps.android.compose.CameraPosition.fromLatLngZoom(
            LatLng(latitude, longitude), 15f
        )
    }

    val center = LatLng(latitude, longitude)
    val radius = 500.0 // meters
    val metersPerDegree = 111000.0

    val angleRad = (heading * Math.PI) / 180.0
    val coneAngle = 20.0 * Math.PI / 180.0 // 40 degrees total

    val left = angleRad - coneAngle
    val right = angleRad + coneAngle

    val leftLat = center.latitude + (cos(left) * (radius / metersPerDegree))
    val leftLng = center.longitude + (sin(left) * (radius / metersPerDegree))

    val rightLat = center.latitude + (cos(right) * (radius / metersPerDegree))
    val rightLng = center.longitude + (sin(right) * (radius / metersPerDegree))

    GoogleMap(
        modifier = Modifier.fillMaxSize(),
        cameraPositionState = cameraPositionState
    ) {
        Polygon(
            points = listOf(
                center,
                LatLng(leftLat, leftLng),
                LatLng(rightLat, rightLng)
            ),
            fillColor = Color.Blue.copy(alpha = 0.3f),
            strokeColor = Color.Blue
        )
    }
}
