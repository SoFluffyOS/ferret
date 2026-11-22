package io.sofluffy.ferret_notifications

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class ConversationRankingTest {
    @Test
    fun android11DoesNotAskTheRanking() {
        assertFalse(NotificationReader.asksRankingForConversation(28))
        assertFalse(NotificationReader.asksRankingForConversation(30))
    }

    @Test
    fun android12AndLaterAsk() {
        assertTrue(NotificationReader.asksRankingForConversation(31))
        assertTrue(NotificationReader.asksRankingForConversation(36))
    }
}
