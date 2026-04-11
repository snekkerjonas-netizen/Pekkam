package com.pekkam.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Divider
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.pekkam.app.ui.theme.PekkamTheme
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private lateinit var purchaseManager: PurchaseManager
    private lateinit var authManager: AuthManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        purchaseManager = PurchaseManager(this)
        authManager = AuthManager(this)

        setContent {
            PekkamTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color.Black
                ) {
                    val navController = rememberNavController()
                    val showPaywall = remember { mutableStateOf(false) }
                    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
                    val scope = rememberCoroutineScope()
                    val tier by purchaseManager.currentTier.collectAsState(AppTier.Free)
                    val authUser by authManager.currentUser.collectAsState(null)
                    val authLoading by authManager.isLoading.collectAsState(false)
                    val authError by authManager.error.collectAsState(null)
                    val devMode by authManager.devModeActive.collectAsState(false)
                    // DEV MODE: tap count state
                    var titleTapCount by remember { mutableStateOf(0) }

                    ModalNavigationDrawer(
                        drawerState = drawerState,
                        drawerContent = {
                            ModalDrawerSheet(
                                modifier = Modifier.width(300.dp),
                                drawerContainerColor = Color(0xFF1A1A1A)
                            ) {
                                // ── Drawer header ──────────────────────────────────
                                Row(
                                    modifier = Modifier.padding(start = 24.dp, top = 52.dp, bottom = 20.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Default.Star, contentDescription = null, tint = Color.White, modifier = Modifier.size(28.dp))
                                    Spacer(Modifier.width(10.dp))
                                    // DEV MODE – trykk 5 ganger på tittelen (fjernes før lansering)
                                    Text(
                                        "Pekkam",
                                        color = Color.White,
                                        fontSize = 20.sp,
                                        fontWeight = FontWeight.Bold,
                                        modifier = Modifier.clickable {
                                            titleTapCount++
                                            if (titleTapCount >= 5) {
                                                titleTapCount = 0
                                                authManager.devModeUnlock()
                                                purchaseManager.devModeUnlock()
                                            }
                                        }
                                    )
                                    // END DEV MODE
                                }

                                // DEV banner – fjernes før lansering
                                if (devMode) {
                                    Box(modifier = Modifier.fillMaxWidth().background(Color.Yellow).padding(6.dp)) {
                                        Text("DEV: Full-versjon aktiv", color = Color.Black, fontSize = 11.sp, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Center))
                                    }
                                }
                                // END DEV

                                Divider(color = Color.White.copy(alpha = 0.12f))

                                // ── Innlogging ──────────────────────────────────────
                                DrawerSectionLabel("Konto")

                                if (authUser != null) {
                                    // Logget inn
                                    Row(
                                        modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(Icons.Default.Star, contentDescription = null, tint = Color.White, modifier = Modifier.size(22.dp))
                                        Spacer(Modifier.width(12.dp))
                                        Column {
                                            Text(authUser!!.displayName, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                                            Text(authUser!!.email, color = Color.Gray, fontSize = 11.sp)
                                        }
                                    }
                                    Row(
                                        modifier = Modifier.padding(horizontal = 24.dp, vertical = 4.dp),
                                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .clip(RoundedCornerShape(20.dp))
                                                .background(Color.White.copy(alpha = 0.12f))
                                                .clickable { purchaseManager.restorePurchases() }
                                                .padding(horizontal = 12.dp, vertical = 6.dp)
                                        ) { Text("Synk kjøp", color = Color.White, fontSize = 12.sp) }
                                        Box(
                                            modifier = Modifier
                                                .clip(RoundedCornerShape(20.dp))
                                                .background(Color.Red.copy(alpha = 0.12f))
                                                .clickable { scope.launch { authManager.signOut() } }
                                                .padding(horizontal = 12.dp, vertical = 6.dp)
                                        ) { Text("Logg ut", color = Color.Red.copy(alpha = 0.85f), fontSize = 12.sp) }
                                    }
                                } else {
                                    // Ikke logget inn
                                    authError?.let { err ->
                                        Text(err, color = Color(0xFFFF9800), fontSize = 10.sp, modifier = Modifier.padding(horizontal = 24.dp, vertical = 4.dp))
                                    }
                                    // Google Sign-In
                                    Box(
                                        modifier = Modifier
                                            .padding(horizontal = 24.dp, vertical = 6.dp)
                                            .fillMaxWidth()
                                            .clip(RoundedCornerShape(12.dp))
                                            .background(Color(0xFF4285F4))
                                            .clickable {
                                                scope.launch { authManager.signInWithGoogle(this@MainActivity) }
                                            }
                                            .padding(horizontal = 16.dp, vertical = 12.dp)
                                    ) {
                                        Text("Logg inn med Google", color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                                    }
                                    Text(
                                        "Logg inn for å synkronisere kjøp på tvers av enheter.",
                                        color = Color.Gray,
                                        fontSize = 10.sp,
                                        modifier = Modifier.padding(horizontal = 24.dp, vertical = 2.dp)
                                    )
                                }

                                Divider(color = Color.White.copy(alpha = 0.12f), modifier = Modifier.padding(top = 12.dp))

                                // ── Abonnement ──────────────────────────────────────
                                DrawerSectionLabel("Abonnement")

                                val tierName = when (tier) {
                                    AppTier.Free    -> "Gratisversjon"
                                    AppTier.Compass -> "Kompass-plan"
                                    AppTier.Full    -> "Full versjon"
                                    else            -> "Ukjent"
                                }
                                val tierSub = when (tier) {
                                    AppTier.Full    -> "Alle funksjoner aktivert"
                                    AppTier.Compass -> "GPS og kart ikke inkludert"
                                    else            -> "Prøv premium-funksjoner"
                                }

                                Row(
                                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Default.Star, contentDescription = null, tint = if (tier == AppTier.Full) Color.Yellow else Color.Gray, modifier = Modifier.size(20.dp))
                                    Spacer(Modifier.width(12.dp))
                                    Column {
                                        Text(tierName, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                                        Text(tierSub, color = Color.Gray, fontSize = 11.sp)
                                    }
                                }

                                if (tier != AppTier.Full) {
                                    Box(
                                        modifier = Modifier
                                            .padding(horizontal = 24.dp, vertical = 8.dp)
                                            .fillMaxWidth()
                                            .clip(RoundedCornerShape(12.dp))
                                            .background(Color.White)
                                            .clickable { scope.launch { drawerState.close() }; showPaywall.value = true }
                                            .padding(horizontal = 16.dp, vertical = 12.dp)
                                    ) {
                                        Text(if (tier == AppTier.Compass) "Oppgrader til Full" else "Kjøp Premium", color = Color.Black, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                                    }
                                }

                                Divider(
                                    color = Color.White.copy(alpha = 0.12f),
                                    modifier = Modifier.padding(top = 12.dp)
                                )

                                // ── Features ───────────────────────────────────────
                                DrawerSectionLabel("Funksjoner")

                                DrawerFeatureRow("GPS-metadata",      "Posisjon lagres i bildet",   tier.hasGPS)
                                DrawerFeatureRow("Kompass-data",      "Retning lagres i bildet",    tier.hasCompass)
                                DrawerFeatureRow("Kartvisning",       "Se where bildet ble tatt",   tier.hasMapView)
                                DrawerFeatureRow("Innvendig lokasjon","Etasje og rom",              tier.hasIndoorPanel)
                                DrawerFeatureRow("Uten vannmerke",    "Rene bilder",                !tier.hasWatermark)

                                Divider(
                                    color = Color.White.copy(alpha = 0.12f),
                                    modifier = Modifier.padding(top = 12.dp)
                                )

                                // ── App ────────────────────────────────────────────
                                DrawerSectionLabel("App")

                                DrawerMenuRow(Icons.Default.Refresh, "Gjenopprett kjøp") {
                                    purchaseManager.restorePurchases()
                                }
                                DrawerMenuRow(Icons.Default.Info, "Om Pekkam") { }
                            }
                        }
                    ) {
                        // ── Main content ───────────────────────────────────────
                        NavHost(navController = navController, startDestination = "camera") {
                            composable("camera") {
                                val viewModel = CameraViewModel(
                                    this@MainActivity,
                                    purchaseManager,
                                    LocationRepository(this@MainActivity),
                                    CompassRepository(this@MainActivity)
                                )
                                CameraScreen(
                                    viewModel = viewModel,
                                    purchaseManager = purchaseManager,
                                    onShowPaywall = { showPaywall.value = true },
                                    onOpenMenu = { scope.launch { drawerState.open() } }
                                )
                            }

                            composable("gallery") {
                                GalleryScreen(purchaseManager = purchaseManager)
                            }

                            composable("map") {
                                DirectionMapScreen(
                                    latitude = 59.9139,
                                    longitude = 10.7522,
                                    heading = 45f
                                )
                            }
                        }

                        if (showPaywall.value) {
                            PaywallScreen(
                                purchaseManager = purchaseManager,
                                onDismiss = { showPaywall.value = false },
                                onPurchase = { productId ->
                                    purchaseManager.purchase(this@MainActivity, productId)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        purchaseManager.destroy()
    }
}

// ── Drawer composable helpers ────────────────────────────────────────────────

@androidx.compose.runtime.Composable
private fun DrawerSectionLabel(title: String) {
    Text(
        title.uppercase(),
        color = Color.White.copy(alpha = 0.4f),
        fontSize = 10.sp,
        fontWeight = FontWeight.SemiBold,
        modifier = androidx.compose.ui.Modifier.padding(start = 24.dp, top = 20.dp, bottom = 6.dp)
    )
}

@androidx.compose.runtime.Composable
private fun DrawerFeatureRow(title: String, subtitle: String, unlocked: Boolean) {
    Row(
        modifier = androidx.compose.ui.Modifier.padding(horizontal = 24.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            if (unlocked) Icons.Default.CheckCircle else Icons.Default.Lock,
            contentDescription = null,
            tint = if (unlocked) Color.Green else Color.White.copy(alpha = 0.25f),
            modifier = androidx.compose.ui.Modifier.size(16.dp)
        )
        Spacer(androidx.compose.ui.Modifier.width(12.dp))
        Column {
            Text(title, color = if (unlocked) Color.White else Color.White.copy(alpha = 0.45f), fontSize = 13.sp)
            Text(subtitle, color = Color.Gray, fontSize = 10.sp)
        }
    }
}

@androidx.compose.runtime.Composable
private fun DrawerMenuRow(icon: ImageVector, title: String, onClick: () -> Unit) {
    Row(
        modifier = androidx.compose.ui.Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 24.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = Color.White.copy(alpha = 0.7f), modifier = androidx.compose.ui.Modifier.size(18.dp))
        Spacer(androidx.compose.ui.Modifier.width(14.dp))
        Text(title, color = Color.White, fontSize = 14.sp)
    }
}
