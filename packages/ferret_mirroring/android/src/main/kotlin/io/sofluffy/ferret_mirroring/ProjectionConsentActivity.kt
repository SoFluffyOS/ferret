package io.sofluffy.ferret_mirroring

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle

/**
 * An invisible activity that shows Android's screen capture prompt. A yes
 * starts the foreground service right here, while this activity is still in
 * front, as Android asks for a mediaProjection service.
 */
class ProjectionConsentActivity : Activity() {
    private var answered = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!ProjectionConsent.isPending) {
            answered = true
            finish()
            return
        }

        ProjectionConsent.attach(this)
        if (savedInstanceState != null) {
            return
        }

        val manager = getSystemService(MediaProjectionManager::class.java)
        if (manager == null) {
            answer(NativeConsentResult.FAILED)
            return
        }

        @Suppress("DEPRECATION")
        startActivityForResult(manager.createScreenCaptureIntent(), REQUEST_CAPTURE)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_CAPTURE || answered) {
            return
        }

        val texts = ProjectionConsent.texts
        if (resultCode != RESULT_OK || data == null || texts == null) {
            answer(NativeConsentResult.DENIED)
            return
        }

        answered = true
        if (!MirrorService.arm(this, resultCode, data, texts)) {
            ProjectionConsent.complete(this, NativeConsentResult.FAILED)
        }

        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isFinishing && !answered) {
            ProjectionConsent.complete(applicationContext, NativeConsentResult.DENIED)
        }
    }

    /** Takes the prompt away when the request was answered or expired elsewhere. */
    fun close() {
        if (isFinishing) {
            return
        }

        answered = true
        @Suppress("DEPRECATION")
        finishActivity(REQUEST_CAPTURE)
        finish()
    }

    @Suppress("DEPRECATION")
    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }

    private fun answer(result: NativeConsentResult) {
        answered = true
        ProjectionConsent.complete(this, result)
        finish()
    }

    companion object {
        private const val REQUEST_CAPTURE = 1

        fun intent(context: Context): Intent =
            Intent(context, ProjectionConsentActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION)
    }
}
