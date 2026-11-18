package io.sofluffy.ferret_messages

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.provider.Telephony
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

/** Reads, watches and sends SMS and MMS for Dart. Never logs message content. */
class FerretMessagesPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    MessagesHostApi {
    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var flutterApi: MessagesFlutterApi? = null
    private var scope: CoroutineScope? = null
    private var contacts: ContactLookup? = null
    private var reader: SmsReader? = null
    private var sender: SmsSender? = null
    private var watcher: ChangeWatcher? = null
    private var permissionResult: CompletableDeferred<Unit>? = null

    private val activity: Activity?
        get() = activityBinding?.activity

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val appContext = binding.applicationContext
        val lookup = ContactLookup(appContext) { isGranted(appContext, Manifest.permission.READ_CONTACTS) }
        val smsReader = SmsReader(appContext, lookup)
        context = appContext
        contacts = lookup
        reader = smsReader
        sender = SmsSender(appContext, smsReader)
        flutterApi = MessagesFlutterApi(binding.binaryMessenger)
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        watcher = ChangeWatcher(appContext) { deliverChanged() }
        MessagesHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MessagesHostApi.setUp(binding.binaryMessenger, null)
        watcher?.stop()
        watcher = null
        scope?.cancel()
        scope = null
        flutterApi = null
        sender = null
        reader = null
        contacts = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        permissionResult?.complete(Unit)
        permissionResult = null
    }

    override fun access(): PlatformAccess {
        val context = requireContext()
        val canRead = isGranted(context, Manifest.permission.READ_SMS)
        val asked = preferences(context).getBoolean(ASKED_KEY, false)
        val blocked = asked && !canRead && activity?.let {
            !it.shouldShowRequestPermissionRationale(Manifest.permission.READ_SMS)
        } == true

        return PlatformAccess(
            hasTelephony = hasTelephony(context),
            canRead = canRead,
            canSend = isGranted(context, Manifest.permission.SEND_SMS),
            canReadContacts = isGranted(context, Manifest.permission.READ_CONTACTS),
            blocked = blocked,
        )
    }

    override suspend fun requestAccess(): PlatformAccess {
        val current = activity
            ?: throw FlutterError("no_activity", "Permissions can only be asked while Ferret is open.")
        val pending = CompletableDeferred<Unit>()
        permissionResult?.complete(Unit)
        permissionResult = pending
        preferences(current).edit().putBoolean(ASKED_KEY, true).apply()
        current.requestPermissions(PERMISSIONS, REQUEST_CODE)
        pending.await()
        contacts?.clear()
        return access()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE) {
            return false
        }

        permissionResult?.complete(Unit)
        permissionResult = null
        return true
    }

    override fun openAppSettings(): Boolean {
        val context = activity ?: requireContext()
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        )
        if (context !is Activity) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        return try {
            context.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    override suspend fun listConversations(beforeDateMs: Long, limit: Long): PlatformConversationPage =
        io { requireReader().conversations(beforeDateMs, limit.toInt().coerceIn(1, MAX_PAGE)) }

    override suspend fun conversationsById(threadIds: List<Long>): List<PlatformConversation> =
        io { requireReader().conversationsById(threadIds.take(MAX_PAGE)) }

    override suspend fun listMessages(
        threadId: Long,
        beforeDateMs: Long,
        skipIds: List<String>,
        limit: Long,
    ): PlatformMessagePage = io {
        requireReader().messages(threadId, beforeDateMs, skipIds.toSet(), limit.toInt().coerceIn(1, MAX_PAGE))
    }

    override suspend fun recentMessages(sinceDateMs: Long, limit: Long): List<PlatformMessage> =
        io { requireReader().recent(sinceDateMs, limit.toInt().coerceIn(1, MAX_PAGE)) }

    override suspend fun fetchAttachment(messageId: String, partId: String): PlatformAttachmentData? =
        io { requireReader().attachment(messageId, partId) }

    override suspend fun send(threadId: Long, addresses: List<String>, text: String): PlatformSendResult {
        val context = requireContext()
        if (!isGranted(context, Manifest.permission.SEND_SMS)) {
            return PlatformSendResult(failure = PlatformSendFailure.NO_ACCESS, threadId = threadId)
        }

        val smsSender = sender ?: throw detached()
        return io { smsSender.send(threadId, addresses, text) }
    }

    override suspend fun markRead(threadId: Long): Boolean {
        val context = requireContext()
        if (Telephony.Sms.getDefaultSmsPackage(context) != context.packageName) {
            return false
        }

        return io {
            val values = ContentValues().apply {
                put(Telephony.Sms.READ, 1)
                put(Telephony.Sms.SEEN, 1)
            }
            val args = arrayOf(threadId.toString())
            val sms = context.contentResolver.update(
                Telephony.Sms.Inbox.CONTENT_URI,
                values,
                "${Telephony.Sms.THREAD_ID} = ? AND ${Telephony.Sms.READ} = 0",
                args,
            )
            val mms = context.contentResolver.update(
                Telephony.Mms.Inbox.CONTENT_URI,
                values,
                "${Telephony.Mms.THREAD_ID} = ? AND ${Telephony.Mms.READ} = 0",
                args,
            )
            sms + mms > 0
        }
    }

    override fun startWatching() {
        val context = requireContext()
        if (!isGranted(context, Manifest.permission.READ_SMS)) {
            throw FlutterError("no_access", "Ferret may not read SMS.")
        }

        watcher?.start()
    }

    override fun stopWatching() {
        watcher?.stop()
    }

    private fun deliverChanged() {
        val api = flutterApi ?: return
        scope?.launch { runCatching { api.onChanged() } }
    }

    private suspend fun <T> io(block: suspend () -> T): T {
        val context = requireContext()
        if (!isGranted(context, Manifest.permission.READ_SMS)) {
            throw FlutterError("no_access", "Ferret may not read SMS.")
        }

        return withContext(Dispatchers.IO) {
            try {
                block()
            } catch (error: SecurityException) {
                throw FlutterError("no_access", error.message)
            }
        }
    }

    private fun requireContext(): Context = context ?: throw detached()

    private fun requireReader(): SmsReader = reader ?: throw detached()

    private fun detached() = FlutterError("detached", "The plugin is not attached to an engine.")

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    private fun isGranted(context: Context, permission: String): Boolean =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun hasTelephony(context: Context): Boolean {
        val feature = when (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            true -> PackageManager.FEATURE_TELEPHONY_MESSAGING
            false -> PackageManager.FEATURE_TELEPHONY
        }
        return context.packageManager.hasSystemFeature(feature)
    }

    private companion object {
        const val REQUEST_CODE = 47651
        const val MAX_PAGE = 200
        const val PREFERENCES = "ferret_messages"
        const val ASKED_KEY = "asked_access"
        val PERMISSIONS = arrayOf(
            Manifest.permission.READ_SMS,
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.SEND_SMS,
            Manifest.permission.READ_CONTACTS,
        )
    }
}
