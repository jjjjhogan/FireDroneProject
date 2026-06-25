package com.firedrone.mobilesdkbridge

import android.app.Application
import com.firedrone.mobilesdkbridge.data.SettingsRepository
import com.firedrone.mobilesdkbridge.network.IngestClient
import com.firedrone.mobilesdkbridge.telemetry.TelemetryPoster

class MobileSdkBridgeApp : Application() {
    lateinit var settingsRepository: SettingsRepository
        private set

    lateinit var ingestClient: IngestClient
        private set

    lateinit var telemetryPoster: TelemetryPoster
        private set

    override fun onCreate() {
        super.onCreate()
        settingsRepository = SettingsRepository(this)
        ingestClient = IngestClient()
        telemetryPoster = TelemetryPoster(settingsRepository, ingestClient)
    }
}
