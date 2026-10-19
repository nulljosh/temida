package com.nulljosh.litigate

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

@Composable
fun LitigateTheme(content: @Composable () -> Unit) =
    MaterialTheme(colorScheme = lightColorScheme(), content = content)

// No hardcoded case content anywhere in this file -- everything rendered
// here comes from the JsonElement fetched at runtime after sign-in, exactly
// matching NativeFragments.swift's rule on iOS/macOS. Single-user sign-in,
// no signup form (native has never had one).
@Composable
fun AppScreen(
    auth: LitigateAuth = LitigateAuth(),
    briefData: BriefDataClient = BriefDataClient(),
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var session by remember { mutableStateOf<AuthSession?>(null) }
    var cases by remember { mutableStateOf<JsonElement?>(null) }
    var error by remember { mutableStateOf<String?>(null) }
    var loading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    fun signIn() {
        scope.launch {
            loading = true
            error = null
            runCatching {
                val s = auth.signIn(email, password)
                session = s
                cases = briefData.fetch(s, "cases")
            }.onFailure { error = it.message ?: "Sign in failed" }
            loading = false
        }
    }

    Surface {
        Column(Modifier.fillMaxSize().padding(24.dp)) {
            Text("Litigate", style = MaterialTheme.typography.headlineMedium)
            val currentSession = session
            when {
                currentSession == null -> {
                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        label = { Text("Email") },
                        modifier = Modifier.fillMaxWidth().padding(top = 16.dp),
                    )
                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = { Text("Password") },
                        visualTransformation = PasswordVisualTransformation(),
                        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                    )
                    Button(onClick = { signIn() }, modifier = Modifier.padding(top = 8.dp)) { Text("Sign in") }
                    if (loading) CircularProgressIndicator(Modifier.padding(top = 16.dp))
                    error?.let { Text(it, modifier = Modifier.padding(top = 8.dp)) }
                }
                cases == null -> Text("No case data for this account.", modifier = Modifier.padding(top = 24.dp))
                else -> LazyColumn(modifier = Modifier.padding(top = 16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    items(jsonLines(cases!!)) { line -> Text(line) }
                }
            }
        }
    }
}

/** Flattens a JsonElement into "key: value" lines for a first-pass generic
 *  viewer. No field names or values here are hardcoded -- this walks
 *  whatever the account's own row contains. */
private fun jsonLines(element: JsonElement, prefix: String = ""): List<String> = when (element) {
    is JsonObject -> element.entries.flatMap { (k, v) -> jsonLines(v, if (prefix.isEmpty()) k else "$prefix.$k") }
    is JsonArray -> element.mapIndexed { i, v -> jsonLines(v, "$prefix[$i]") }.flatten()
    is JsonPrimitive -> listOf("$prefix: ${element.content}")
    is JsonNull -> emptyList()
}
