import 'package:ferret_iphone/src/ancs/ancs_attribute.dart';
import 'package:ferret_iphone/src/ancs/ancs_date.dart';
import 'package:ferret_iphone/src/ancs/ancs_event.dart';

/// A notification on the iPhone with its text, as fetched for an [AncsEvent].
class AncsNotification {
  const AncsNotification({
    required this.event,
    this.appId = '',
    this.title = '',
    this.subtitle = '',
    this.message = '',
    this.date,
    this.positiveActionLabel = '',
    this.negativeActionLabel = '',
  });

  /// Builds it from the attributes of a Data Source answer, by id.
  factory AncsNotification.fromAttributes(
    AncsEvent event,
    Map<int, String> attributes,
  ) {
    String text(AncsAttribute attribute) => attributes[attribute.id] ?? '';

    return AncsNotification(
      event: event,
      appId: text(.appIdentifier),
      title: text(.title),
      subtitle: text(.subtitle),
      message: text(.message),
      date: parseAncsDate(text(.date)),
      positiveActionLabel: text(.positiveActionLabel),
      negativeActionLabel: text(.negativeActionLabel),
    );
  }

  final AncsEvent event;

  /// The app's bundle id, such as `com.apple.MobileSMS`.
  final String appId;
  final String title;
  final String subtitle;
  final String message;
  final DateTime? date;

  /// The iPhone's own words for the actions, such as "Answer" and "Clear".
  final String positiveActionLabel;
  final String negativeActionLabel;

  int get uid => event.uid;
}
