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

subprojects {
    if (name != "flutter_inappwebview_android") return@subprojects
    afterEvaluate {
        val origJava = file("src/main/java")
        val activityFile = origJava.resolve(
            "com/pichillilorenzo/flutter_inappwebview_android/in_app_browser/InAppBrowserActivity.java",
        )
        if (!activityFile.exists()) return@afterEvaluate

        val patchedJava = layout.buildDirectory.dir("patchedInAppWebViewJava").get().asFile
        val patchTask = tasks.register("patchInAppWebViewEdgeToEdge") {
            inputs.dir(origJava)
            outputs.dir(patchedJava)
            doLast {
                patchedJava.deleteRecursively()
                origJava.copyRecursively(patchedJava)
                val dest = patchedJava.resolve(
                    "com/pichillilorenzo/flutter_inappwebview_android/in_app_browser/InAppBrowserActivity.java",
                )
                dest.writeText(
                    dest.readText().replace(
                        Regex(
                            """\r?\n[ \t]*if \(Build\.VERSION\.SDK_INT >= Build\.VERSION_CODES\.LOLLIPOP\) \{\r?\n[ \t]*getWindow\(\)\.setStatusBarColor\(Color\.TRANSPARENT\);\r?\n[ \t]*\}""",
                        ),
                        "",
                    ),
                )
            }
        }

        val androidExt = extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
        androidExt?.sourceSets?.getByName("main")?.java?.setSrcDirs(listOf(patchedJava))
        tasks.named("preBuild").configure { dependsOn(patchTask) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
