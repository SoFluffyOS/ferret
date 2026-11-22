/// Ferret's updates: a daily check of GitHub's latest release (one switch
/// turns it off), and, only when asked, a download that is checked against
/// the release's SHA256SUMS and the platform's signature before it installs.
library;

export 'package:ferret_updates/ferret_updates.dart';
export 'package:updates/feature/feature.dart';
export 'package:updates/l10n/l10n.dart';
export 'package:updates/models/models.dart';
export 'package:updates/services/services.dart';
export 'package:updates/ui/ui.dart';
export 'package:updates/view_models/view_models.dart';
