package io.sofluffy.ferret_messages

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class MessageRulesTest {
    @Test
    fun draftsAreLeftOut() {
        assertNull(MessageRules.smsKind(3))
        assertNull(MessageRules.mmsKind(3))
        assertEquals(PlatformMessageKind.QUEUED, MessageRules.smsKind(6))
        assertEquals(PlatformMessageKind.FAILED, MessageRules.mmsKind(5))
    }

    @Test
    fun mmsSecondsKeepTheWholeSecond() {
        assertEquals(1_700_000_000L, MessageRules.mmsSecondsAtOrBefore(1_700_000_000_999L))
        assertEquals(1_700_000_000_000L, MessageRules.mmsDateMs(1_700_000_000L))
    }

    @Test
    fun mmsRowIdsOnlyForMms() {
        assertEquals(7L, MessageRules.mmsRowId("mms:7"))
        assertNull(MessageRules.mmsRowId("sms:7"))
        assertNull(MessageRules.mmsRowId("mms:x"))
    }

    @Test
    fun pageMergesSkipsAndKeepsOrder() {
        val sms = listOf(MessageRules.Row("sms:3", 3000), MessageRules.Row("sms:2", 2000))
        val mms = listOf(MessageRules.Row("mms:9", 3000), MessageRules.Row("mms:8", 1000))

        val (page, hasMore) = MessageRules.page(sms, mms, setOf("sms:3"), 2)

        assertEquals(listOf("mms:9", "sms:2"), page.map { it.id })
        assertEquals(true, hasMore)
    }

    @Test
    fun recipientIdsIgnoreJunk() {
        assertEquals(listOf(3L, 7L), MessageRules.recipientIds(" 3  7 x"))
        assertEquals(emptyList(), MessageRules.recipientIds(null))
    }

    @Test
    fun snippetsAreShortAndOnOneLine() {
        assertEquals("a b", MessageRules.snippet(" a\n\nb "))
        assertEquals(10, MessageRules.snippet("x".repeat(50), max = 10).length)
    }

    @Test
    fun firstFailureWins() {
        val failures = listOf(PlatformSendFailure.NONE, PlatformSendFailure.NO_SERVICE, PlatformSendFailure.OTHER)

        assertEquals(PlatformSendFailure.NO_SERVICE, MessageRules.combine(failures))
        assertEquals(PlatformSendFailure.NONE, MessageRules.combine(listOf(PlatformSendFailure.NONE)))
    }

    @Test
    fun thumbnailsSampleDownToTheSide() {
        assertEquals(8, Thumbnails.sampleSize(4000, 3000, 320))
        assertEquals(1, Thumbnails.sampleSize(300, 200, 320))
    }
}
