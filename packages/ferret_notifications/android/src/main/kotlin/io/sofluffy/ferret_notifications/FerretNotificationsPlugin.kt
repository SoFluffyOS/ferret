package io.sofluffy.ferret_notifications

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretNotificationsPlugin */
class FerretNotificationsPlugin :
    FlutterPlugin,
    FerretNotificationsPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretNotificationsPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretNotificationsPluginApi.setUp(binding.binaryMessenger, null)
    }
}
