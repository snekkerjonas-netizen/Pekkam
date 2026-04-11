package com.pekkam.app

import android.content.Context
import android.content.SharedPreferences
import com.android.billingclient.api.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class PurchaseManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("pekkam_prefs", Context.MODE_PRIVATE)
    private val billingClient: BillingClient = BillingClient.newBuilder(context)
        .setListener { billingResult, purchases ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
                for (purchase in purchases) {
                    handlePurchase(purchase)
                }
            }
        }
        .enablePendingPurchases()
        .build()

    private val _currentTier = MutableStateFlow<AppTier>(loadTierFromPrefs())
    val currentTier: StateFlow<AppTier> = _currentTier

    private val _products = MutableStateFlow<List<ProductDetails>>(emptyList())
    val products: StateFlow<List<ProductDetails>> = _products

    init {
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    queryProducts()
                }
            }

            override fun onBillingServiceDisconnected() {}
        })
    }

    private fun queryProducts() {
        val productIds = listOf("com.pekkam.compass", "com.pekkam.full", "com.pekkam.upgrade_to_full")
        val queryProductDetailsParams = QueryProductDetailsParams.newBuilder()
            .setProductList(productIds.map {
                QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(it)
                    .setProductType(BillingClient.ProductType.INAPP)
                    .build()
            })
            .build()

        billingClient.queryProductDetailsAsync(queryProductDetailsParams) { billingResult, productDetailsList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                _products.value = productDetailsList ?: emptyList()
            }
        }
    }

    fun purchase(context: Context, productId: String) {
        val product = _products.value.find { it.id == productId } ?: return

        val billingFlowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(product)
                        .build()
                )
            )
            .build()

        billingClient.launchBillingFlow(context as android.app.Activity, billingFlowParams)
    }

    fun restorePurchases() {
        val queryPurchasesParams = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.INAPP)
            .build()

        billingClient.queryPurchasesAsync(queryPurchasesParams) { billingResult, purchases ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                for (purchase in purchases) {
                    handlePurchase(purchase)
                }
            }
        }
    }

    private fun handlePurchase(purchase: Purchase) {
        val tier = when (purchase.products.firstOrNull()) {
            "com.pekkam.compass" -> if (_currentTier.value is AppTier.Compass) _currentTier.value else AppTier.Compass
            "com.pekkam.full" -> AppTier.Full
            "com.pekkam.upgrade_to_full" -> AppTier.Full
            else -> return
        }

        _currentTier.value = tier
        saveTierToPrefs(tier)
    }

    private fun saveTierToPrefs(tier: AppTier) {
        prefs.edit().putString("tier", AppTier.toName(tier)).apply()
    }

    private fun loadTierFromPrefs(): AppTier {
        val tierName = prefs.getString("tier", "free") ?: "free"
        return AppTier.fromName(tierName)
    }

    fun destroy() {
        if (billingClient.isReady) {
            billingClient.endConnection()
        }
    }
}
