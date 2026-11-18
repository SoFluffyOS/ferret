package io.sofluffy.ferret_handoff

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * What the native chooser needs while Flutter may not be running: the paired
 * devices (names come from Dart) and items waiting to be sent.
 */
internal class HandoffStore(context: Context) {
    private val preferences =
        context.applicationContext.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun devices(): List<HandoffDevice> {
        val array = parse(preferences.getString(KEY_DEVICES, null))
        return (0 until array.length()).mapNotNull { index ->
            val device = array.optJSONObject(index) ?: return@mapNotNull null
            val id = device.optString("id")
            if (id.isEmpty()) {
                return@mapNotNull null
            }

            HandoffDevice(id = id, name = device.optString("name", id))
        }
    }

    fun setDevices(devices: List<HandoffDevice>) {
        val array = JSONArray()
        for (device in devices) {
            array.put(JSONObject().put("id", device.id).put("name", device.name))
        }

        preferences.edit().putString(KEY_DEVICES, array.toString()).apply()
    }

    @Synchronized
    fun addPending(item: SharedItem) {
        val array = parse(preferences.getString(KEY_PENDING, null))
        array.put(SharedItemJson.encode(item))
        while (array.length() > MAX_PENDING) {
            array.remove(0)
        }

        preferences.edit().putString(KEY_PENDING, array.toString()).commit()
    }

    @Synchronized
    fun takePending(): List<SharedItem> {
        val array = parse(preferences.getString(KEY_PENDING, null))
        preferences.edit().remove(KEY_PENDING).commit()
        return (0 until array.length()).mapNotNull { index ->
            array.optJSONObject(index)?.let(SharedItemJson::decode)
        }
    }

    private fun parse(raw: String?): JSONArray {
        if (raw == null) {
            return JSONArray()
        }

        return try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }
    }

    private companion object {
        const val PREFERENCES = "io.sofluffy.ferret_handoff"
        const val KEY_DEVICES = "devices"
        const val KEY_PENDING = "pending"
        const val MAX_PENDING = 10
    }
}

internal object SharedItemJson {
    fun encode(item: SharedItem): JSONObject = JSONObject()
        .put("origin", item.origin.raw)
        .put("createdAtMs", item.createdAtMs)
        .putOpt("targetDeviceId", item.targetDeviceId)
        .putOpt("text", item.text)
        .putOpt("subject", item.subject)
        .putOpt("webUri", item.webUri)
        .putOpt("deepLink", item.deepLink)
        .putOpt("appPackage", item.appPackage)
        .putOpt("appName", item.appName)
        .putOpt("structuredData", item.structuredData)
        .putOpt("title", item.title)

    fun decode(json: JSONObject): SharedItem = SharedItem(
        origin = ShareOrigin.ofRaw(json.optInt("origin")) ?: ShareOrigin.SHARE_SHEET,
        createdAtMs = json.optLong("createdAtMs", System.currentTimeMillis()),
        targetDeviceId = json.stringOrNull("targetDeviceId"),
        text = json.stringOrNull("text"),
        subject = json.stringOrNull("subject"),
        webUri = json.stringOrNull("webUri"),
        deepLink = json.stringOrNull("deepLink"),
        appPackage = json.stringOrNull("appPackage"),
        appName = json.stringOrNull("appName"),
        structuredData = json.stringOrNull("structuredData"),
        title = json.stringOrNull("title"),
    )

    private fun JSONObject.stringOrNull(key: String): String? {
        if (!has(key) || isNull(key)) {
            return null
        }

        return optString(key)
    }
}
