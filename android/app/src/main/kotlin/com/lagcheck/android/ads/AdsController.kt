package com.lagcheck.android.ads

import android.app.Activity
import com.google.android.gms.ads.MobileAds
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.ConsentInformation
import com.google.android.ump.UserMessagingPlatform
import com.lagcheck.android.BuildConfig
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Consentimento (UMP) e inicialização do AdMob. Dormente enquanto `BuildConfig.ADS_ENABLED` for falso:
 * nada é solicitado, nada é inicializado. Chamado na Home, nunca durante um check (Decisão 82).
 */
class AdsController(private val activity: Activity) {
    val enabled: Boolean = BuildConfig.ADS_ENABLED

    private val _canRequestAds = MutableStateFlow(false)
    /** Só com isso há requisição de anúncio. */
    val canRequestAds: StateFlow<Boolean> = _canRequestAds.asStateFlow()

    private val _privacyOptionsRequired = MutableStateFlow(false)
    /** "Opções de privacidade" aparece em Configurações quando o UMP exigir. */
    val privacyOptionsRequired: StateFlow<Boolean> = _privacyOptionsRequired.asStateFlow()

    private var started = false
    private var initialized = false
    private val consent: ConsentInformation by lazy { UserMessagingPlatform.getConsentInformation(activity) }

    /** requestConsentInfoUpdate a cada abertura; exibe o formulário só se exigido. */
    fun start() {
        if (!enabled || started) return
        started = true
        refresh() // sessão anterior já pode ter consentimento
        consent.requestConsentInfoUpdate(
            activity,
            ConsentRequestParameters.Builder().build(),
            {
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) { refresh() }
            },
            { refresh() }
        )
    }

    fun showPrivacyOptions() {
        if (!enabled) return
        UserMessagingPlatform.showPrivacyOptionsForm(activity) { refresh() }
    }

    private fun refresh() {
        _canRequestAds.value = consent.canRequestAds()
        _privacyOptionsRequired.value =
            consent.privacyOptionsRequirementStatus == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
        if (_canRequestAds.value && !initialized) {
            initialized = true
            // Fora da thread principal, depois do consentimento.
            Thread { MobileAds.initialize(activity.applicationContext) {} }.start()
        }
    }
}
