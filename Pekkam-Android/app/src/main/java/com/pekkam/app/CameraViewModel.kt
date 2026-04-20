package com.pekkam.app

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.MediaStore
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.exifinterface.media.ExifInterface
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Locale

class CameraViewModel(
    private val context: Context,
    private val purchaseManager: PurchaseManager,
    private val locationRepository: LocationRepository,
    private val compassRepository: CompassRepository,
    private val appSettings: AppSettings
) : ViewModel() {

    private val _lastImageUri = MutableStateFlow<String?>(null)
    val lastImageUri: StateFlow<String?> = _lastImageUri

    // Zoom state (linear ratio, 1.0 = no zoom)
    private val _zoomRatio = MutableStateFlow(1f)
    val zoomRatio: StateFlow<Float> = _zoomRatio

    // Flash mode: ImageCapture.FLASH_MODE_OFF / ON / AUTO
    private val _flashMode = MutableStateFlow(ImageCapture.FLASH_MODE_OFF)
    val flashMode: StateFlow<Int> = _flashMode

    // Live sensor state
    private val _currentLocationData = MutableStateFlow<LocationRepository.LocationData?>(null)
    val currentLocationData: StateFlow<LocationRepository.LocationData?> = _currentLocationData

    private val _currentCompassReading = MutableStateFlow<CompassReading?>(null)
    val currentCompassReading: StateFlow<CompassReading?> = _currentCompassReading

    private var imageCapture: ImageCapture? = null
    private var cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
    private var camera: Camera? = null
    private var cameraProvider: ProcessCameraProvider? = null

    init {
        viewModelScope.launch {
            try {
                locationRepository.getLocationUpdates().collect { _currentLocationData.value = it }
            } catch (_: Exception) { /* location permission not yet granted */ }
        }
        viewModelScope.launch {
            compassRepository.getCompassUpdates().collect { _currentCompassReading.value = it }
        }
    }

    fun setupCamera(provider: ProcessCameraProvider, previewSurface: androidx.camera.view.PreviewView) {
        try {
            cameraProvider = provider
            provider.unbindAll()

            imageCapture = ImageCapture.Builder()
                .setTargetRotation(android.view.Surface.ROTATION_0)
                .setFlashMode(_flashMode.value)
                .build()

            val preview = androidx.camera.core.Preview.Builder().build()
            preview.setSurfaceProvider(previewSurface.surfaceProvider)

            camera = provider.bindToLifecycle(
                context as androidx.lifecycle.LifecycleOwner,
                cameraSelector,
                preview,
                imageCapture
            )

            // Apply current zoom after binding
            applyZoom(_zoomRatio.value)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun setZoomRatio(ratio: Float) {
        val clamped = ratio.coerceIn(getMinZoom(), getMaxZoom())
        _zoomRatio.value = clamped
        applyZoom(clamped)
    }

    private fun applyZoom(ratio: Float) {
        camera?.cameraControl?.setZoomRatio(ratio)
    }

    fun getMinZoom(): Float = camera?.cameraInfo?.zoomState?.value?.minZoomRatio ?: 1f
    fun getMaxZoom(): Float = camera?.cameraInfo?.zoomState?.value?.maxZoomRatio ?: 1f

    fun availableZoomLevels(): List<Float> {
        val max = getMaxZoom()
        val levels = mutableListOf<Float>()
        if (getMinZoom() <= 0.6f) levels.add(0.5f)
        levels.add(1f)
        if (max >= 2f) levels.add(2f)
        if (max >= 3f) levels.add(3f)
        if (max >= 5f) levels.add(5f)
        return levels
    }

    fun cycleFlash() {
        val next = when (_flashMode.value) {
            ImageCapture.FLASH_MODE_OFF  -> ImageCapture.FLASH_MODE_ON
            ImageCapture.FLASH_MODE_ON   -> ImageCapture.FLASH_MODE_AUTO
            else                         -> ImageCapture.FLASH_MODE_OFF
        }
        _flashMode.value = next
        imageCapture?.flashMode = next
    }

    fun capturePhoto(floor: Int? = null, room: String? = null) {
        val imageCapture = imageCapture ?: return

        // Snapshot sensor state at shutter time
        val location   = _currentLocationData.value?.location
        val heading    = _currentCompassReading.value?.heading
        val tier       = purchaseManager.currentTier.value

        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(System.currentTimeMillis())
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "PEKKAM_$timeStamp")
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
            put(MediaStore.MediaColumns.RELATIVE_PATH, "DCIM/Pekkam")
        }

        val outputFileOptions = ImageCapture.OutputFileOptions.Builder(
            context.contentResolver,
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            contentValues
        ).build()

        imageCapture.takePicture(
            outputFileOptions,
            context.mainExecutor,
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    val uri = outputFileResults.savedUri ?: return
                    viewModelScope.launch(Dispatchers.IO) {
                        try {
                            processAndSave(uri, tier, location, heading, floor, room)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                        withContext(Dispatchers.Main) {
                            _lastImageUri.value = uri.toString()
                        }
                    }
                }

                override fun onError(exception: ImageCaptureException) {
                    exception.printStackTrace()
                }
            }
        )
    }

    // ── Post-processing: overlays + EXIF ────────────────────────────────────

    private fun processAndSave(
        uri: Uri,
        tier: AppTier,
        location: android.location.Location?,
        heading: Float?,
        floor: Int?,
        room: String?
    ) {
        // 1. Decode the raw JPEG from MediaStore
        val inputStream = context.contentResolver.openInputStream(uri)
        var bitmap: Bitmap? = BitmapFactory.decodeStream(inputStream)
        inputStream?.close()
        if (bitmap == null) return

        // 2. Apply visual overlays
        if (tier.hasWatermark) {
            bitmap = ImageOverlayRenderer.addWatermark(bitmap)
        }
        val useCompass = appSettings.useCompass(tier)
        if (useCompass && heading != null) {
            val direction = CompassRepository.getCardinalDirection(heading)
            bitmap = ImageOverlayRenderer.addCompassOverlay(bitmap, heading, direction)
        }

        // 3. Write processed bitmap back to the same URI
        context.contentResolver.openOutputStream(uri, "wt")?.use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 95, out)
        }

        // 4. Write EXIF metadata (after bitmap re-write so it is not lost)
        context.contentResolver.openFileDescriptor(uri, "rw")?.use { pfd ->
            val exif = ExifInterface(pfd.fileDescriptor)
            if (appSettings.useGPS(tier) && location != null) {
                exif.setLatLong(location.latitude, location.longitude)
                exif.setAttribute(ExifInterface.TAG_GPS_DOP, location.accuracy.toString())
            }
            if (useCompass && heading != null) {
                exif.setAttribute("PekkamHeading", heading.toString())
            }
            if (floor != null) exif.setAttribute("PekkamFloor", floor.toString())
            if (room  != null) exif.setAttribute("PekkamRoom",  room)
            exif.saveAttributes()
        }
    }

    fun flipCamera() {
        cameraSelector = if (cameraSelector == CameraSelector.DEFAULT_BACK_CAMERA) {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }
        // Re-bind with new selector – caller must invoke setupCamera again with the PreviewView
    }
}
