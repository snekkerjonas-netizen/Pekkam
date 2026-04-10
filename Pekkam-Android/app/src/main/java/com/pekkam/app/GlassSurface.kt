package com.pekkam.app

import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

@Composable
fun GlassPanel(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        Box(
            modifier = modifier
                .blur(20.dp)
                .background(
                    Color.Black.copy(alpha = 0.3f),
                    RoundedCornerShape(12.dp)
                )
        ) {
            content()
        }
    } else {
        Box(
            modifier = modifier.background(
                Color(0x88000000),
                RoundedCornerShape(12.dp)
            )
        ) {
            content()
        }
    }
}
