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
    }
}

dependencies {
    // Mesmo núcleo do Android: regra, catálogo, UDP e sessão. Nada de regra duplicada aqui.
    implementation(project(":core:session"))
    implementation(compose.desktop.currentOs)
    implementation(compose.material3)
    implementation(libs.kotlinx.coroutines.core)
}

compose.desktop {
    application {
        mainClass = "com.lagcheck.desktop.MainKt"
        nativeDistributions {
            targetFormats(TargetFormat.Msi, TargetFormat.Exe)
            packageName = "LagCheck"
            packageVersion = "1.0.0"
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
