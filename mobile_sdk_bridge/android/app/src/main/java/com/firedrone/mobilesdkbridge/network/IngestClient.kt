package com.firedrone.mobilesdkbridge.network

import com.firedrone.mobilesdkbridge.data.SamplePayload
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

data class IngestResult(
    val httpCode: Int,
    val body: String,
)

class IngestClient(
    private val client: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(8, TimeUnit.SECONDS)
        .readTimeout(8, TimeUnit.SECONDS)
        .writeTimeout(8, TimeUnit.SECONDS)
        .build(),
) {
    fun postMobileSdkState(
        apiBaseUrl: String,
        ingestToken: String,
        payload: JSONObject = SamplePayload.buildStub(),
    ): IngestResult {
        val normalizedBase = apiBaseUrl.trim().trimEnd('/')
        val url = "$normalizedBase/dji/ingest/mobile-sdk"
        val body = payload.toString().toRequestBody(JSON_MEDIA_TYPE)

        val request = Request.Builder()
            .url(url)
            .header("Authorization", "Bearer $ingestToken")
            .header("Content-Type", "application/json")
            .post(body)
            .build()

        client.newCall(request).execute().use { response ->
            val responseBody = response.body?.string().orEmpty()
            return IngestResult(response.code, responseBody)
        }
    }

    companion object {
        private val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()
    }
}
