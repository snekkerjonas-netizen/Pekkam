package com.pekkam.app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import kotlin.math.cos
import kotlin.math.sin

object ImageOverlayRenderer {
    fun addWatermark(bitmap: Bitmap): Bitmap {
        val result = bitmap.copy(bitmap.config, true)
        val canvas = Canvas(result)

        val text = "PEKKAM PRØVEVERSJON"
        val paint = Paint().apply {
            textSize = 80f
            color = android.graphics.Color.WHITE
            alpha = 77
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }

        val textWidth = paint.measureText(text)
        val textHeight = 80f
        val spacing = 300f
        val angle = -45f

        canvas.save()

        var x = -bitmap.width.toFloat()
        while (x < bitmap.width * 2) {
            var y = -bitmap.height.toFloat()
            while (y < bitmap.height * 2) {
                canvas.save()

                val centerX = x + textWidth / 2
                val centerY = y + textHeight / 2

                canvas.translate(centerX, centerY)
                canvas.rotate(angle)
                canvas.translate(-centerX, -centerY)

                canvas.drawText(text, x, y + textHeight, paint)

                canvas.restore()

                y += spacing
            }
            x += spacing
        }

        canvas.restore()
        return result
    }

    fun addCompassOverlay(bitmap: Bitmap, heading: Float, direction: String): Bitmap {
        val result = bitmap.copy(bitmap.config, true)
        val canvas = Canvas(result)

        val compassSize = 300f
        val padding = 40f
        val left = bitmap.width - compassSize - padding
        val top = bitmap.height - compassSize - padding

        // Draw background circle
        val bgPaint = Paint().apply {
            color = android.graphics.Color.BLACK
            alpha = 128
        }
        canvas.drawCircle(left + compassSize / 2, top + compassSize / 2, compassSize / 2, bgPaint)

        // Draw border
        val borderPaint = Paint().apply {
            color = android.graphics.Color.WHITE
            strokeWidth = 4f
            style = Paint.Style.STROKE
        }
        canvas.drawCircle(left + compassSize / 2, top + compassSize / 2, compassSize / 2 - 5, borderPaint)

        val centerX = left + compassSize / 2
        val centerY = top + compassSize / 2
        val radius = (compassSize / 2) - 20f

        // Draw cardinal directions
        val directions = arrayOf("N", "E", "S", "W")
        val angles = arrayOf(0f, 90f, 180f, 270f)

        val dirPaint = Paint().apply {
            color = android.graphics.Color.WHITE
            textSize = 28f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            textAlign = Paint.Align.CENTER
        }

        for (i in directions.indices) {
            val angle = Math.toRadians(angles[i].toDouble())
            val x = centerX + sin(angle) * radius
            val y = centerY - cos(angle) * radius
            canvas.drawText(directions[i], x.toFloat(), y.toFloat() + 10, dirPaint)
        }

        // Draw needle
        val needleAngle = Math.toRadians(heading.toDouble())
        val needleLength = radius * 0.8f
        val needleEndX = centerX + sin(needleAngle) * needleLength
        val needleEndY = centerY - cos(needleAngle) * needleLength

        val needlePaint = Paint().apply {
            color = android.graphics.Color.RED
            strokeWidth = 6f
        }
        canvas.drawLine(centerX, centerY, needleEndX.toFloat(), needleEndY.toFloat(), needlePaint)

        // Draw heading degree text
        val headingText = String.format("%.0f°", heading)
        val headingPaint = Paint().apply {
            color = android.graphics.Color.WHITE
            textSize = 24f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(headingText, centerX, centerY + 30, headingPaint)

        // Draw direction text
        val dirTextPaint = Paint().apply {
            color = android.graphics.Color.LTGRAY
            textSize = 22f
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(direction, centerX, centerY + 60, dirTextPaint)

        return result
    }
}
