import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.compose.compiler)
}

android {
    namespace = "com.lagcheck.android"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.lagcheck.app"
        minSdk = 26
        targetSdk = 36
        // Versão do produto (MAJOR.MINOR.PATCH) e build crescente. Sobrescreva com
        // -Plagcheck.versionName=1.0.1 -Plagcheck.versionCode=2 (ver scripts/android-release.sh).
        versionCode = ((project.findProperty("lagcheck.versionCode") as String?) ?: "1").toInt()
        versionName = (project.findProperty("lagcheck.versionName") as String?) ?: "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Anúncios (MVP1.1, Decisão 82): LIGADOS por padrão (decisão do Luiz); desliga com -Plagcheck.adsEnabled=false.
        // Sem IDs reais, o app usa só os IDs de teste do Google (nunca gera tráfego real).
        val adsEnabled = (project.findProperty("lagcheck.adsEnabled") as String?) != "false"
        buildConfigField("boolean", "ADS_ENABLED", adsEnabled.toString())
        manifestPlaceholders["admobAppId"] =
            (project.findProperty("lagcheck.admobAppId") as String?) ?: "ca-app-pub-3940256099942544~3347511713"
        buildConfigField(
            "String", "ADMOB_BANNER_UNIT_ID",
            "\"" + ((project.findProperty("lagcheck.admobBannerUnitId") as String?) ?: "ca-app-pub-3940256099942544/9214589741") + "\""
        )
    }

    // Assinatura de release (chave de upload do Play App Signing). Fica FORA do repositório:
    // ~/Projetos/lagcheck-release/keys/lagcheck-upload.properties (ou -Plagcheck.signing.properties=<caminho>).
    // Sem o arquivo, o release sai sem assinatura (útil para CI e para quem não tem a chave).
    val signingProps = Properties()
    val signingFile = File(
        (project.findProperty("lagcheck.signing.properties") as String?)
            ?: "${System.getProperty("user.home")}/Projetos/lagcheck-release/keys/lagcheck-upload.properties"
    )
    val hasSigning = signingFile.exists().also { if (it) signingFile.inputStream().use(signingProps::load) }
    if (hasSigning) {
        signingConfigs {
            create("release") {
                storeFile = File(signingProps.getProperty("storeFile"))
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
        }
        debug {
            applicationIdSuffix = ".debug"
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

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.play.review)
    // AdMob + UMP (Decisão 82). Dormente enquanto ADS_ENABLED for falso.
    implementation(libs.play.services.ads)
    // QR Code do link da loja nos cards e no vídeo de compartilhamento (Apache-2.0, sem dependências).
    implementation(libs.zxing.core)
    debugImplementation(libs.androidx.compose.ui.tooling)

    testImplementation(libs.junit)
    testImplementation(libs.truth)
    testImplementation(libs.kotlinx.coroutines.test)
}
