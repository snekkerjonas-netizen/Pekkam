package com.pekkam.app

import android.Manifest
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraSwitch
import androidx.compose.material.icons.filled.FlashAuto
import androidx.compose.material.icons.filled.FlashOff
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Menu
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import androidx.camera.core.ImageCapture

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CameraScreen(
    viewModel: CameraViewModel,
    purchaseManager: PurchaseManager,
    onShowPaywall: () -> Unit,
    onOpenMenu: () -> Unit
) {
    val context = LocalContext.current

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
    val zoomRatio by viewModel.zoomRatio.collectAsState()
    val flashMode by viewModel.flashMode.collectAsState()

    // Keep a reference to the PreviewView so CameraViewModel can hook up after flip
    var previewViewRef by remember { mutableStateOf<PreviewView?>(null) }

    LaunchedEffect(Unit) {
        permissionsState.launchMultiplePermissionRequest()
    }

    Box(modifier = Modifier.fillMaxSize()) {

        // ── Camera preview ──────────────────────────────────────────
        AndroidView(
            factory = { ctx ->
                PreviewView(ctx).also { pv ->
                    previewViewRef = pv
                    val future = ProcessCameraProvider.getInstance(ctx)
                    future.addListener({
                        viewModel.setupCamera(future.get(), pv)
                    }, ctx.mainExecutor)
                }
            },
            modifier = Modifier.fillMaxSize()
        )

        // ── Top bar ─────────────────────────────────────────────────
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 12.dp, end = 12.dp, top = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Menu / hamburger
            GlassIconButton(onClick = onOpenMenu) {
                Icon(Icons.Default.Menu, contentDescription = "Meny", tint = Color.White)
            }

            // GPS chip
            if (tier.hasGPS) {
                GlassChip {
                    Text("±100m", color = Color.White, fontSize = 11.sp)
                }
            }

            // Compass chip
            if (tier.hasCompass) {
                GlassChip {
                    Column {
                        Text("45°", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        Text("Nord", color = Color.White, fontSize = 9.sp)
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Flash toggle
            GlassIconButton(onClick = { viewModel.cycleFlash() }) {
                Icon(
                    imageVector = when (flashMode) {
                        ImageCapture.FLASH_MODE_ON   -> Icons.Default.FlashOn
                        ImageCapture.FLASH_MODE_AUTO -> Icons.Default.FlashAuto
                        else                         -> Icons.Default.FlashOff
                    },
                    contentDescription = "Blits",
                    tint = if (flashMode == ImageCapture.FLASH_MODE_OFF) Color.White else Color.Yellow
                )
            }
        }

        // ── Bottom area: zoom + controls ────────────────────────────
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Zoom level buttons
            ZoomBar(
                zoomRatio = zoomRatio,
                availableLevels = viewModel.availableZoomLevels(),
                onZoomSelected = { viewModel.setZoomRatio(it) }
            )

            // Main control row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Map button
                GlassIconButton(
                    onClick = if (tier.hasMapView) ({ /* TODO: show map */ }) else onShowPaywall
                ) {
                    Icon(
                        Icons.Default.Map,
                        contentDescription = "Kart",
                        tint = if (tier.hasMapView) Color.White else Color.White.copy(alpha = 0.35f)
                    )
                }

                // Shutter
                Box(
                    modifier = Modifier
                        .size(74.dp)
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.15f))
                        .clickable { viewModel.capturePhoto(context, null, null, floor, room) },
                    contentAlignment = Alignment.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(60.dp)
                            .clip(CircleShape)
                            .background(Color.White)
                    )
                }

                // Flip
                GlassIconButton(onClick = {
                    viewModel.flipCamera()
                    previewViewRef?.let { pv ->
                        val future = ProcessCameraProvider.getInstance(context)
                        future.addListener({
                            viewModel.setupCamera(future.get(), pv)
                        }, context.mainExecutor)
                    }
                }) {
                    Icon(Icons.Default.CameraSwitch, contentDescription = "Bytt kamera", tint = Color.White)
                }
            }
        }

        // ── Indoor floating button ──────────────────────────────────
        if (tier.hasIndoorPanel) {
            Button(
                onClick = { showIndoorPanel = true },
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(end = 12.dp, top = 120.dp)
            ) {
                Text("Inn")
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

// ── Zoom button row ─────────────────────────────────────────────────────────

@Composable
fun ZoomBar(
    zoomRatio: Float,
    availableLevels: List<Float>,
    onZoomSelected: (Float) -> Unit
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        availableLevels.forEach { level ->
            val isActive = kotlin.math.abs(zoomRatio - level) < 0.15f
            val label = if (level == 0.5f) ".5×" else "${level.toInt()}×"
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(if (isActive) Color.White else Color.Black.copy(alpha = 0.45f))
                    .clickable { onZoomSelected(level) }
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = label,
                    color = if (isActive) Color.Black else Color.White,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}

// ── Reusable glass-style icon button ────────────────────────────────────────

@Composable
fun GlassIconButton(onClick: () -> Unit, content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Color.Black.copy(alpha = 0.4f))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        content()
    }
}

// ── Reusable glass chip ─────────────────────────────────────────────────────

@Composable
fun GlassChip(content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(Color.Black.copy(alpha = 0.4f))
            .padding(horizontal = 10.dp, vertical = 7.dp)
    ) {
        content()
    }
}

// ── Indoor annotation dialog ────────────────────────────────────────────────

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
            .clickable(onClick = onDismiss)
    ) {
        GlassPanel(
            modifier = Modifier
                .align(Alignment.Center)
                .padding(20.dp)
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text("Innvendig lokalisering", color = Color.White, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(16.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Button(onClick = { onFloorChange(floor - 1) }) { Text("-") }
                    Text("Etasje $floor", color = Color.White)
                    Button(onClick = { onFloorChange(floor + 1) }) { Text("+") }
                }
                Spacer(Modifier.height(16.dp))
                Button(onClick = onDismiss, modifier = Modifier.align(Alignment.End)) {
                    Text("Lagre")
                }
            }
        }
    }
}
