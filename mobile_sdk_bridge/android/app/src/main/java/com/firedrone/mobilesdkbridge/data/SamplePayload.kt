package com.firedrone.mobilesdkbridge.data

import org.json.JSONObject

/**
 * Sample Mobile SDK payload aligned with backend/scripts/post_mobile_sdk_state.py.
 * Phase A uses this stub; Phase B replaces aircraft fields from DJI SDK callbacks.
 */
object SamplePayload {
    const val APP_VERSION = "0.1.0"

    fun buildStub(): JSONObject {
        return JSONObject()
            .put(
                "controller",
                JSONObject()
                    .put("serialNumber", "rc-pro-001")
                    .put("appVersion", APP_VERSION),
            )
            .put(
                "aircraft",
                JSONObject()
                    .put("serialNumber", "msdk-m3t-01")
                    .put("name", "MSDK Field Unit")
                    .put("model", "DJI Matrice 30T")
                    .put("batteryPercent", 89)
                    .put("signalPercent", 93)
                    .put("latitude", 34.621)
                    .put("longitude", -119.721)
                    .put("altitudeMeters", 124.2)
                    .put("connection", "connected"),
            )
            .put(
                "flight",
                JSONObject()
                    .put("state", "device-online")
                    .put("routeProgressPercent", 17)
                    .put("windMph", 8)
                    .put("temperatureF", 79)
                    .put("firePerimeterRisk", "operator-feed")
                    .put("linkHealth", "stable"),
            )
    }
}
