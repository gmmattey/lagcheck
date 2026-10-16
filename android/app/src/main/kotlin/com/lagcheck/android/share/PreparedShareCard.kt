package com.lagcheck.android.share

import android.content.Context
import com.lagcheck.android.ui.AppLocale
import java.io.File
import java.security.MessageDigest

/** Snapshot imutável de todos os campos que o card de link efetivamente desenha. */
internal data class PreparedShareCardSnapshot(
    val gameName: String,
    val artDrawableName: String,
    val tone: ShareTone,
    val headline: String,
    val regionName: String,
    val metrics: List<ShareMetric>,
    val localeTag: String,
    val measurementIdentity: String
) {
    val cacheKey: String
        get() = buildString {
            append(gameName).append('|').append(artDrawableName).append('|').append(tone.name)
            append('|').append(headline).append('|').append(regionName).append('|').append(localeTag).append('|').append(measurementIdentity)
            metrics.forEach { append('|').append(it.kind.name).append(':').append(it.value).append(':').append(it.unit) }
        }

    fun scene() = ShareMediaScene(gameName, artDrawableName, tone, headline, regionName, metrics)

    companion object {
        fun from(scene: ShareMediaScene, localeTag: String, measurementIdentity: String) = PreparedShareCardSnapshot(
            scene.gameName, scene.artDrawableName, scene.tone, scene.headline, scene.regionName, scene.metrics, localeTag, measurementIdentity
        )
    }
}

/**
 * Cache efêmero do card de link. O arquivo é identificado pelo snapshot que o
 * originou, para que um reteste nunca entregue por acidente o card anterior.
 */
internal object PreparedShareCard {
    private val lock = Any()

    fun fileFor(context: Context, snapshot: PreparedShareCardSnapshot): File = File(
        context.cacheDir,
        "share/lagcheck-link-${digest(snapshot.cacheKey)}.jpg"
    )

    fun prepare(context: Context, snapshot: PreparedShareCardSnapshot): File {
        return synchronized(lock) {
            val file = fileFor(context, snapshot)
            if (file.isFile && file.length() > 0L) return@synchronized file

            val scene = snapshot.scene()
            val images = ShareMediaImages.load(context, scene, AppLocale.language, withTiles = false)
            val bytes = ShareMediaRenderer.jpeg(ShareMediaRenderer.Kind.PREVIEW, scene, images)
            val temporary = File(file.parentFile, "${file.name}.tmp")
            file.parentFile?.mkdirs()
            temporary.writeBytes(bytes)
            if (!temporary.renameTo(file)) {
                temporary.delete()
                error("Could not finalize prepared share card")
            }
            file
        }
    }

    internal fun digest(snapshotKey: String): String = MessageDigest.getInstance("SHA-256")
        .digest(snapshotKey.toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it) }
        .take(24)
}
