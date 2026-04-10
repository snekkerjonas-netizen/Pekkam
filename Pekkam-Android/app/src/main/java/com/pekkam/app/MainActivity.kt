package com.pekkam.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.pekkam.app.ui.theme.PekkamTheme

class MainActivity : ComponentActivity() {
    private lateinit var purchaseManager: PurchaseManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        purchaseManager = PurchaseManager(this)

        setContent {
            PekkamTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val navController = rememberNavController()
                    var showPaywall = remember { mutableStateOf(false) }

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
                                onShowPaywall = { showPaywall.value = true }
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

    override fun onDestroy() {
        super.onDestroy()
        purchaseManager.destroy()
    }
}
