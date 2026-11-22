/// The phone's own texting and calling apps, whose notifications tell the
/// same news as Ferret's Messages and Calls.
abstract final class PhoneApps {
  /// Apps that show SMS and MMS, besides the chat apps in `MessagingApps`.
  static const texting = {
    'com.android.messaging',
    'com.android.mms',
    'com.google.android.apps.messaging',
    'com.oneplus.mms',
    'com.samsung.android.messaging',
    'com.textra',
  };

  /// Phone apps that post "Missed call".
  static const calling = {
    'com.android.dialer',
    'com.android.incallui',
    'com.android.server.telecom',
    'com.google.android.dialer',
    'com.oneplus.dialer',
    'com.samsung.android.dialer',
    'com.samsung.android.incallui',
  };
}
