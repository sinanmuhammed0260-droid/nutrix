// Gradle init script to handle build directory lock issues gracefully
import java.io.IOException

gradle.projectsLoaded {
    rootProject.allprojects {
        tasks.configureEach {
            doFirst {
                // Try to handle IOException for directory deletion
                if (this.name.contains("dexBuilder", ignoreCase = true) || 
                    this.name.contains("DexBuilder", ignoreCase = true)) {
                    try {
                        val outDir = file("${project.buildDir}/intermediates/project_dex_archive/debug/dexBuilderDebug/out")
                        if (outDir.exists()) {
                            try {
                                outDir.deleteRecursively()
                            } catch (e: IOException) {
                                logger.warn("Could not delete ${outDir.absolutePath}: ${e.message}")
                                logger.warn("This is usually harmless - continuing with incremental build...")
                                // Don't fail the build, just continue
                            }
                        }
                    } catch (e: Exception) {
                        logger.warn("Error in cleanup: ${e.message}")
                    }
                }
            }
        }
    }
}

// Override the clean task to be more tolerant
gradle.projectsLoaded {
    rootProject.allprojects {
        tasks.named("clean").configure {
            doLast {
                try {
                    // Clean operation
                } catch (e: IOException) {
                    if (e.message?.contains("Unable to delete directory") == true) {
                        logger.warn("Some directories could not be deleted (likely locked by IDE): ${e.message}")
                        logger.warn("This is usually harmless. Try closing your IDE and rebuilding.")
                    } else {
                        throw e
                    }
                }
            }
        }
    }
}
