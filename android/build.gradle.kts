allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Force all subprojects (including Flutter plugins) to use the same
    // Android Gradle Plugin version as the host project, avoiding
    // redundant network downloads of older AGP versions.
    configurations.configureEach {
        resolutionStrategy {
            force("com.android.tools.build:gradle:8.11.1")
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
