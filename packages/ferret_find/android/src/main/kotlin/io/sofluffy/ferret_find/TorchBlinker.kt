package io.sofluffy.ferret_find

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Handler

/** Blinks the back torch until [stop]. The camera itself is never opened. */
internal class TorchBlinker private constructor(
    private val manager: CameraManager,
    private val cameraId: String,
    private val handler: Handler,
) : Runnable {
    private var lit = false
    private var running = true

    override fun run() {
        if (!running) {
            return
        }

        lit = !lit
        runCatching { manager.setTorchMode(cameraId, lit) }
        handler.postDelayed(this, BLINK_MS)
    }

    fun stop() {
        running = false
        handler.removeCallbacks(this)
        runCatching { manager.setTorchMode(cameraId, false) }
    }

    companion object {
        private const val BLINK_MS = 400L

        fun hasTorch(context: Context): Boolean = torchCamera(context) != null

        fun start(context: Context, handler: Handler): TorchBlinker? {
            val manager = context.getSystemService(CameraManager::class.java) ?: return null
            val cameraId = torchCamera(context) ?: return null
            val blinker = TorchBlinker(manager, cameraId, handler)
            handler.post(blinker)
            return blinker
        }

        private fun torchCamera(context: Context): String? {
            val manager = context.getSystemService(CameraManager::class.java) ?: return null
            val ids = runCatching { manager.cameraIdList.toList() }.getOrDefault(emptyList())
            val withFlash = ids.filter { id ->
                runCatching {
                    manager.getCameraCharacteristics(id).get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
                }.getOrDefault(false)
            }
            val back = withFlash.firstOrNull { id ->
                runCatching {
                    manager.getCameraCharacteristics(id).get(CameraCharacteristics.LENS_FACING) ==
                        CameraCharacteristics.LENS_FACING_BACK
                }.getOrDefault(false)
            }
            return back ?: withFlash.firstOrNull()
        }
    }
}
