package com.firedrone.mobilesdkbridge

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.firedrone.mobilesdkbridge.ui.BridgeApp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val app = application as MobileSdkBridgeApp
        setContent {
            BridgeApp(
                settingsRepository = app.settingsRepository,
                telemetryPoster = app.telemetryPoster,
            )
        }
    }
}
