plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "dev.cadence.app"
    compileSdk = 35
    defaultConfig {
        applicationId = "dev.cadence.app"
        minSdk = 28
        targetSdk = 35
        versionCode = 1
        versionName = "0.1"
        val baseUrl = providers.gradleProperty("cadenceBaseUrl").getOrElse("http://10.0.2.2:3000")
        require(baseUrl.startsWith("https://") || baseUrl.startsWith("http://10.0.2.2:")) { "Use HTTPS for a real device" }
        buildConfigField("String", "BASE_URL", "\"${baseUrl.replace("\"", "\\\"")}\"")
    }
    buildFeatures { buildConfig = true }
    packaging { resources.excludes += "META-INF/versions/9/OSGI-INF/MANIFEST.MF" }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin { compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) } }

dependencies {
    implementation("dev.hotwire:core:1.3.2")
    implementation("dev.hotwire:navigation-fragments:1.3.2")
    implementation("androidx.appcompat:appcompat:1.7.1")
}
