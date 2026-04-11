package com.pekkam.app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

enum class CompassWarning {
    NEEDS_CALIBRATION,
    DISTURBED
}

data class CompassReading(
    val heading: Float,
    val accuracy: Int,
    val warning: CompassWarning?
)

class CompassRepository(context: Context) {
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val magnetometer = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

    private var accelerometerReading = FloatArray(3)
    private var magnetometerReading = FloatArray(3)
    private val rotationMatrix = FloatArray(9)
    private val orientationAngles = FloatArray(3)

    fun getCompassUpdates(): Flow<CompassReading> = callbackFlow {
        val sensorEventListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                when (event.sensor.type) {
                    Sensor.TYPE_ACCELEROMETER -> {
                        System.arraycopy(event.values, 0, accelerometerReading, 0, 3)
                    }
                    Sensor.TYPE_MAGNETIC_FIELD -> {
                        System.arraycopy(event.values, 0, magnetometerReading, 0, 3)
                    }
                }

                if (SensorManager.getRotationMatrix(
                        rotationMatrix, null,
                        accelerometerReading, magnetometerReading
                    )
                ) {
                    SensorManager.getOrientation(rotationMatrix, orientationAngles)
                    val heading = Math.toDegrees(orientationAngles[0].toDouble()).toFloat()
                    val normalizedHeading = (heading + 360) % 360

                    val warning = if (event.accuracy < 2) {
                        CompassWarning.NEEDS_CALIBRATION
                    } else if (event.accuracy == 1) {
                        CompassWarning.DISTURBED
                    } else {
                        null
                    }

                    trySend(CompassReading(normalizedHeading, event.accuracy, warning))
                }
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
        }

        if (accelerometer != null) {
            sensorManager.registerListener(sensorEventListener, accelerometer, SensorManager.SENSOR_DELAY_UI)
        }
        if (magnetometer != null) {
            sensorManager.registerListener(sensorEventListener, magnetometer, SensorManager.SENSOR_DELAY_UI)
        }

        awaitClose {
            sensorManager.unregisterListener(sensorEventListener)
        }
    }

    companion object {
        fun getCardinalDirection(heading: Float): String {
            val directions = arrayOf("Nord", "Nordøst", "Øst", "Sørøst", "Sør", "Sørvest", "Vest", "Nordvest")
            val index = ((heading + 22.5) / 45).toInt() % 8
            return directions[index]
        }
    }
}
