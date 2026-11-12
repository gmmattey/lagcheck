package com.lagcheck.android.data

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager

/** Ícones do launcher (Decisão 83): um activity-alias por opção; só um fica habilitado. */
enum class AppIcon(val alias: String, val title: String, val subtitle: String, val foreground: Int?) {
    CLASSIC(".icon.ClassicIcon", "Clássico", "Glifo roxo", null),
    THUMBS(".icon.ThumbsIcon", "Joinha", "Mascote", com.lagcheck.android.R.drawable.ic_launcher_thumbs_fg),
    WINK(".icon.WinkIcon", "Piscadinha", "Mascote", com.lagcheck.android.R.drawable.ic_launcher_wink_fg),
    CHEER(".icon.CheerIcon", "Comemorando", "Mascote", com.lagcheck.android.R.drawable.ic_launcher_cheer_fg)
}

object AppIconManager {
    private fun component(context: Context, icon: AppIcon) = ComponentName(context.packageName, "com.lagcheck.android" + icon.alias)

    /** O que está habilitado no sistema é a fonte da verdade (o padrão do manifesto é o Clássico). */
    fun current(context: Context): AppIcon {
        val pm = context.packageManager
        return AppIcon.entries.firstOrNull { icon ->
            when (pm.getComponentEnabledSetting(component(context, icon))) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
                PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> icon == AppIcon.CLASSIC &&
                    AppIcon.entries.none { other -> other != icon && pm.getComponentEnabledSetting(component(context, other)) == PackageManager.COMPONENT_ENABLED_STATE_ENABLED }
                else -> false
            }
        } ?: AppIcon.CLASSIC
    }

    /** Habilita o novo antes de desabilitar os outros: o app nunca fica sem ícone no launcher. */
    fun set(context: Context, icon: AppIcon) {
        val pm = context.packageManager
        pm.setComponentEnabledSetting(component(context, icon), PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
        AppIcon.entries.filter { it != icon }.forEach {
            pm.setComponentEnabledSetting(component(context, it), PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
        }
    }
}
