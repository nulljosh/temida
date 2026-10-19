package com.nulljosh.litigate

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.parameter
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

// Nothing case-identifying lives in this file, only the fetch. `value` is
// left as a raw JsonElement -- there is no compile-time model of case
// content anywhere in this repo's source, on any platform, on purpose (see
// CLAUDE.md's "Source holds types and empty containers only" / the
// check-no-case-content.sh acceptance test). Populate a UI from the fetched
// JsonElement at runtime; never copy a value out of it into a literal here.
private data class BriefRow(val value: JsonElement)

class BriefDataClient {
    private val http = HttpClient {
        install(ContentNegotiation) { json(Json { ignoreUnknownKeys = true }) }
    }

    /** Fetches the signed-in user's own `brief_data` row for `key` ("cases" or
     *  "fragments"). RLS scopes this to `auth.uid()`, so a wrong/expired token
     *  yields an empty result, not another user's row. */
    suspend fun fetch(session: AuthSession, key: String): JsonElement? {
        val rows: List<JsonObject> = http.get("${restBaseUrl()}/brief_data") {
            header("apikey", apiKeyHeader())
            header("Authorization", "Bearer ${session.accessToken}")
            parameter("key", "eq.$key")
            parameter("select", "value")
        }.body()
        return rows.firstOrNull()?.get("value")
    }
}
