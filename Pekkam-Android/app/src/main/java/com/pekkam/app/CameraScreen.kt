package com.pekkam.app

import android.Manifest
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CameraScreen(
    viewModel: CameraViewModel,
    purchaseManager: PurchaseManager,
    onShowPaywall: () -> Unit
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    val permissionsState = rememberMultiplePermissionsState(
        permissions = listOf(
            Manifest.permission.CAMERA,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
    )

    var showIndoorPanel by remember { mutableStateOf(false) }
    var floor by remember { mutableStateOf(0) }
    var room by remember { mutableStateOf("") }

    val tier by purchaseManager.currentTier.collectAsState(AppTier.Free)

    LaunchedEffect(Unit) {
        permissionsState.launchMultiplePermissionRequest()
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // Camera preview
        AndroidView(
            factory = { ctx ->
                PreviewView(ctx).apply {
                    val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)
                    cameraProviderFuture.addListener({
                        val cameraProvider = cameraProviderFuture.get()
                        viewModel.setupCamera(cameraProvider)
                    }, context.mainExecutor)
                }
            },
            modifier = Modifier.fillMaxSize()
        )

        // Top HUD
        if (tier.hasGPS || tier.hasCompass) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(12.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                if (tier.hasGPS) {
                    GlassPanel(
                        modifier = Modifier.padding(8.dp)
                    ) {
                        Text("±100m", modifier = Modifier.padding(8.dp), color = Color.White)
                    }
                }

                if (tier.hasCompass) {
                    GlassPanel(
                        modifier = Modifier.padding(8.dp)
                    ) {
                        Column(modifier = Modifier.padding(8.dp)) {
                            Text("45°", color = Color.White)
                            Text("Nord", color = Color.White)
                        }
                    }
                }

                Spacer(modifier = Modifier.weight(1f))
            }
        }

        // Bottom control bar
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(20.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Map button
            if (tier.hasMapView) {
                Button(onClick = { /* Show map */ }) {
                    Icon(Icons.Default.PhotoCamera, contentDescription = "Map")
                }
            } else {
                Button(onClick = onShowPaywall) {
                    Text("Map")
                }
            }

            // Shutter button
            Button(
                onClick = { viewModel.capturePhoto(context, null, null, floor, room) },
                modifier = Modifier.size(70.dp),
                shape = CircleShape
            ) {
                Icon(Icons.Default.PhotoCamera, contentDescription = "Capture")
            }

            // Flip camera
            Button(onClick = { viewModel.flipCamera() }) {
                Text("Flip")
            }
        }

        // Indoor button (if applicable)
        if (tier.hasIndoorPanel) {
            Button(
                onClick = { showIndoorPanel = true },
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(12.dp)
            ) {
                Text("Indoor")
            }
        }
    }

    if (showIndoorPanel) {
        IndoorAnnotationPanel(
            floor = floor,
            room = room,
            onFloorChange = { floor = it },
            onRoomChange = { room = it },
            onDismiss = { showIndoorPanel = false }
        )
    }
}

@Composable
fun IndoorAnnotationPanel(
    floor: Int,
    room: String,
    onFloorChange: (Int) -> Unit,
    onRoomChange: (String) -> Unit,
    onDismiss: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.5f))
    ) {
        GlassPanel(
            modifier = Modifier
                .align(Alignment.Center)
                .padding(20.dp)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text("Innvendig lokalisering", color = Color.White)
                // Add controls here
                Button(onClick = onDismiss) {
                    Text("Lagre")
                }
            }
        }
    }
}
