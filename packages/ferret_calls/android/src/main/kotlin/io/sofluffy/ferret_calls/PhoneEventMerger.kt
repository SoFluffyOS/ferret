package io.sofluffy.ferret_calls

/**
 * Turns the two overlapping sources of call state into one stream: an event
 * goes out when the state changes, or when the number of the current state
 * becomes known. Repeats are dropped.
 */
internal class PhoneEventMerger(private val onEvent: (PlatformPhoneState, String?) -> Unit) {
    private var lastState: PlatformPhoneState? = null
    private var lastNumber: String? = null

    fun reset() {
        lastState = null
        lastNumber = null
    }

    fun accept(state: PlatformPhoneState, number: String?) {
        if (state == PlatformPhoneState.IDLE) {
            lastNumber = null
            if (lastState == PlatformPhoneState.IDLE) {
                return
            }

            lastState = state
            onEvent(state, null)
            return
        }

        val known = number?.takeIf { it.isNotBlank() }
        val stateChanged = state != lastState
        val numberLearned = known != null && known != lastNumber
        if (!stateChanged && !numberLearned) {
            return
        }

        lastState = state
        if (known != null) {
            lastNumber = known
        }
        onEvent(state, known)
    }
}
