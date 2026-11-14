package com.lagcheck.android.ui.components

import android.provider.Settings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.lagcheck.android.data.ApproxLocationClient
import com.lagcheck.android.ui.tr
import com.lagcheck.core.designsystem.components.map.MapGeoPoint
import com.lagcheck.core.designsystem.components.map.RouteMapController
import com.lagcheck.core.designsystem.components.map.RouteMapOrigin
import com.lagcheck.core.designsystem.components.map.RouteMapProjection
import com.lagcheck.core.designsystem.components.map.RouteMeasurementMap
import java.util.Locale

/**
 * Ligação entre o app e o mapa de medição (mesmo comportamento do site). "Você" vem da localização aproximada pelo IP
 * (endpoint do site, ~50 km); se ela falhar, do país configurado no aparelho. A região, a varredura e as sondas vêm só
 * da medição.
 */
object RouteMapSupport {
    /** Reserva quando a consulta por IP falha: ponto do país do aparelho, sem cidade. */
    fun countryPoint(): MapGeoPoint? = RouteMapOrigin.approximatePoint(Locale.getDefault().country)

    fun canDraw(regionId: String?): Boolean = regionId != null && RouteMapProjection.regionPoint(regionId) != null

    /** Garante "Você" num mapa que não passou pela varredura (usa o resultado do IP já obtido no check). */
    fun ensureUser(controller: RouteMapController) {
        if (controller.user != null || controller.locationUnavailable) return
        val cached = ApproxLocationClient.cachedLocation()
        if (cached != null) controller.setUser(MapGeoPoint(cached.lat, cached.lon), cached.city)
        else controller.setUser(countryPoint())
    }
}

/** Mapa de medição com os textos do app e a preferência "Remover animações" do sistema. */
@Composable
fun LagCheckRouteMap(
    controller: RouteMapController,
    regionName: (String) -> String,
    modifier: Modifier = Modifier
) {
    RouteMeasurementMap(
        controller = controller,
        userLabel = tr("Você"),
        unavailableLabel = tr("Localização aproximada indisponível"),
        accessibilityText = tr("Mapa da rota medida"),
        regionName = regionName,
        modifier = modifier,
        reduceMotion = rememberReduceMotion()
    )
}

/** "Remover animações" do Android zera a escala de animação: o mapa deixa de mover pacotes. */
@Composable
fun rememberReduceMotion(): Boolean {
    val resolver = LocalContext.current.contentResolver
    return remember(resolver) {
        runCatching { Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }
            .getOrDefault(false)
    }
}
