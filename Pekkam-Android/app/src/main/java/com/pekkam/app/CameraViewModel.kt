package com.pekkam.app

import android.content.ContentValues
import android.content.Context
import android.location.Location
import android.provider.MediaStore
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.exifinterface.media.ExifInterface
import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.text.SimpleDateFormat
import java.util.Locale

class CameraViewModel(
    private val context: Context,
    private val purchaseManager: PurchaseManager,
    private val locationRepository: LocationRepository,
    private val compassRepository: CompassRepository
) : ViewModel() {

    private val _tier = MutableStateFlow<AppTier>(AppTier.Free)
    val tier: StateFlow<AppTier> = _tier

    private val _lastImageUri = MutableStateFlow<String?>(null)
    val lastImageUri: StateFlow<String?> = _lastImageUri

    private var imageCapture: ImageCapture? = null
    private var cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

    fun setupCamera(cameraProvider: ProcessCameraProvider) {
        try {
            cameraProvider.unbindAll()

            imageCapture = ImageCapture.Builder()
                .setTargetRotation(android.view.Surface.ROTATION_0)
                .build()

            val preview = androidx.camera.core.Preview.Builder().build()
            cameraProvider.bindToLifecycle(context as androidx.lifecycle.LifecycleOwner, cameraSelector, preview, imageCapture)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun capturePhoto(
        context: Context,
        location: Location?,
        heading: Float?,
        floor: Int? = null,
        room: String? = null
    ) {
        val imageCapture = imageCapture ?: return

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
                    val uri = outputFileResults.savedUri
                    if (uri \!= null) {
                        try {
                            val pfd = context.contentResolver.openFileDescriptor(uri, "w")
                            if (pfd \!= null) {
                                val exif = ExifInterface(pfd.fileDescriptor)

                                if (_tier.value.hasGPS && location \!= null) {
                                    exif.setLatLong(location.latitude, location.longitude)
                                    exif.setAttribute(ExifInterface.TAG_GPS_DOP, location.accuracy.toString())
                                }

                                if (_tier.value.hasCompass && heading \!= null) {
                                    exif.setAttribute("PekkamHeading", heading.toString())
                                    if (floor \!= null) {
                                        exif.setAttribute("PekkamFloor", floor.toString())
                                    }
                                    if (room \!= null) {
                                        exif.setAttribute("PekkamRoom", room)
                                    }
                                }

                                exif.saveAttributes()
                                pfd.close()
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                        _lastImageUri.value = uri.toString()
                    }
                }

                override fun onError(exception: ImageCaptureException) {
                    exception.printStackTrace()
                }
            }
        )
    }

    fun flipCamera() {
        cameraSelector = if (cameraSelector == CameraSelector.DEFAULT_BACK_CAMERA) {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }
    }
}
