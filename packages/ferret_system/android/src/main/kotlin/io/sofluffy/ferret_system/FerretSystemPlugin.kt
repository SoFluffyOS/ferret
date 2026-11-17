package io.sofluffy.ferret_system

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.engine.plugins.FlutterPlugin

class FerretSystemPlugin : FlutterPlugin, SystemHostApi {
    private var context: Context? = null
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        SystemHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SystemHostApi.setUp(binding.binaryMessenger, null)
        releaseMulticastLock()
        context = null
    }

    override fun acquireMulticastLock() {
        if (multicastLock?.isHeld == true) {
            return
        }

        val wifi = context?.applicationContext?.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return
        multicastLock = wifi.createMulticastLock("ferret-discovery").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    override fun releaseMulticastLock() {
        multicastLock?.takeIf { it.isHeld }?.release()
        multicastLock = null
    }

    override fun isMulticastLockHeld(): Boolean = multicastLock?.isHeld == true
}
