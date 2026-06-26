package com.firedrone.mobilesdkbridge.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.firedrone.mobilesdkbridge.BuildConfig
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(
    name = "bridge_settings",
)

data class BridgeSettings(
    val apiBaseUrl: String = BuildConfig.DEFAULT_API_BASE,
    val ingestToken: String = "",
)

class SettingsRepository(private val context: Context) {
    private val apiBaseKey = stringPreferencesKey("api_base_url")
    private val ingestTokenKey = stringPreferencesKey("ingest_token")

    val settings: Flow<BridgeSettings> = context.dataStore.data.map { prefs ->
        BridgeSettings(
            apiBaseUrl = prefs[apiBaseKey]?.trim().orEmpty().ifBlank {
                BuildConfig.DEFAULT_API_BASE
            },
            ingestToken = prefs[ingestTokenKey].orEmpty(),
        )
    }

    suspend fun save(apiBaseUrl: String, ingestToken: String) {
        context.dataStore.edit { prefs ->
            prefs[apiBaseKey] = apiBaseUrl.trim()
            prefs[ingestTokenKey] = ingestToken.trim()
        }
    }
}
