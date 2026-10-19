package com.nulljosh.litigate

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AuthTest {
    @Test fun endpointsPointAtSharedSparkProject() {
        assertTrue(restBaseUrl().startsWith("https://tjsxsqlxjmanwvmywwvw.supabase.co"))
        assertTrue(apiKeyHeader().isNotBlank())
    }
}
