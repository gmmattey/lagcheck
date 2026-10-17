plugins {
    alias(libs.plugins.kotlin.jvm)
}

kotlin {
    compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) }
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

dependencies {
    api(project(":core:domain"))
    api(project(":core:catalog"))
    api(project(":core:network"))
    implementation(libs.kotlinx.coroutines.core)

    testImplementation(libs.kotlinx.serialization.json)
    testImplementation(libs.junit)
    testImplementation(libs.truth)
    testImplementation(libs.kotlinx.coroutines.test)
}
