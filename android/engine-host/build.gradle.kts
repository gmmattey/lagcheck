plugins {
    alias(libs.plugins.kotlin.jvm)
    application
}

kotlin {
    compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) }
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

// O catálogo acompanha o binário. O host não baixa nem interpreta conteúdo remoto.
sourceSets {
    named("main") {
        resources.srcDir("../app/src/main/assets")
    }
}

application {
    mainClass.set("com.lagcheck.enginehost.MainKt")
}

dependencies {
    // Reuso deliberado: sessão, catálogo, UDP, carga e a biblioteca existente continuam Kotlin.
    implementation(project(":core:session"))
    implementation(project(":desktop"))
    // LibraryRepository expõe SnapshotStateList; o host lê somente seu conteúdo projetado.
    implementation("org.jetbrains.compose.runtime:runtime:1.7.0")
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.serialization.json)
    testImplementation(kotlin("test"))
}
