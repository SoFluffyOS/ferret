package io.sofluffy.ferret_calls

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Watches and controls the phone's calls for Dart. */
class FerretCallsPlugin :
    FlutterPlugin,
    ActivityAware,
    CallsHostApi,
    PluginRegistry.RequestPermissionsResultListener {
    private var context: Context? = null
    private var flutterApi: CallsFlutterApi? = null
    private var scope: CoroutineScope? = null
    private var monitor: CallMonitor? = null
    private var control: CallControl? = null
    private var contacts: ContactLookup? = null
    private var history: CallHistory? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingRequest: CompletableDeferred<Unit>? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val applicationContext = binding.applicationContext
        val contactLookup = ContactLookup(applicationContext)
        context = applicationContext
        flutterApi = CallsFlutterApi(binding.binaryMessenger)
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        control = CallControl(applicationContext)
        contacts = contactLookup
        history = CallHistory(applicationContext, contactLookup)
        monitor = CallMonitor(applicationContext, ::onPhoneEvent)
        CallsHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CallsHostApi.setUp(binding.binaryMessenger, null)
        monitor?.stop()
        control?.restoreRinger()
        scope?.cancel()
        pendingRequest?.complete(Unit)
        pendingRequest = null
        scope = null
        monitor = null
        control = null
        contacts = null
        history = null
        flutterApi = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attach(binding)

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        attach(binding)

    override fun onDetachedFromActivityForConfigChanges() = detach()

    override fun onDetachedFromActivity() = detach()

    override fun getPermissions(): PlatformCallPermissions =
        CallPermissions.read(requireContext(), activityBinding?.activity)

    override suspend fun requestPermissions(): PlatformCallPermissions {
        val context = requireContext()
        val activity: Activity? = activityBinding?.activity
        val missing = CallPermissions.missing(context)
        if (activity == null || missing.isEmpty()) {
            return CallPermissions.read(context, activity)
        }

        pendingRequest?.let { alreadyAsking ->
            alreadyAsking.await()
            return getPermissions()
        }

        val answered = CompletableDeferred<Unit>()
        pendingRequest = answered
        activity.requestPermissions(missing.toTypedArray(), REQUEST_CODE)
        answered.await()
        CallPermissions.markAsked(context)

        return getPermissions()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE) {
            return false
        }

        pendingRequest?.complete(Unit)
        pendingRequest = null
        return true
    }

    override fun openAppSettings() {
        val context = requireContext()
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        try {
            context.startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            throw FlutterError("unavailable", "This device has no App info page.")
        }
    }

    override fun startMonitoring(): Boolean = monitor?.start() == true

    override fun stopMonitoring() {
        monitor?.stop()
        control?.restoreRinger()
    }

    override fun answer(): PlatformCallResult = requireControl().answer()

    override fun end(): PlatformCallResult = requireControl().end()

    override fun silenceRinger(): PlatformCallResult = requireControl().silenceRinger()

    override fun dial(number: String): PlatformCallResult = requireControl().dial(number)

    override suspend fun recentCalls(limit: Long): List<PlatformCallLogEntry> {
        val callHistory = history ?: throw detached()
        val bounded = limit.coerceIn(0, MAX_LOG_ENTRIES).toInt()

        return withContext(Dispatchers.IO) { callHistory.recent(bounded) }
    }

    override suspend fun lookupContact(number: String): PlatformContact? {
        val contactLookup = contacts ?: throw detached()

        return withContext(Dispatchers.IO) { contactLookup.find(number, withPhoto = true) }
    }

    private fun onPhoneEvent(state: PlatformPhoneState, number: String?) {
        if (state != PlatformPhoneState.RINGING) {
            control?.restoreRinger()
        }

        val api = flutterApi ?: return
        scope?.launch { runCatching { api.onPhoneEvent(PlatformPhoneEvent(state, number)) } }
    }

    private fun attach(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    private fun detach() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        pendingRequest?.complete(Unit)
        pendingRequest = null
    }

    private fun requireContext(): Context = context ?: throw detached()

    private fun requireControl(): CallControl = control ?: throw detached()

    private fun detached() = FlutterError("detached", "The plugin is not attached to an engine.")

    private companion object {
        const val REQUEST_CODE = 0xCA11
        const val MAX_LOG_ENTRIES = 200L
    }
}
