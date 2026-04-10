package com.pekkam.app

import android.content.ContentUris
import android.provider.MediaStore
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

data class MediaItem(val id: Long, val uri: String, val displayName: String)

@Composable
fun GalleryScreen(purchaseManager: PurchaseManager) {
    val scope = rememberCoroutineScope()
    val tier by purchaseManager.currentTier.collectAsState(AppTier.Free)
    var mediaItems by remember { mutableStateOf<List<MediaItem>>(emptyList()) }
    var selectedItem by remember { mutableStateOf<MediaItem?>(null) }

    Box(modifier = Modifier.fillMaxSize()) {
        LazyVerticalGrid(
            columns = GridCells.Fixed(3),
            modifier = Modifier
                .fillMaxSize()
                .padding(4.dp)
        ) {
            items(mediaItems) { item ->
                Box(
                    modifier = Modifier
                        .padding(4.dp)
                        .clickable {
                            if (tier.hasGalleryDetail) {
                                selectedItem = item
                            }
                        }
                ) {
                    Text("Photo", modifier = Modifier.align(Alignment.Center), color = Color.Gray)
                }
            }
        }

        if (selectedItem \!= null && tier.hasGalleryDetail) {
            PhotoDetailScreen(item = selectedItem\!\!) {
                selectedItem = null
            }
        }
    }
}

@Composable
fun PhotoDetailScreen(item: MediaItem, onDismiss: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .clickable { onDismiss() }
    ) {
        Text("Photo Details: ${item.displayName}", modifier = Modifier.align(Alignment.Center))
    }
}
