package com.lagcheck.desktop.ui.map

import androidx.compose.ui.geometry.Offset
import com.lagcheck.desktop.ds.LcColor
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RouteMapTest {

    // 1. Projeção (lat/lon para x/y e inverso)
    @Test
    fun testProjectionAndUnprojection() {
        val width = 800f
        val height = 400f
        val cam = Camera(lon = -46.63, lat = -23.55, zoom = 1.8)

        // Centro da câmera deve projetar para o centro da tela
        val center = project(lat = cam.lat, lon = cam.lon, cam = cam, width = width, height = height)
        assertEquals(width / 2f, center.x, 0.001f, "Centro lon deve cair em width/2")
        assertEquals(height / 2f, center.y, 0.001f, "Centro lat deve cair em height/2")

        // Ida e volta: lat/lon -> (x, y) -> lat/lon
        val testPoints = listOf(
            Pair(-12.97, -38.51), // Salvador
            Pair(38.95, -77.45),  // Virgínia
            Pair(50.11, 8.68),    // Frankfurt
            Pair(35.68, 139.75),  // Tóquio
            Pair(0.0, 0.0)        // Meridiano / Equador
        )

        for ((lat, lon) in testPoints) {
            val screenPos = project(lat, lon, cam, width, height)
            val (invLat, invLon) = unproject(screenPos.x, screenPos.y, cam, width, height)
            assertEquals(lat, invLat, 0.0001, "Latitude invertida deve coincidir")
            assertEquals(lon, invLon, 0.0001, "Longitude invertida deve coincidir")
        }
    }

    // 2. Curva de Bézier (início, fim e meio)
    @Test
    fun testBezierArcCurve() {
        val p0 = Offset(100f, 300f)
        val p1 = Offset(500f, 300f)
        val arc = computeArc(p0, p1)

        assertEquals(p0.x, arc.x0, 0.001f)
        assertEquals(p0.y, arc.y0, 0.001f)
        assertEquals(p1.x, arc.x1, 0.001f)
        assertEquals(p1.y, arc.y1, 0.001f)

        // Altura do arco deve projetar para cima (y diminuindo na tela)
        assertTrue(arc.cy < (p0.y + p1.y) / 2f, "Ponto de controle deve apontar para cima (cy < yMedio)")

        // Início (t = 0.0)
        val start = bezierPoint(arc, 0f)
        assertEquals(p0.x, start.x, 0.001f, "t=0 deve ser exatamente p0.x")
        assertEquals(p0.y, start.y, 0.001f, "t=0 deve ser exatamente p0.y")

        // Fim (t = 1.0)
        val end = bezierPoint(arc, 1f)
        assertEquals(p1.x, end.x, 0.001f, "t=1 deve ser exatamente p1.x")
        assertEquals(p1.y, end.y, 0.001f, "t=1 deve ser exatamente p1.y")

        // Meio (t = 0.5): B(0.5) = 0.25*P0 + 0.5*Pc + 0.25*P1
        val mid = bezierPoint(arc, 0.5f)
        val expectedMidX = 0.25f * arc.x0 + 0.5f * arc.cx + 0.25f * arc.x1
        val expectedMidY = 0.25f * arc.y0 + 0.5f * arc.cy + 0.25f * arc.y1
        assertEquals(expectedMidX, mid.x, 0.001f, "t=0.5 x deve satisfazer a fórmula de Bézier")
        assertEquals(expectedMidY, mid.y, 0.001f, "t=0.5 y deve satisfazer a fórmula de Bézier")
    }

    // 3. Câmera (zoom enquadra os dois pontos, clamp)
    @Test
    fun testCameraFramingAndClamping() {
        val width = 1000f
        val height = 500f

        val user = MapPoint("Salvador", -12.97, -38.51)
        val nearServer = MapPoint("São Paulo", -23.55, -46.63)
        val farServer = MapPoint("Tóquio", 35.68, 139.75)

        // Pontos distantes devem ter zoom menor, limitado a no mínimo 1.0
        val farCam = frameCamera(user, farServer, width, height, maxZoom = 3.4)
        assertTrue(farCam.zoom >= 1.0, "Zoom deve ser >= 1.0")
        assertTrue(farCam.zoom <= 3.4, "Zoom não deve ultrapassar maxZoom")
        assertEquals((user.lon + farServer.lon) / 2.0, farCam.lon, 0.001, "Lon da câmera deve ser o ponto médio")
        assertEquals((user.lat + farServer.lat) / 2.0, farCam.lat, 0.001, "Lat da câmera deve ser o ponto médio")

        // Pontos muito próximos (ex: quase idênticos) com maxZoom explícito (3.4)
        val samePoint = MapPoint("Mesmo Ponto", user.lat + 0.1, user.lon + 0.1)
        val clampedCam = frameCamera(user, samePoint, width, height, maxZoom = 3.4)
        assertEquals(3.4, clampedCam.zoom, 0.001, "Pontos muito próximos devem ser travados em maxZoom (3.4)")
    }

    // 4. Leitura e contagem da grade (240×95, ~6.858 pontos)
    @Test
    fun testGridParsingAndCount() {
        val grid = MapGrid.loadFromResources()

        assertEquals(240, grid.cols, "Colunas devem ser 240")
        assertEquals(95, grid.rows, "Linhas devem ser 95")
        assertEquals(1.5, grid.step, 0.0001, "Passo deve ser 1.5°")
        assertEquals(84.0, grid.latTop, 0.0001, "latTop deve ser 84.0°")
        assertEquals(-58.0, grid.latBottom, 0.0001, "latBottom deve ser -58.0°")

        // Exatamente 6.858 pontos de terra
        assertEquals(6858, grid.pointCount, "Contagem de pontos de terra deve ser exatamente 6858")
        assertEquals(6858, grid.landLons.size)
        assertEquals(6858, grid.landLats.size)

        // Confere que todos os pontos estão dentro dos limites geográficos
        for (i in 0 until grid.pointCount) {
            val lon = grid.landLons[i]
            val lat = grid.landLats[i]
            assertTrue(lon in -180f..180f, "Longitude $lon fora dos limites")
            assertTrue(lat in -58f..84f, "Latitude $lat fora dos limites")
        }
    }

    // 5. RouteMapState (pacote some em 58% quando perdido; retorno registra RTT; reset limpa)
    @Test
    fun testRouteMapStateLifecycle() {
        val state = RouteMapState()
        val user = MapPoint("Salvador", -12.97, -38.51)
        val server = MapPoint("São Paulo", -23.55, -46.63)

        val t0 = 1_000_000_000L

        // Dispara sonda 0
        state.onProbeSentInternal(0, t0)
        assertEquals(1, state.packets.size, "Deve haver 1 pacote ativo após envio")
        val p0 = state.packets[0]
        assertEquals(PacketPhase.OUTBOUND, p0.phase)
        assertEquals(false, p0.lost)

        // Marca sonda 0 como perdida
        state.onProbeLostInternal(0, t0 + 100_000_000L)
        assertTrue(p0.lost, "Pacote deve estar marcado como perdido")

        // Aos 50% da duração (210 ms num padrão de 420 ms): pacote ainda visível
        val halfTime = t0 + (RouteMapState.DEFAULT_FLY_DURATION_NANOS * 0.50).toLong()
        state.updateTime(halfTime, user, server)
        assertEquals(1, state.packets.size, "Pacote perdido ainda deve estar em voo a 50%")
        assertTrue(p0.elapsedFraction >= 0.50f)

        // Aos 59% da duração (ultrapassando os 58% de LOST_THRESHOLD): pacote some
        val pastLostTime = t0 + (RouteMapState.DEFAULT_FLY_DURATION_NANOS * 0.59).toLong()
        state.updateTime(pastLostTime, user, server)
        assertEquals(0, state.packets.size, "Pacote perdido deve sumir ao atingir 58%")

        // Sonda 1: retorno com RTT registrado
        val t1 = 2_000_000_000L
        state.onProbeSentInternal(1, t1)
        state.onProbeReturnedInternal(1, 28.4, t1 + 100_000_000L)

        assertEquals(1, state.rttHistory.size, "Deve ter registrado 1 RTT")
        assertEquals(28.4, state.medianRttMs)

        // Adiciona mais RTTs para verificar mediana
        state.onProbeReturnedInternal(2, 40.0, t1 + 200_000_000L)
        state.onProbeReturnedInternal(3, 15.0, t1 + 300_000_000L)
        // [15.0, 28.4, 40.0] -> mediana = 28.4
        assertEquals(28.4, state.medianRttMs)

        // Reset limpa tudo
        state.reset()
        assertEquals(0, state.packets.size, "Reset deve limpar pacotes")
        assertEquals(0, state.rings.size, "Reset deve limpar anéis")
        assertEquals(0, state.rttHistory.size, "Reset deve limpar histórico de RTTs")
        assertNull(state.medianRttMs, "Mediana deve ser nula após reset")
        assertEquals(false, state.hasActiveAnimations, "Animações ativas devem ser falsas após reset")
    }

    // 6. Reduzir movimento desativa pacotes e anéis
    @Test
    fun testReducedMotionDisablesPackets() {
        val state = RouteMapState()
        state.reducedMotion = true

        state.onProbeSent(0)
        assertEquals(0, state.packets.size, "Quando reducedMotion for true, não deve criar pacotes")

        state.emitRing(-12.97, -38.51, 60f, LcColor.Accent)
        assertEquals(0, state.rings.size, "Quando reducedMotion for true, não deve emitir anéis")
    }

    // 7. Enquadramento com zoom máximo padrão (2.2) e modo "só a região" (user == null)
    @Test
    fun testDefaultMaxZoomAndRegionOnlyFraming() {
        val width = 1000f
        val height = 500f
        val user = MapPoint("Salvador", -12.97, -38.51)
        val samePoint = MapPoint("Mesmo Ponto", user.lat + 0.05, user.lon + 0.05)
        val region = MapPoint("São Paulo", -23.55, -46.63)

        // Com usuário, zoom máximo padrão agora é 2.2 para visão mais ampla de contexto
        val defaultClampedCam = frameCamera(user, samePoint, width, height)
        assertEquals(2.2, defaultClampedCam.zoom, 0.001, "Zoom máximo padrão deve ser 2.2")

        // Modo 'só a região' (user == null): câmera centrada na região com zoom 2.2
        val regionOnlyCam = frameCamera(null, region, width, height)
        assertEquals(region.lon, regionOnlyCam.lon, 0.0001, "Lon da câmera deve ser a lon da região")
        assertEquals(region.lat, regionOnlyCam.lat, 0.0001, "Lat da câmera deve ser a lat da região")
        assertEquals(2.2, regionOnlyCam.zoom, 0.0001, "Zoom deve ser 2.2 no modo só a região")

        // No modo só a região, o ponto da região projeta exatamente no centro da tela
        val regionOffset = project(region.lat, region.lon, regionOnlyCam, width, height)
        assertEquals(width / 2f, regionOffset.x, 0.001f, "Região deve projetar no centro horizontal da tela")
        assertEquals(height / 2f, regionOffset.y, 0.001f, "Região deve projetar no centro vertical da tela")

        // Modo 'só a região' respeitando maxZoom customizado quando fornecido
        val customZoomCam = frameCamera(null, region, width, height, maxZoom = 1.8)
        assertEquals(1.8, customZoomCam.zoom, 0.0001, "Zoom deve respeitar maxZoom customizado")
    }

    // 8. Ciclo de vida do RouteMapState sem usuário (user == null)
    @Test
    fun testRouteMapStateWithoutUser() {
        val state = RouteMapState()
        val region = MapPoint("São Paulo", -23.55, -46.63)
        val t0 = 1_000_000_000L

        // Recebe respostas UDP mesmo sem localização do usuário
        state.onProbeSentInternal(0, t0)
        state.onProbeReturnedInternal(0, 19.5, t0 + 100_000_000L)
        state.onProbeReturnedInternal(1, 23.0, t0 + 200_000_000L)

        assertEquals(2, state.rttHistory.size)
        assertEquals(21.25, state.medianRttMs)

        // Atualização de tempo com user == null: não adiciona anel de onda em 'Você'
        val pastReturnTime = t0 + 1_000_000_000L
        state.updateTime(pastReturnTime, user = null, region = region)
        assertEquals(0, state.rings.size, "Com user == null não deve emitir anel em 'Você'")
    }
}
