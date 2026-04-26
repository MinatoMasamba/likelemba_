// android/build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}


subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // Correction spécifique pour Isar et les vieux packages
            if (android.namespace == null) {
                // Si c'est isar_flutter_libs, on lui donne son nom attendu
                if (project.name.contains("isar")) {
                    android.namespace = "dev.isar.isar_flutter_libs"
                } else {
                    android.namespace = "com.likelemba.${project.name.replace("-", "_")}"
                }
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory
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