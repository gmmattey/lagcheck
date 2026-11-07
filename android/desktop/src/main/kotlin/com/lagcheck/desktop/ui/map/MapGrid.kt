package com.lagcheck.desktop.ui.map

/**
 * Grade de pontos de terra do mapa-múndi pré-calculada (dot-matrix).
 *
 * Baseada no Natural Earth 110m (240x95 células a 1.5°).
 * Mantém coordenadas geográficas pré-calculadas em FloatArray para desempenho
 * máximo sem alocação por frame durante a renderização no Canvas.
 */
class MapGrid(
    val step: Double,
    val latTop: Double,
    val latBottom: Double,
    val cols: Int,
    val rows: Int,
    val landLons: FloatArray,
    val landLats: FloatArray
) {
    val pointCount: Int get() = landLons.size

    companion object {
        private const val DEFAULT_RESOURCE = "/map/map-grid.json"

        @Volatile
        private var cachedInstance: MapGrid? = null

        /**
         * Carrega a grade a partir dos recursos embutidos da aplicação.
         */
        fun loadFromResources(resourcePath: String = DEFAULT_RESOURCE): MapGrid {
            cachedInstance?.let { return it }
            val stream = MapGrid::class.java.getResourceAsStream(resourcePath)
                ?: error("Recurso da grade do mapa não encontrado em: $resourcePath")
            val text = stream.bufferedReader(Charsets.UTF_8).use { it.readText() }
            return parse(text).also { cachedInstance = it }
        }

        /**
         * Faz o parse do JSON da grade sem dependências externas.
         */
        fun parse(jsonText: String): MapGrid {
            val step = extractDouble(jsonText, "step") ?: 1.5
            val latTop = extractDouble(jsonText, "latTop") ?: 84.0
            val latBottom = extractDouble(jsonText, "latBottom") ?: -58.0
            val cols = extractInt(jsonText, "cols") ?: 240
            val rows = extractInt(jsonText, "rows") ?: 95

            val gridRows = extractGridArray(jsonText)

            val lons = ArrayList<Float>(7000)
            val lats = ArrayList<Float>(7000)

            for (r in 0 until minOf(rows, gridRows.size)) {
                val lat = (latTop - (r + 0.5) * step).toFloat()
                val rowStr = gridRows[r]
                val limit = minOf(cols, rowStr.length)
                for (c in 0 until limit) {
                    if (rowStr[c] == '1') {
                        val lon = (-180.0 + (c + 0.5) * step).toFloat()
                        lons.add(lon)
                        lats.add(lat)
                    }
                }
            }

            val lonsArr = FloatArray(lons.size)
            val latsArr = FloatArray(lats.size)
            for (i in lons.indices) {
                lonsArr[i] = lons[i]
                latsArr[i] = lats[i]
            }

            return MapGrid(
                step = step,
                latTop = latTop,
                latBottom = latBottom,
                cols = cols,
                rows = rows,
                landLons = lonsArr,
                landLats = latsArr
            )
        }

        private fun extractDouble(json: String, key: String): Double? {
            val pattern = Regex("\"$key\"\\s*:\\s*(-?[0-9]+(?:\\.[0-9]+)?)")
            return pattern.find(json)?.groupValues?.get(1)?.toDoubleOrNull()
        }

        private fun extractInt(json: String, key: String): Int? {
            val pattern = Regex("\"$key\"\\s*:\\s*(-?[0-9]+)")
            return pattern.find(json)?.groupValues?.get(1)?.toIntOrNull()
        }

        private fun extractGridArray(json: String): List<String> {
            val gridStart = json.indexOf("\"grid\"")
            if (gridStart == -1) return emptyList()
            val arrayStart = json.indexOf('[', gridStart)
            if (arrayStart == -1) return emptyList()
            val arrayEnd = json.lastIndexOf(']')
            if (arrayEnd <= arrayStart) return emptyList()

            val rows = mutableListOf<String>()
            val regex = Regex("\"([01]+)\"")
            regex.findAll(json.substring(arrayStart, arrayEnd + 1)).forEach {
                rows.add(it.groupValues[1])
            }
            return rows
        }
    }
}
