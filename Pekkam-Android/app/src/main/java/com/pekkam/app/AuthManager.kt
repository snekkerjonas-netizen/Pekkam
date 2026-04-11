package com.pekkam.app

import android.content.Context
import android.content.SharedPreferences
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import org.json.JSONObject
import java.security.MessageDigest
import java.util.UUID

data class PekkamUser(
    val id: String,
    val name: String,
    val email: String,
    val provider: String  // "google" | "apple"
) {
    val displayName: String get() = name.ifEmpty { email }
}

class AuthManager(private val context: Context) {

    // TODO: Erstatt med din Web Client ID fra Google Cloud Console → APIs & Services → Credentials
    // Det er den OAuth 2.0 Web-klient-IDen (ikke Android-klienten)
    private val webClientId = "YOUR_GOOGLE_WEB_CLIENT_ID"

    private val prefs: SharedPreferences =
        context.getSharedPreferences("pekkam_auth", Context.MODE_PRIVATE)

    private val _currentUser = MutableStateFlow<PekkamUser?>(loadStoredUser())
    val currentUser: StateFlow<PekkamUser?> = _currentUser

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error

    // DEV MODE – fjernes før lansering
    private val _devModeActive = MutableStateFlow(false)
    val devModeActive: StateFlow<Boolean> = _devModeActive
    fun devModeUnlock() { _devModeActive.value = true }
    // END DEV MODE

    suspend fun signInWithGoogle(activityContext: android.app.Activity) {
        _isLoading.value = true
        _error.value = null
        try {
            val credentialManager = CredentialManager.create(context)

            val nonce = UUID.randomUUID().toString()
            val hashedNonce = MessageDigest.getInstance("SHA-256")
                .digest(nonce.toByteArray())
                .joinToString("") { "%02x".format(it) }

            val googleIdOption = GetGoogleIdOption.Builder()
                .setFilterByAuthorizedAccounts(false)
                .setServerClientId(webClientId)
                .setNonce(hashedNonce)
                .build()

            val request = GetCredentialRequest.Builder()
                .addCredentialOption(googleIdOption)
                .build()

            val result = credentialManager.getCredential(activityContext, request)
            val credential = result.credential

            if (credential is CustomCredential &&
                credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                val googleCredential = GoogleIdTokenCredential.createFrom(credential.data)
                val user = PekkamUser(
                    id = googleCredential.id,
                    name = googleCredential.displayName ?: "",
                    email = googleCredential.id,
                    provider = "google"
                )
                _currentUser.value = user
                saveUser(user)
            }
        } catch (e: GetCredentialException) {
            if (!e.message.orEmpty().contains("cancel", ignoreCase = true)) {
                _error.value = "Google-innlogging feilet: ${e.message}"
            }
        } catch (e: Exception) {
            _error.value = "Feil: ${e.message}"
        } finally {
            _isLoading.value = false
        }
    }

    suspend fun signOut() {
        try {
            CredentialManager.create(context).clearCredentialState(ClearCredentialStateRequest())
        } catch (_: Exception) {}
        _currentUser.value = null
        prefs.edit().remove("user").apply()
    }

    private fun saveUser(user: PekkamUser) {
        val json = JSONObject().apply {
            put("id", user.id)
            put("name", user.name)
            put("email", user.email)
            put("provider", user.provider)
        }
        prefs.edit().putString("user", json.toString()).apply()
    }

    private fun loadStoredUser(): PekkamUser? {
        val json = prefs.getString("user", null) ?: return null
        return try {
            val obj = JSONObject(json)
            PekkamUser(
                id = obj.getString("id"),
                name = obj.getString("name"),
                email = obj.getString("email"),
                provider = obj.getString("provider")
            )
        } catch (_: Exception) { null }
    }
}
