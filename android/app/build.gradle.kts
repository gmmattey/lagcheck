import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.google.services)
}

android {
    namespace = "com.lagcheck.android"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.lagcheck.app"
        minSdk = 26
        targetSdk = 36
        // Versão do produto (MAJOR.MINOR) e build crescente. Sobrescreva com
        // -Plagcheck.versionName=1.0 -Plagcheck.versionCode=2 (ver scripts/android-release.sh).
        versionCode = ((project.findProperty("lagcheck.versionCode") as String?) ?: "1").toInt()
        versionName = (project.findProperty("lagcheck.versionName") as String?) ?: "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Anúncios nativos (Decisão 94): desliga com -Plagcheck.adsEnabled=false.
        // Sem IDs reais, o app usa só os IDs de teste do Google (nunca gera tráfego real).
        val adsEnabled = (project.findProperty("lagcheck.adsEnabled") as String?) != "false"
        buildConfigField("boolean", "ADS_ENABLED", adsEnabled.toString())
        manifestPlaceholders["admobAppId"] =
            (project.findProperty("lagcheck.admobAppId") as String?) ?: "ca-app-pub-3940256099942544~3347511713"
        val testNativeUnitId = "ca-app-pub-3940256099942544/2247696110"
        listOf("Home", "History", "Games", "Result").forEach { placement ->
            val propertyName = "lagcheck.admobNative${placement}UnitId"
            val unitId = (project.findProperty(propertyName) as String?) ?: testNativeUnitId
            buildConfigField("String", "ADMOB_NATIVE_${placement.uppercase()}_UNIT_ID", "\"$unitId\"")
        }
    }

    // O Play Console não informa ao SDK se um install veio de teste fechado ou
    // de produção. O ambiente nasce no AAB para o GA4 nunca precisar adivinhar.
    flavorDimensions += "distribution"
    productFlavors {
        // "test" é prefixo reservado do Android Gradle Plugin; este variant
        // gera o AAB de testes e informa `testing` ao GA4.
        create("validation") {
            dimension = "distribution"
            buildConfigField("String", "ANALYTICS_ENVIRONMENT", "\"testing\"")
        }
        create("production") {
            dimension = "distribution"
            buildConfigField("String", "ANALYTICS_ENVIRONMENT", "\"production\"")
        }
    }

    // Assinatura de release (chave de upload do Play App Signing).
    // Procura em release/keys/lagcheck-upload.properties (ou -Plagcheck.signing.properties=<caminho>).
    // Sem o arquivo, o release sai sem assinatura (útil para CI e para quem não tem a chave).
    val signingProps = Properties()
    val localSigningFile = rootProject.file("../release/keys/lagcheck-upload.properties")
    val legacySigningFile = File("${System.getProperty("user.home")}/Projetos/lagcheck-release/keys/lagcheck-upload.properties")
    val customSigningPath = project.findProperty("lagcheck.signing.properties") as String?
    val signingFile = when {
        customSigningPath != null -> File(customSigningPath)
        localSigningFile.exists() -> localSigningFile
        else -> legacySigningFile
    }
    val hasSigning = signingFile.exists().also { if (it) signingFile.inputStream().use(signingProps::load) }
    if (hasSigning) {
        signingConfigs {
            create("release") {
                val rawStoreFile = signingProps.getProperty("storeFile") ?: "lagcheck-upload.jks"
                val resolvedStoreFile = if (File(rawStoreFile).isAbsolute) File(rawStoreFile) else signingFile.parentFile.resolve(rawStoreFile)
                storeFile = resolvedStoreFile
                storePassword = signingProps.getProperty("storePassword")
                keyAlias = signingProps.getProperty("keyAlias")
                keyPassword = signingProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasSigning) signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            buildConfigField("boolean", "FIREBASE_ANALYTICS_ENABLED", "true")
        }
        debug {
            applicationIdSuffix = ".debug"
            // O projeto Firebase só cadastra o applicationId de release. Mantemos
            // o Debug independente: ele compila, instala e nunca coleta Analytics.
            buildConfigField("boolean", "FIREBASE_ANALYTICS_ENABLED", "false")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
        // O AdMob 25.x traz metadados de Kotlin mais novos que o 2.0.20 do projeto (só nos módulos internos
        // do SDK, que o app não usa em Kotlin). Remover quando o Kotlin do projeto subir.
        freeCompilerArgs += "-Xskip-metadata-version-check"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    implementation(project(":core:domain"))
    implementation(project(":core:network"))
    implementation(project(":core:catalog"))
    implementation(project(":core:session"))
    implementation(project(":core:telemetry-radio"))
    implementation(project(":core:designsystem"))

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)
    // registerForActivityResult requires Fragment 1.3.0+; transient dependencies resolve 1.1.0.
    implementation(libs.androidx.fragment)

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.play.review)
    // AdMob + UMP (Decisão 82). Dormente enquanto ADS_ENABLED for falso.
    implementation(libs.play.services.ads)
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.analytics)
    // QR Code do link da loja nos cards e no vídeo de compartilhamento (Apache-2.0, sem dependências).
    implementation(libs.zxing.core)
    debugImplementation(libs.androidx.compose.ui.tooling)

    testImplementation(libs.junit)
    testImplementation(libs.truth)
    testImplementation(libs.kotlinx.coroutines.test)
}

// `google-services.json` existe apenas em src/release porque o Firebase não
// cadastra com.lagcheck.app.debug. Desabilitar estas tarefas preserva builds Debug
// sem fingir que o pacote de desenvolvimento é o aplicativo de produção.
tasks.matching { it.name.endsWith("DebugGoogleServices") }.configureEach {
    enabled = false
}
