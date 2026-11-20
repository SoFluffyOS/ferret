package io.sofluffy.ferret_system

import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log

/**
 * The "Send clipboard" Quick Settings tile. A tap sends the clipboard; a long press
 * opens the app (through the app activity that handles
 * `android.service.quicksettings.action.QS_TILE_PREFERENCES`).
 */
class FerretTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        refresh()
    }

    override fun onClick() {
        super.onClick()
        if (isLocked) {
            unlockAndRun { sendClipboard() }
            return
        }

        sendClipboard()
    }

    private fun sendClipboard() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(ClipboardActivity.pendingIntent(this, REQUEST_CLIPBOARD, "tile"))
            return
        }

        @Suppress("DEPRECATION", "StartActivityAndCollapseDeprecated")
        startActivityAndCollapse(ClipboardActivity.intent(this, "tile"))
    }

    private fun refresh() {
        val tile = qsTile ?: return
        val devices = FerretRuntime.connectedDevices
        val paused = FerretRuntime.pauseState(this).paused
        val running = FerretRuntime.isEngineRunning()

        tile.label = getString(R.string.ferret_system_tile_label)
        tile.state = when {
            paused || !running || devices.isEmpty() -> Tile.STATE_INACTIVE
            else -> Tile.STATE_ACTIVE
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = subtitle(paused, running, devices)
        }
        tile.updateTile()
    }

    private fun subtitle(paused: Boolean, running: Boolean, devices: List<String>): String = when {
        paused -> getString(R.string.ferret_system_tile_paused)
        !running || devices.isEmpty() -> getString(R.string.ferret_system_tile_not_connected)
        devices.size == 1 -> devices.first()
        else -> resources.getQuantityString(R.plurals.ferret_system_tile_devices, devices.size, devices.size)
    }

    companion object {
        private const val REQUEST_CLIPBOARD = 10
        private const val TAG = "FerretTileService"

        fun component(context: Context) = ComponentName(context, FerretTileService::class.java)

        fun requestRefresh(context: Context) {
            try {
                requestListeningState(context, component(context))
            } catch (error: RuntimeException) {
                Log.d(TAG, "Tile refresh skipped", error)
            }
        }
    }
}
