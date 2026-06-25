package com.firedrone.mobilesdkbridge.telemetry

import com.firedrone.mobilesdkbridge.data.SamplePayload
import com.firedrone.mobilesdkbridge.data.SettingsRepository
import com.firedrone.mobilesdkbridge.network.IngestClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

enum class BridgeMode {
    STUB,
    DJI_SDK,
}

enum class PosterState {
    IDLE,
    POSTING,
    SUCCESS,
    ERROR,
}

data class PosterStatus(
    val isRunning: Boolean = false,
    val mode: BridgeMode = BridgeMode.STUB,
    val aircraftConnection: String = "stub",
    val posterState: PosterState = PosterState.IDLE,
    val lastHttpCode: Int? = null,
    val lastResponseBody: String = "",
    val lastError: String = "",
    val postsSent: Int = 0,
    val lastPostAtEpochMs: Long = 0L,
)

class TelemetryPoster(
    private val settingsRepository: SettingsRepository,
    private val ingestClient: IngestClient,
    private val intervalMs: Long = DEFAULT_INTERVAL_MS,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var loopJob: Job? = null

    private val _status = MutableStateFlow(PosterStatus())
    val status: StateFlow<PosterStatus> = _status.asStateFlow()

    fun start(mode: BridgeMode = BridgeMode.STUB) {
        if (loopJob?.isActive == true) {
            _status.value = _status.value.copy(mode = mode, isRunning = true)
            return
        }

        _status.value = _status.value.copy(
            isRunning = true,
            mode = mode,
            aircraftConnection = if (mode == BridgeMode.STUB) "stub" else "pending-sdk",
            lastError = "",
        )

        loopJob = scope.launch {
            while (isActive) {
                postOnce(mode)
                delay(intervalMs)
            }
        }
    }

    fun stop() {
        loopJob?.cancel()
        loopJob = null
        _status.value = _status.value.copy(
            isRunning = false,
            posterState = PosterState.IDLE,
        )
    }

    suspend fun postOnce(mode: BridgeMode = _status.value.mode): PosterStatus {
        _status.value = _status.value.copy(posterState = PosterState.POSTING, lastError = "")

        val settings = settingsRepository.settings.first()
        if (settings.ingestToken.isBlank()) {
            return fail("Ingest token is required")
        }
        if (settings.apiBaseUrl.isBlank()) {
            return fail("API base URL is required")
        }

        return withContext(Dispatchers.IO) {
            try {
                val payload = when (mode) {
                    BridgeMode.STUB -> SamplePayload.buildStub()
                    BridgeMode.DJI_SDK -> SamplePayload.buildStub()
                }

                val result = ingestClient.postMobileSdkState(
                    apiBaseUrl = settings.apiBaseUrl,
                    ingestToken = settings.ingestToken,
                    payload = payload,
                )

                val ok = result.httpCode in 200..299
                val next = _status.value.copy(
                    posterState = if (ok) PosterState.SUCCESS else PosterState.ERROR,
                    lastHttpCode = result.httpCode,
                    lastResponseBody = result.body.take(MAX_RESPONSE_CHARS),
                    lastError = if (ok) "" else "HTTP ${result.httpCode}",
                    postsSent = _status.value.postsSent + 1,
                    lastPostAtEpochMs = System.currentTimeMillis(),
                    aircraftConnection = if (mode == BridgeMode.STUB) "stub" else "pending-sdk",
                )
                _status.value = next
                next
            } catch (error: Exception) {
                fail(error.message ?: error.javaClass.simpleName)
            }
        }
    }

    private fun fail(message: String): PosterStatus {
        val next = _status.value.copy(
            posterState = PosterState.ERROR,
            lastError = message,
        )
        _status.value = next
        return next
    }

    companion object {
        const val DEFAULT_INTERVAL_MS = 3_000L
        private const val MAX_RESPONSE_CHARS = 500
    }
}
