package com.pekkam.app

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun PaywallScreen(
    purchaseManager: PurchaseManager,
    onDismiss: () -> Unit,
    onPurchase: (String) -> Unit
) {
    val tier by purchaseManager.currentTier.collectAsState(AppTier.Free)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF001B2E))
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("PEKKAM", color = Color.White, fontSize = 32.sp, fontWeight = FontWeight.Bold)
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White)
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Tier cards
            TierCard(
                title = "Gratis",
                price = "0 kr",
                features = listOf("Kamera", "Vannmerke"),
                isSelected = tier is AppTier.Free,
                onClick = {}
            )

            TierCard(
                title = "Kompass",
                price = "39 kr",
                features = listOf("Kamera", "Kompass overlay", "Uten vannmerke"),
                isSelected = tier is AppTier.Compass,
                onClick = { onPurchase("com.pekkam.compass") }
            )

            TierCard(
                title = "Full",
                price = "49 kr",
                features = listOf(
                    "Alle Kompass funksjoner",
                    "GPS i EXIF",
                    "Kart visning",
                    "Galleriet detaljer",
                    "Innvendig panel"
                ),
                isSelected = tier is AppTier.Full,
                onClick = { onPurchase("com.pekkam.full") }
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Upgrade button
            if (tier is AppTier.Compass) {
                Button(
                    onClick = { onPurchase("com.pekkam.upgrade_to_full") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .height(48.dp)
                ) {
                    Text("Oppgrader til Full (10 kr)")
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Restore button
            Button(
                onClick = { /* Restore purchases */ },
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .padding(16.dp)
            ) {
                Text("Gjenopprett kjøp")
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
fun TierCard(
    title: String,
    price: String,
    features: List<String>,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = if (isSelected) Color(0xFF00B4D8) else Color.White.copy(alpha = 0.2f)
            )
            .background(Color.White.copy(alpha = 0.05f))
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(title, color = Color.White, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                Text(price, color = Color.White.copy(alpha = 0.7f), fontSize = 12.sp)
            }
            if (isSelected) {
                Text("✓", color = Color(0xFF00B4D8), fontWeight = FontWeight.Bold)
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        features.forEach { feature ->
            Text(
                "✓ $feature",
                color = Color.White,
                fontSize = 12.sp,
                modifier = Modifier.padding(vertical = 4.dp)
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        if (\!isSelected) {
            Button(
                onClick = onClick,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Kjøp")
            }
        }
    }
}
