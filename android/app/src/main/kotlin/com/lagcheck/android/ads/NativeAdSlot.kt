package com.lagcheck.android.ads

import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.FrameLayout
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdLoader
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import com.lagcheck.android.BuildConfig
import com.lagcheck.android.ui.tr
import com.lagcheck.session.ads.AdPlacement
import com.lagcheck.core.designsystem.theme.LagCheckColors

/** Mantém a requisição e o NativeAd vivos enquanto a tela está composta, inclusive fora da janela da LazyColumn. */
@Composable
fun rememberNativeAd(placement: AdPlacement): NativeAd? {
    val context = LocalContext.current
    val unitId = when (placement) {
        AdPlacement.HOME -> BuildConfig.ADMOB_NATIVE_HOME_UNIT_ID
        AdPlacement.HISTORY -> BuildConfig.ADMOB_NATIVE_HISTORY_UNIT_ID
        AdPlacement.GAMES -> BuildConfig.ADMOB_NATIVE_GAMES_UNIT_ID
        AdPlacement.RESULT -> BuildConfig.ADMOB_NATIVE_RESULT_UNIT_ID
    }
    var ad by remember(placement, unitId) { mutableStateOf<NativeAd?>(null) }
    DisposableEffect(placement, unitId) {
        var active = true
        val loader = AdLoader.Builder(context, unitId)
            .forNativeAd { loaded ->
                if (active) {
                    ad?.destroy()
                    ad = loaded
                } else {
                    loaded.destroy()
                }
            }
            .withAdListener(object : AdListener() {
                override fun onAdFailedToLoad(error: LoadAdError) {
                    if (active) ad = null
                }
            })
            .build()
        loader.loadAd(AdRequest.Builder().build())
        onDispose {
            active = false
            ad?.destroy()
            ad = null
        }
    }
    return ad
}

/** A View pode ser descartada ao rolar sem perder o anúncio carregado. */
@Composable
fun NativeAdSlot(ad: NativeAd, modifier: Modifier = Modifier) {
    val label = tr("Anúncio")
    AndroidView(
        modifier = modifier.fillMaxWidth(),
        factory = { ctx -> createNativeAdView(ctx, label, ad) },
        update = { view ->
            (view.tag as? TextView)?.apply {
                text = label
                contentDescription = label
            }
        },
        onRelease = { it.destroy() }
    )
}

private fun createNativeAdView(context: android.content.Context, label: String, ad: NativeAd): NativeAdView {
    val density = context.resources.displayMetrics.density
    fun dp(value: Int) = (value * density + 0.5f).toInt()
    fun text(value: String, size: Float, color: Int, bold: Boolean = false) = TextView(context).apply {
        this.text = value
        textSize = size
        setTextColor(color)
        if (bold) setTypeface(typeface, Typeface.BOLD)
    }
    val primary = LagCheckColors.TextPrimary.toArgb()
    val secondary = LagCheckColors.TextMuted.toArgb()
    val view = NativeAdView(context)
    view.background = GradientDrawable().apply {
        setColor(LagCheckColors.Surface.toArgb())
        cornerRadius = dp(16).toFloat()
        setStroke(dp(1), LagCheckColors.Border.toArgb())
    }
    val content = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(16), dp(12), dp(16), dp(16))
    }
    view.addView(content, FrameLayout.LayoutParams(-1, -2))

    // O SDK insere AdChoices no NativeAdView; a primeira linha reserva seu canto superior direito.
    val badge = text(label, 12f, secondary, true).apply {
        contentDescription = label
        setPadding(dp(7), dp(3), dp(7), dp(3))
        background = GradientDrawable().apply {
            setColor(LagCheckColors.Panel.toArgb())
            cornerRadius = dp(4).toFloat()
        }
    }
    content.addView(badge, LinearLayout.LayoutParams(-2, -2).apply { bottomMargin = dp(10) })
    view.tag = badge

    val row = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
    content.addView(row)
    val icon = ImageView(context).apply { scaleType = ImageView.ScaleType.FIT_CENTER }
    if (ad.icon != null) {
        icon.setImageDrawable(ad.icon!!.drawable)
        row.addView(icon, LinearLayout.LayoutParams(dp(44), dp(44)).apply { rightMargin = dp(12) })
        view.iconView = icon
    }
    val headings = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
    row.addView(headings, LinearLayout.LayoutParams(0, -2, 1f))
    val headline = text(ad.headline.orEmpty(), 16f, primary, true).apply { maxLines = 2 }
    headings.addView(headline)
    view.headlineView = headline
    ad.advertiser?.let { advertiser ->
        val advertiserView = text(advertiser, 12f, secondary).apply { maxLines = 1 }
        headings.addView(advertiserView)
        view.advertiserView = advertiserView
    }
    ad.body?.let { body ->
        val bodyView = text(body, 14f, secondary).apply { maxLines = 3 }
        content.addView(bodyView, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(10) })
        view.bodyView = bodyView
    }
    ad.mediaContent?.let { media ->
        val mediaView = MediaView(context)
        mediaView.mediaContent = media
        content.addView(mediaView, LinearLayout.LayoutParams(-1, dp(150)).apply { topMargin = dp(12) })
        view.mediaView = mediaView
    }
    ad.callToAction?.let { callToAction ->
        val cta = text(callToAction, 14f, primary, true).apply {
            gravity = Gravity.CENTER
            minHeight = dp(44)
            contentDescription = callToAction
            background = GradientDrawable().apply {
                setColor(LagCheckColors.Panel.toArgb())
                setStroke(dp(1), LagCheckColors.Border.toArgb())
                cornerRadius = dp(10).toFloat()
            }
        }
        content.addView(cta, LinearLayout.LayoutParams(-1, dp(44)).apply { topMargin = dp(12) })
        view.callToActionView = cta
    }
    view.setNativeAd(ad)
    return view
}
