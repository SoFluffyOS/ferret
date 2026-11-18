/// Messaging apps. They come first in the app list when nothing else tells
/// them apart, and mark which saved picks were the old defaults.
abstract final class MessagingApps {
  static const packages = {
    'ch.threema.app',
    'chat.simplex.app',
    'com.discord',
    'com.facebook.mlite',
    'com.facebook.orca',
    'com.google.android.apps.dynamite',
    'com.google.android.apps.messaging',
    'com.kakao.talk',
    'com.microsoft.teams',
    'com.samsung.android.messaging',
    'com.skype.raider',
    'com.Slack',
    'com.tencent.mm',
    'com.viber.voip',
    'com.whatsapp',
    'com.whatsapp.w4b',
    'com.wire',
    'eu.siacs.conversations',
    'im.molly.app',
    'im.vector.app',
    'io.element.android.x',
    'jp.naver.line.android',
    'org.briarproject.briar.android',
    'org.telegram.messenger',
    'org.telegram.messenger.web',
    'org.thoughtcrime.securesms',
    'org.thunderdog.challegram',
  };

  static bool contains(String packageName) => packages.contains(packageName);
}
