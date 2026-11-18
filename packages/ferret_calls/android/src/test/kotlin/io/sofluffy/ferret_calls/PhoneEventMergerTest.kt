package io.sofluffy.ferret_calls

import kotlin.test.Test
import kotlin.test.assertEquals

internal class PhoneEventMergerTest {
    private val events = ArrayList<Pair<PlatformPhoneState, String?>>()
    private val merger = PhoneEventMerger { state, number -> events.add(state to number) }

    @Test
    fun stateWithoutNumberThenNumber_emitsBoth() {
        merger.accept(PlatformPhoneState.RINGING, null)
        merger.accept(PlatformPhoneState.RINGING, "")
        merger.accept(PlatformPhoneState.RINGING, "+15550100")

        assertEquals(
            listOf<Pair<PlatformPhoneState, String?>>(
                PlatformPhoneState.RINGING to null,
                PlatformPhoneState.RINGING to "+15550100",
            ),
            events,
        )
    }

    @Test
    fun repeatsFromBothSources_areDropped() {
        merger.accept(PlatformPhoneState.RINGING, "+15550100")
        merger.accept(PlatformPhoneState.RINGING, null)
        merger.accept(PlatformPhoneState.OFF_HOOK, null)
        merger.accept(PlatformPhoneState.OFF_HOOK, "+15550100")
        merger.accept(PlatformPhoneState.IDLE, "+15550100")
        merger.accept(PlatformPhoneState.IDLE, null)

        assertEquals(
            listOf<Pair<PlatformPhoneState, String?>>(
                PlatformPhoneState.RINGING to "+15550100",
                PlatformPhoneState.OFF_HOOK to null,
                PlatformPhoneState.IDLE to null,
            ),
            events,
        )
    }

    @Test
    fun sameNumberCallingAgain_isReported() {
        merger.accept(PlatformPhoneState.RINGING, "+15550100")
        merger.accept(PlatformPhoneState.IDLE, null)
        merger.accept(PlatformPhoneState.RINGING, "+15550100")

        assertEquals(3, events.size)
        assertEquals(PlatformPhoneState.RINGING to "+15550100", events.last())
    }

    @Test
    fun photoSize_fitsTheLongestSide() {
        assertEquals(96 to 48, PhotoSize.fit(960, 480, 96))
        assertEquals(40 to 60, PhotoSize.fit(40, 60, 96))
        assertEquals(1 to 96, PhotoSize.fit(2, 4000, 96))
    }
}
