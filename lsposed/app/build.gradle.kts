// Skeleton only: this module is not included in any Gradle build and has
// never been compiled. See ../DESIGN.md.
plugins {
    id("com.android.application")
}

android {
    namespace = "io.sofluffy.ferret.lsposed"
    compileSdk = 37

    defaultConfig {
        applicationId = "io.sofluffy.ferret.lsposed"
        minSdk = 27
        targetSdk = 37
        versionCode = 1
        versionName = "0.0.1-skeleton"
    }
}

dependencies {
    // The legacy Xposed API, provided by the LSPosed framework at runtime.
    compileOnly("de.robv.android.xposed:api:82")
}
