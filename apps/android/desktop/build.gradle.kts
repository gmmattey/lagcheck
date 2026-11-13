import org.jetbrains.compose.desktop.application.dsl.TargetFormat

plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.compose.multiplatform)
}

kotlin {
    compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) }
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

// O desktop embala as mesmas artes editoriais e a wordmark já aprovadas no Android.
// Não há download, URL externa ou segunda fonte de assets.
sourceSets {
    named("main") {
        resources.srcDir("../app/src/main/res/drawable")
        resources.srcDir("../app/src/main/res/drawable-xxhdpi")
        resources.srcDir(layout.buildDirectory.dir("generated/lagcheck-runtime"))
    }
}

val packageRequested = gradle.startParameter.taskNames.any {
    it.contains("packageMsi", ignoreCase = true) ||
        it.contains("packageExe", ignoreCase = true) ||
        it.contains("createDistributable", ignoreCase = true)
}
val ga4MeasurementId = providers.gradleProperty("lagcheck.ga4.measurementId")
    .orElse(providers.environmentVariable("LAGCHECK_GA4_MEASUREMENT_ID")).orNull.orEmpty()
val ga4ApiSecret = providers.gradleProperty("lagcheck.ga4.apiSecret")
    .orElse(providers.environmentVariable("LAGCHECK_GA4_API_SECRET")).orNull.orEmpty()
val generateRuntimeConfig by tasks.registering {
    val output = layout.buildDirectory.file("generated/lagcheck-runtime/lagcheck-runtime.properties")
    outputs.file(output)
    doLast {
        output.get().asFile.apply {
            parentFile.mkdirs()
            writeText(
                "analytics.enabled=${packageRequested && ga4MeasurementId.isNotBlank() && ga4ApiSecret.isNotBlank()}\n" +
                    "analytics.measurementId=$ga4MeasurementId\n" +
                    "analytics.apiSecret=$ga4ApiSecret\n"
            )
        }
    }
}

tasks.named("processResources") { dependsOn(generateRuntimeConfig) }

dependencies {
    // Mesmo núcleo do Android: regra, catálogo, UDP e sessão. Nada de regra duplicada aqui.
    implementation(project(":core:session"))
    implementation(compose.desktop.currentOs)
    implementation(compose.material3)
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.serialization.json)
    testImplementation(kotlin("test"))
}

compose.desktop {
    application {
        mainClass = "com.lagcheck.desktop.MainKt"
        // Evita a alteração intermitente de cores observada com Direct3D no Windows,
        // preservando aceleração pela GPU. Skiko tenta os backends compatíveis se falhar.
        if (System.getProperty("os.name").startsWith("Windows", ignoreCase = true)) {
            jvmArgs("-Dskiko.renderApi=OPENGL")
        }
        nativeDistributions {
            targetFormats(TargetFormat.Msi, TargetFormat.Exe)
            // O runtime enxuto (jlink) não inclui o cliente HTTP por padrão: sem este módulo
            // o app fecha na abertura com NoClassDefFoundError (java/net/http/HttpClient).
            modules("java.net.http")
            packageName = "LagCheck"
            // O empacotador do Windows (jpackage / WiX) exige estritamente versão numérica
            // no formato MAJOR.MINOR.BUILD (ex: 0.1.0). Versão vinda de uma única propriedade lagcheck.version.
            packageVersion = providers.gradleProperty("lagcheck.version").getOrElse("0.1.0")
            vendor = "LagCheck"
            description = "LagCheck — Medição determinística de qualidade de rota e conexão para jogos"

            windows {
                iconFile.set(project.file("src/main/resources/icon/lagcheck.ico"))
                menuGroup = "LagCheck"
                shortcut = true
                dirChooser = true
                perUserInstall = true
                upgradeUuid = "183beac0-1a84-41ea-ba52-5b046265bfd0"
            }
        }
    }
}

tasks.register<JavaExec>("runCli") {
    group = "application"
    classpath = sourceSets["main"].runtimeClasspath
    mainClass.set("com.lagcheck.desktop.MainKt")
    args("--cli")
}

tasks.register<JavaExec>("shots") {
    group = "application"
    classpath = sourceSets["main"].runtimeClasspath
    mainClass.set("com.lagcheck.desktop.MainKt")
    args("--shots", layout.buildDirectory.dir("shots").get().asFile.absolutePath)
}
