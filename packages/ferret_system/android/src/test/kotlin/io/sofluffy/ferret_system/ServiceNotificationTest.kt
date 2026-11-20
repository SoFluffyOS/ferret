package io.sofluffy.ferret_system

import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class ServiceNotificationTest {
    @AfterTest
    fun reset() {
        ServiceNotification.hidden = false
    }

    @Test
    fun aShownNoticeFollowsEveryChange() {
        assertTrue(ServiceNotification.shouldPost(inForeground = true))
    }

    @Test
    fun aSwipedNoticeStaysAwayWhileTheServiceRuns() {
        ServiceNotification.hidden = true

        assertFalse(ServiceNotification.shouldPost(inForeground = true))
    }

    @Test
    fun theServiceStartingAfreshShowsItAgain() {
        ServiceNotification.hidden = true

        assertTrue(ServiceNotification.shouldPost(inForeground = false))
    }
}
