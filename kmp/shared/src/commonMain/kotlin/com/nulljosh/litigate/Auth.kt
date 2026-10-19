package com.nulljosh.litigate

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

// Same shared `spark` Supabase project every other app on this account uses;
// the anon key is public by design (it is embedded in every app's web
// bundle already, e.g. lexly's js/lingo-app.js) and carries no access on
// its own -- RLS on brief_data is what actually gates a row to its owner.
private const val SUPABASE_URL = "https://tjsxsqlxjmanwvmywwvw.supabase.co"
private const val SUPABASE_ANON_KEY =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqc3hzcWx4am1hbnd2bXl3d3Z3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0OTc0MDEsImV4cCI6MjA4NjA3MzQwMX0.LphLfho3wdQC20MhtcnBpzQUNuBoTOobrugQbNGxc68"

@Serializable
data class AuthSession(val accessToken: String, val userId: String)

@Serializable
private data class TokenResponse(
    val access_token: String = "",
    val user: TokenUser? = null,
)

@Serializable
private data class TokenUser(val id: String = "")

@Serializable
private data class AuthErrorBody(val error_description: String? = null, val msg: String? = null)

class AuthException(message: String) : Exception(message)

// Single-user sign-in gated to the owner account, same as iOS/macOS today --
// litigate's own CLAUDE.md: "iOS/macOS still single-user (sign-in is gated
// to the owner account); multi-user signup there is Phase 2." No signup UI
// here either.
class LitigateAuth {
    private val http = HttpClient {
        install(ContentNegotiation) { json(Json { ignoreUnknownKeys = true }) }
    }

    suspend fun signIn(email: String, password: String): AuthSession {
        val response: HttpResponse = http.post("$SUPABASE_URL/auth/v1/token?grant_type=password") {
            header("apikey", SUPABASE_ANON_KEY)
            contentType(ContentType.Application.Json)
            setBody("""{"email":"${email.jsonEscape()}","password":"${password.jsonEscape()}"}""")
        }
        if (!response.status.isSuccess()) {
            val body = runCatching { response.body<AuthErrorBody>() }.getOrNull()
            throw AuthException(body?.error_description ?: body?.msg ?: "Sign in failed (${response.status.value})")
        }
        val token = response.body<TokenResponse>()
        return AuthSession(token.access_token, token.user?.id ?: "")
    }
}

private fun String.jsonEscape() = replace("\\", "\\\\").replace("\"", "\\\"")

internal fun apiKeyHeader() = SUPABASE_ANON_KEY
internal fun restBaseUrl() = "$SUPABASE_URL/rest/v1"
