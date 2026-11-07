package com.lagcheck.desktop.location

import com.lagcheck.desktop.ui.map.MapPoint

/**
 * Coordenadas de exibição derivadas das cidades-sede públicas das regiões AWS.
 * O catálogo assinado define quais region IDs são medidos; ele não fornece
 * latitude/longitude. Esta tabela não escolhe rota nem cria regiões novas.
 */
object RegionCoordinates {
    private val points = mapOf(
        "sa-east-1" to MapPoint("São Paulo", -23.55, -46.63),
        "us-east-1" to MapPoint("Virgínia do Norte", 38.95, -77.45),
        "us-east-2" to MapPoint("Ohio", 39.96, -83.00),
        "us-west-1" to MapPoint("Norte da Califórnia", 37.34, -121.89),
        "us-west-2" to MapPoint("Oregon", 45.52, -122.68),
        "ca-central-1" to MapPoint("Canadá Central", 45.42, -75.70),
        "eu-central-1" to MapPoint("Frankfurt", 50.11, 8.68),
        "eu-west-1" to MapPoint("Irlanda", 53.35, -6.26),
        "eu-west-2" to MapPoint("Londres", 51.51, -0.13),
        "eu-west-3" to MapPoint("Paris", 48.86, 2.35),
        "eu-north-1" to MapPoint("Estocolmo", 59.33, 18.07),
        "eu-south-1" to MapPoint("Milão", 45.46, 9.19),
        "ap-northeast-1" to MapPoint("Tóquio", 35.68, 139.69),
        "ap-northeast-2" to MapPoint("Seul", 37.57, 126.98),
        "ap-northeast-3" to MapPoint("Osaka", 34.69, 135.50),
        "ap-southeast-1" to MapPoint("Cingapura", 1.35, 103.82),
        "ap-southeast-2" to MapPoint("Sydney", -33.87, 151.21),
        "ap-south-1" to MapPoint("Mumbai", 19.08, 72.88),
        "ap-east-1" to MapPoint("Hong Kong", 22.32, 114.17),
        "me-south-1" to MapPoint("Bahrein", 26.22, 50.59),
        "af-south-1" to MapPoint("Cidade do Cabo", -33.92, 18.42)
    )

    fun forRegion(regionId: String): MapPoint? = points[regionId]
}
