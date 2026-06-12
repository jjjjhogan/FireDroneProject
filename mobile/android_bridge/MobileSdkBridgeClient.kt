package org.firedrone.bridge

import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

data class MobileSdkAircraftSnapshot(
    val serialNumber: String,
    val name: String,
    val model: String,
    val batteryPercent: Int,
    val signalPercent: Int,
    val latitude: Double,
    val longitude: Double,
    val altitudeMeters: Double,
    val connection: String = "connected",
)

data class MobileSdkFlightSnapshot(
    val state: String = "device-online",
    val routeProgressPercent: Int = 0,
    val windMph: Double = 0.0,
    val temperatureF: Double = 0.0,
    val firePerimeterRisk: String = "operator-feed",
    val linkHealth: String = "stable",
)

class MobileSdkBridgeClient(
    private val apiBase: String,
    private val ingestToken: String,
) {
    fun postSnapshot(
        controllerSerialNumber: String,
        appVersion: String,
        aircraft: MobileSdkAircraftSnapshot,
        flight: MobileSdkFlightSnapshot,
    ): Int {
        val payload = JSONObject()
            .put(
                "controller",
                JSONObject()
                    .put("serialNumber", controllerSerialNumber)
                    .put("appVersion", appVersion),
            )
            .put(
                "aircraft",
                JSONObject()
                    .put("serialNumber", aircraft.serialNumber)
                    .put("name", aircraft.name)
                    .put("model", aircraft.model)
                    .put("batteryPercent", aircraft.batteryPercent)
                    .put("signalPercent", aircraft.signalPercent)
                    .put("latitude", aircraft.latitude)
                    .put("longitude", aircraft.longitude)
                    .put("altitudeMeters", aircraft.altitudeMeters)
                    .put("connection", aircraft.connection),
            )
            .put(
                "flight",
                JSONObject()
                    .put("state", flight.state)
                    .put("routeProgressPercent", flight.routeProgressPercent)
                    .put("windMph", flight.windMph)
                    .put("temperatureF", flight.temperatureF)
                    .put("firePerimeterRisk", flight.firePerimeterRisk)
                    .put("linkHealth", flight.linkHealth),
            )

        val url = URL("${apiBase.trimEnd('/')}/dji/ingest/mobile-sdk")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.connectTimeout = 5000
        connection.readTimeout = 5000
        connection.doOutput = true
        connection.setRequestProperty("Authorization", "Bearer $ingestToken")
        connection.setRequestProperty("Content-Type", "application/json")

        OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { writer ->
            writer.write(payload.toString())
        }
        return connection.responseCode
    }
}
