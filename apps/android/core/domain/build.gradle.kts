import org.jetbrains.kotlin.gradle.plugin.mpp.apple.XCFramework

plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    jvm {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    val xcf = XCFramework("LagCheckEngine")
    listOf(
        iosArm64(),
        iosSimulatorArm64()
    ).forEach { target ->
        target.binaries.framework {
            baseName = "LagCheckEngine"
            isStatic = true
            xcf.add(this)
        }
    }

    js(IR) {
        moduleName = "lagcheck-engine"
        browser()
        nodejs()
        binaries.library()
        generateTypeScriptDefinitions()
        useEsModules()
    }

    sourceSets {
        commonMain.dependencies {
            implementation(libs.kotlinx.serialization.json)
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
        }
        jvmTest.dependencies {
            implementation(libs.junit)
            implementation(libs.truth)
        }
    }
}

tasks.register("assembleXCFramework") {
    group = "build"
    description = "Assembles LagCheckEngine XCFramework for all configured targets"
    dependsOn("assembleLagCheckEngineXCFramework")
}
