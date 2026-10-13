package com.lagcheck.android.ads

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import com.lagcheck.android.BuildConfig
import com.lagcheck.android.ui.tr
import com.lagcheck.core.designsystem.theme.LagCheckColors

/**
 * Banner adaptativo ancorado, só para Home e Histórico (quem decide é `AdPolicy`).
 * A altura é reservada desde o primeiro render (sem layout shift); falha de carga mantém a área vazia.
 * Rótulo "Anúncio / Ad" sempre visível.
 */
@Composable
fun BannerAdSlot(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val widthDp = LocalConfiguration.current.screenWidthDp
    val size = remember(widthDp) { AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(context, widthDp) }
    Column(modifier = modifier.fillMaxWidth().padding(top = 4.dp)) {
        Text(
            text = tr("Anúncio"),
            fontSize = 12.sp,
            color = LagCheckColors.TextMuted,
            modifier = Modifier.padding(start = 24.dp, bottom = 2.dp)
        )
        Box(
            modifier = Modifier.fillMaxWidth().height(size.height.dp),
            contentAlignment = Alignment.Center
        ) {
            AndroidView(
                factory = { ctx ->
                    AdView(ctx).apply {
                        setAdSize(size)
                        adUnitId = BuildConfig.ADMOB_BANNER_UNIT_ID
                        loadAd(AdRequest.Builder().build())
                    }
                },
                onRelease = { it.destroy() }
            )
        }
    }
}
