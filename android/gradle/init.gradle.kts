// Gradle init script to handle build directory lock issues
import java.io.IOException

gradle.projectsLoaded {
    rootProject.allprojects {
        tasks.configureEach {
            doFirst {
                if (this.name.contains("dexBuilder", ignoreCase = true)) {
                    val outDir = file("${project.buildDir}/intermediates/project_dex_archive/debug/dexBuilderDebug/out")
                    if (outDir.exists()) {
                        try {
                            // Try to delete, but don't fail if it's locked
                            val deleted = outDir.deleteRecursively()
                            if (!deleted) {
                                logger.warn("Could not delete ${outDir.absolutePath} - files may be locked")
                                logger.warn("This is usually harmless. The build will continue with existing files.")
                            }
                        } catch (e: IOException) {
                            logger.warn("IOException while deleting ${outDir.absolutePath}: ${e.message}")
                            logger.warn("Continuing build - this is usually harmless.")
                            // Don't rethrow - allow build to continue
                        } catch (e: Exception) {
                            logger.warn("Error cleaning directory: ${e.message}")
                            // Don't fail the build
                        }
                    }
                }
            }
        }
    }
}
