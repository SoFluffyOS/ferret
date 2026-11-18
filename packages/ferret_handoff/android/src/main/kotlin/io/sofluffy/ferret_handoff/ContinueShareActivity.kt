package io.sofluffy.ferret_handoff

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.content.res.Configuration
import android.os.Bundle
import android.widget.Toast

/**
 * The "Continue on…" share target: picks a paired device in a small native
 * dialog, without starting Flutter, then hands the text to Ferret.
 */
class ContinueShareActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val text = intent.getStringExtra(Intent.EXTRA_TEXT)?.trim()
        if (intent.action != Intent.ACTION_SEND || text.isNullOrEmpty()) {
            Toast.makeText(this, R.string.ferret_handoff_nothing_to_send, Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        val item = SharedItem(
            origin = ShareOrigin.SHARE_SHEET,
            createdAtMs = System.currentTimeMillis(),
            text = text,
            subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)?.trim(),
            appPackage = referrer?.host,
        )
        val devices = HandoffStore(this).devices()

        when (devices.size) {
            0 -> showNoDevices()
            1 -> send(item, devices.first())
            else -> showChooser(item, devices)
        }
    }

    private fun send(item: SharedItem, device: HandoffDevice) {
        HandoffDelivery.deliver(this, item.copy(targetDeviceId = device.id), device.name)
        finish()
    }

    private fun showChooser(item: SharedItem, devices: List<HandoffDevice>) {
        AlertDialog.Builder(this, dialogTheme())
            .setTitle(R.string.ferret_handoff_choose_device)
            .setItems(devices.map { it.name }.toTypedArray()) { _, index ->
                send(item, devices[index])
            }
            .setNegativeButton(R.string.ferret_handoff_cancel, null)
            .setOnDismissListener { finish() }
            .show()
    }

    private fun showNoDevices() {
        AlertDialog.Builder(this, dialogTheme())
            .setMessage(R.string.ferret_handoff_no_devices)
            .setPositiveButton(R.string.ferret_handoff_open_app) { _, _ ->
                HandoffDelivery.openApp(this)
            }
            .setNegativeButton(R.string.ferret_handoff_cancel, null)
            .setOnDismissListener { finish() }
            .show()
    }

    private fun dialogTheme(): Int {
        val night = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        if (night == Configuration.UI_MODE_NIGHT_YES) {
            return android.R.style.Theme_DeviceDefault_Dialog_Alert
        }

        return android.R.style.Theme_DeviceDefault_Light_Dialog_Alert
    }
}
