allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Cada plugin (permission_handler_android, firebase_core, geolocator_android,
// etc.) trae su propio build.gradle adentro que también lee
// flutter.compileSdkVersion — fijar compileSdk solo en app/build.gradle.kts
// no les llega a ellos. Con este Flutter tan nuevo esa propiedad resuelve a
// la 37 (todavía en preview, rompe en CI: "No se pudo encontrar el objetivo
// con la cadena hash 'android-37'"), así que se lo forzamos a todos los
// módulos Android por igual.
subprojects {
    listOf("com.android.application", "com.android.library").forEach { id ->
        plugins.withId(id) {
            extensions.configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
