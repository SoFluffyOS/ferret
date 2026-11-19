package io.sofluffy.ferret_camera

import androidx.core.content.FileProvider

/** Ferret's own provider class, so it never clashes with another plugin's
 * FileProvider entry in the merged manifest. */
class CameraFileProvider : FileProvider()
