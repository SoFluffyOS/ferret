package io.sofluffy.ferret_drop

/** Where in Downloads a received file goes, and a name there nobody uses. */
internal object DownloadNames {
    /** `Download/<folder>/`, the form MediaStore's RELATIVE_PATH takes. */
    fun relativePath(downloads: String, folder: String): String = "$downloads/${folder.trim('/')}/"

    /** [wanted], or `name (1).ext`, `name (2).ext`… when [taken] says so. */
    fun free(wanted: String, taken: (String) -> Boolean): String {
        val dot = wanted.lastIndexOf('.').takeIf { it > 0 } ?: wanted.length
        val stem = wanted.substring(0, dot)
        val extension = wanted.substring(dot)
        var candidate = wanted
        var counter = 1
        while (taken(candidate)) {
            candidate = "$stem ($counter)$extension"
            counter++
        }

        return candidate
    }
}
