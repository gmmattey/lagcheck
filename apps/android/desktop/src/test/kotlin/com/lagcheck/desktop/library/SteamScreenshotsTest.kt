package com.lagcheck.desktop.library

import com.lagcheck.desktop.library.scanner.SteamScreenshots
import java.io.File
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SteamScreenshotsTest {
    private fun steam(): File {
        val root = Files.createTempDirectory("steam").toFile()
        val userdata = File(root, "userdata/111/760").apply { mkdirs() }
        File(userdata, "remote/42/screenshots/thumbnails").mkdirs()
        File(userdata, "remote/42/screenshots/a.jpg").writeText("x")
        File(userdata, "remote/42/screenshots/thumbnails/a.jpg").writeText("x")
        File(userdata, "remote/42/screenshots/b.jpg").writeText("x")
        File(userdata, "screenshots.vdf").writeText(
            """
            "screenshots"
            {
              "42"
              {
                "0" { "filename" "42/screenshots/a.jpg" "thumbnail" "42/screenshots/thumbnails/a.jpg" "width" "1920" "height" "1080" "gameid" "42" "creation" "1000" }
                "1" { "filename" "42/screenshots/b.jpg" "gameid" "42" "creation" "2000" }
                "2" { "filename" "42/screenshots/sumiu.jpg" "gameid" "42" "creation" "3000" }
              }
              "shortcutnames" { }
            }
            """.trimIndent()
        )
        return root
    }

    @Test
    fun `lista so prints existentes do jogo, mais recentes primeiro`() {
        val shots = SteamScreenshots { steam() }.forApp("42")
        assertEquals(2, shots.size)
        assertEquals(2_000_000L, shots[0].createdEpochMs)
        assertNull(shots[0].thumbnailPath)
        assertTrue(shots[1].thumbnailPath!!.endsWith("a.jpg"))
        assertEquals(1920, shots[1].width)
    }

    @Test
    fun `jogo sem prints e Steam ausente devolvem vazio`() {
        assertTrue(SteamScreenshots { steam() }.forApp("99").isEmpty())
        assertTrue(SteamScreenshots { null }.forApp("42").isEmpty())
    }
}
