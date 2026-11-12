package com.lagcheck.android.data

import android.content.Context
import com.lagcheck.session.InstallationIdStore
import java.util.UUID

/** UUID anônimo por instalação. Reinstalar gera outro: nada liga o ID a pessoa, conta ou aparelho. */
class PrefsInstallationIdStore(context: Context) : InstallationIdStore {
    private val prefs = context.getSharedPreferences("lagcheck_prefs", Context.MODE_PRIVATE)

    @Synchronized
    override fun getOrCreate(): String {
        val existing = prefs.getString(KEY, null)
        if (existing != null && runCatching { UUID.fromString(existing) }.isSuccess) return existing
        val id = UUID.randomUUID().toString().lowercase()
        prefs.edit().putString(KEY, id).apply()
        return id
    }

    private companion object {
        const val KEY = "lagcheck.analytics.installation_id"
    }
}
