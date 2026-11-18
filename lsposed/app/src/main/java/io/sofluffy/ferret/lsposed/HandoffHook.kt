package io.sofluffy.ferret.lsposed

import android.app.Activity
import de.robv.android.xposed.IXposedHookLoadPackage
import de.robv.android.xposed.XC_MethodHook
import de.robv.android.xposed.XposedHelpers
import de.robv.android.xposed.callbacks.XC_LoadPackage.LoadPackageParam
import java.lang.ref.WeakReference

/**
 * SKELETON, not an implementation: never compiled, never run. It shows the
 * shape described in lsposed/DESIGN.md and nothing more.
 *
 * Inside each app the user ticked in LSPosed, this keeps track of the
 * activity in front. When Ferret asks, [HandoffRequestReceiver] calls the
 * activity's own `onProvideAssistContent` (and, from API 37,
 * `onHandoffActivityDataRequested`) and sends back the link it gets.
 */
class HandoffHook : IXposedHookLoadPackage {
    override fun handleLoadPackage(loaded: LoadPackageParam) {
        if (loaded.packageName in NEVER_HOOKED) {
            return
        }

        val trackFront = object : XC_MethodHook() {
            override fun afterHookedMethod(call: MethodHookParam) {
                runCatching { FrontActivity.set(call.thisObject as? Activity) }
            }
        }
        val forgetFront = object : XC_MethodHook() {
            override fun afterHookedMethod(call: MethodHookParam) {
                runCatching { FrontActivity.clear(call.thisObject as? Activity) }
            }
        }

        XposedHelpers.findAndHookMethod(Activity::class.java, "onResume", trackFront)
        XposedHelpers.findAndHookMethod(Activity::class.java, "onPause", forgetFront)

        // Not written yet, on purpose (see "Open questions" in DESIGN.md):
        //  - registering HandoffRequestReceiver in the hooked app, guarded by
        //    Ferret's signature permission;
        //  - calling the two callbacks on the main thread with a timeout;
        //  - returning only the web URI, the fallback URI and the label.
    }

    private companion object {
        /** The system itself and Ferret are never hooked, whatever the scope says. */
        val NEVER_HOOKED = setOf("android", "com.android.systemui", "io.sofluffy.ferret")
    }
}

/** The resumed activity of the app this code runs in, held weakly. */
internal object FrontActivity {
    @Volatile
    private var front: WeakReference<Activity>? = null

    fun set(activity: Activity?) {
        front = activity?.let(::WeakReference)
    }

    fun clear(activity: Activity?) {
        if (front?.get() === activity) {
            front = null
        }
    }

    fun get(): Activity? = front?.get()
}
