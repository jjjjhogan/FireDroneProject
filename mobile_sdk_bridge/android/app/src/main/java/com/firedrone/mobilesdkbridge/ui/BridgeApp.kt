package com.firedrone.mobilesdkbridge.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.firedrone.mobilesdkbridge.BuildConfig
import com.firedrone.mobilesdkbridge.data.BridgeSettings
import com.firedrone.mobilesdkbridge.data.SettingsRepository
import com.firedrone.mobilesdkbridge.telemetry.BridgeMode
import com.firedrone.mobilesdkbridge.telemetry.PosterStatus
import com.firedrone.mobilesdkbridge.telemetry.TelemetryPoster
import kotlinx.coroutines.launch
import java.text.DateFormat
import java.util.Date

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BridgeApp(
    settingsRepository: SettingsRepository,
    telemetryPoster: TelemetryPoster,
) {
    val savedSettings by settingsRepository.settings.collectAsState(
        initial = BridgeSettings(),
    )
    val posterStatus by telemetryPoster.status.collectAsState()
    val scope = rememberCoroutineScope()

    var apiBaseUrl by remember(savedSettings.apiBaseUrl) {
        mutableStateOf(savedSettings.apiBaseUrl)
    }
    var ingestToken by remember(savedSettings.ingestToken) {
        mutableStateOf(savedSettings.ingestToken)
    }
    var saveMessage by remember { mutableStateOf("") }

    MaterialTheme {
        Scaffold(
            topBar = {
                TopAppBar(title = { Text("FireDrone MSDK Bridge") })
            },
        ) { padding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(
                    text = "Phase A stub bridge — posts sample telemetry every 3 seconds.",
                    style = MaterialTheme.typography.bodyMedium,
                )
                Text(
                    text = "App ${BuildConfig.VERSION_NAME} · telemetry-only · no flight commands",
                    style = MaterialTheme.typography.labelMedium,
                )

                SettingsCard(
                    apiBaseUrl = apiBaseUrl,
                    ingestToken = ingestToken,
                    onApiBaseUrlChange = { apiBaseUrl = it },
                    onIngestTokenChange = { ingestToken = it },
                    onSave = {
                        scope.launch {
                            settingsRepository.save(apiBaseUrl, ingestToken)
                            saveMessage = "Settings saved on device"
                        }
                    },
                    saveMessage = saveMessage,
                )

                StatusCard(posterStatus)

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Button(
                        onClick = { telemetryPoster.start(BridgeMode.STUB) },
                        enabled = !posterStatus.isRunning,
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Start posting")
                    }
                    Button(
                        onClick = { telemetryPoster.stop() },
                        enabled = posterStatus.isRunning,
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Stop")
                    }
                }

                Button(
                    onClick = {
                        scope.launch {
                            telemetryPoster.postOnce(BridgeMode.STUB)
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Send once")
                }

                Text(
                    text = "Production API: https://firedrone-api.onrender.com/api\n" +
                        "Emulator local API default: http://10.0.2.2:5000/api",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
    }
}

@Composable
private fun SettingsCard(
    apiBaseUrl: String,
    ingestToken: String,
    onApiBaseUrlChange: (String) -> Unit,
    onIngestTokenChange: (String) -> Unit,
    onSave: () -> Unit,
    saveMessage: String,
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text("Connection settings", style = MaterialTheme.typography.titleMedium)
            OutlinedTextField(
                value = apiBaseUrl,
                onValueChange = onApiBaseUrlChange,
                label = { Text("API base URL") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
            )
            OutlinedTextField(
                value = ingestToken,
                onValueChange = onIngestTokenChange,
                label = { Text("Ingest token (DJI_INGEST_TOKEN)") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
            )
            Button(onClick = onSave, modifier = Modifier.fillMaxWidth()) {
                Text("Save settings")
            }
            if (saveMessage.isNotBlank()) {
                Text(saveMessage, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
private fun StatusCard(status: PosterStatus) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text("Bridge status", style = MaterialTheme.typography.titleMedium)
            StatusLine("Monitoring", if (status.isRunning) "running" else "stopped")
            StatusLine("Mode", status.mode.name.lowercase())
            StatusLine("Aircraft link", status.aircraftConnection)
            StatusLine("Poster", status.posterState.name.lowercase())
            StatusLine("Posts sent", status.postsSent.toString())
            StatusLine("Last HTTP", status.lastHttpCode?.toString() ?: "—")
            StatusLine(
                "Last post",
                if (status.lastPostAtEpochMs > 0) {
                    DateFormat.getDateTimeInstance().format(Date(status.lastPostAtEpochMs))
                } else {
                    "—"
                },
            )
            if (status.lastError.isNotBlank()) {
                Text(
                    text = "Last error: ${status.lastError}",
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            if (status.lastResponseBody.isNotBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text("Last response", style = MaterialTheme.typography.labelMedium)
                Text(
                    text = status.lastResponseBody,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
    }
}

@Composable
private fun StatusLine(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, style = MaterialTheme.typography.bodyMedium)
        Text(value, style = MaterialTheme.typography.bodyMedium)
    }
}
