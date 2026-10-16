allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

// Force exact version 1.6.40 for com.razorpay:checkout to prevent dynamic metadata DNS lookup errors (1.6.+)
subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.razorpay" && requested.name == "checkout") {
                useVersion("1.6.40")
                because("Force fixed version 1.6.40 to prevent dynamic metadata DNS lookup errors and API mismatches")
            }
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
