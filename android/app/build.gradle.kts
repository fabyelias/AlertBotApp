import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase: procesa google-services.json (ver README, pendiente #1).
    id("com.google.gms.google-services")
}

// Clave de release: nunca hardcodeada acá, sale de Codemagic (panel
// Distribution → Android code signing), de dos formas posibles según
// cómo la exponga — probamos las dos, ninguna pisa a la otra:
// 1) Variables de entorno CM_KEYSTORE_PATH/CM_KEYSTORE_PASSWORD/
//    CM_KEY_ALIAS/CM_KEY_PASSWORD, ya en el ambiente del build.
// 2) android/key.properties (NO se versiona, ver .gitignore), armado
//    solo por Codemagic con esos mismos cuatro datos.
// Si no está ninguna (local, o todavía no la configuraste), cae a la
// clave de debug — ver signingConfigs y buildTypes más abajo.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun datoDeRelease(envVar: String, propKey: String): String? =
    System.getenv(envVar) ?: keystoreProperties.getProperty(propKey)

val releaseStoreFile = datoDeRelease("CM_KEYSTORE_PATH", "storeFile")
val releaseStorePassword = datoDeRelease("CM_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = datoDeRelease("CM_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = datoDeRelease("CM_KEY_PASSWORD", "keyPassword")
val hayClaveDeRelease = releaseStoreFile != null && releaseStorePassword != null &&
    releaseKeyAlias != null && releaseKeyPassword != null

android {
    namespace = "com.example.alertbot_app"
    // Fijo en vez de flutter.compileSdkVersion: con el Flutter tan nuevo que
    // instalamos, ese valor resuelve a la 37, todavía en preview — Codemagic
    // "la instala" pero Gradle no encuentra el target ("No se pudo encontrar
    // el objetivo con la cadena hash 'android-37'"). La 36 es la última
    // estable de verdad.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications (sonidos de alerta) lo pide — sin esto
        // Gradle rechaza el build ("requires core library desugaring").
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        // Fija (debug.keystore, en este mismo directorio) en vez de la que
        // Gradle arma sola en $HOME/.android/debug.keystore: en una máquina
        // de build efímera como la de Codemagic, esa carpeta no existe al
        // empezar, así que se genera una clave AL AZAR en cada build — cada
        // APK queda firmado distinto, y Android se niega a instalarlo encima
        // del anterior ("App not installed") a menos que se desinstale la
        // app entera antes de cada prueba. Con esta clave fija, todos los
        // builds quedan firmados igual y el instalador actualiza sin drama.
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        // Solo se crea si Codemagic mandó la clave de release de verdad
        // (ver arriba) — nunca la de debug, ni nada hardcodeado acá, a
        // diferencia de la de arriba (que sí es pública a propósito, ver
        // el comentario de esa).
        if (hayClaveDeRelease) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.alertbot_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Fijo en 24 (Android 7.0): flutter_local_notifications (sonidos de
        // alerta) pide esa mínima desde su v21 — bien por debajo de
        // cualquier celular real que use el barrio.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = 36 // ídem compileSdk, ver comentario arriba
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Con la clave de release configurada en Codemagic, la usa
            // (obligatorio para subir a Play Store). Si todavía no la
            // configuraste, cae a la de debug, para no romper builds de
            // prueba mientras tanto.
            signingConfig = if (hayClaveDeRelease) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Versión de la librería que pide isCoreLibraryDesugaringEnabled, arriba.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
