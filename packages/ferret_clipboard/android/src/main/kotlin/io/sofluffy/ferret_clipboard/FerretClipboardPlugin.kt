package io.sofluffy.ferret_clipboard

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretClipboardPlugin */
class FerretClipboardPlugin :
    FlutterPlugin,
    FerretClipboardPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretClipboardPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretClipboardPluginApi.setUp(binding.binaryMessenger, null)
    }
}
