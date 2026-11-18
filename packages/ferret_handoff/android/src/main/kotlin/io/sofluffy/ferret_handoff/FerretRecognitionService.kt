package io.sofluffy.ferret_handoff

import android.content.Intent
import android.speech.RecognitionService
import android.speech.SpeechRecognizer

/** Required for an assistant to be listed; Ferret does no speech. */
class FerretRecognitionService : RecognitionService() {
    override fun onStartListening(recognizerIntent: Intent?, listener: Callback?) {
        listener?.error(SpeechRecognizer.ERROR_CLIENT)
    }

    override fun onCancel(listener: Callback?) {}

    override fun onStopListening(listener: Callback?) {}
}
