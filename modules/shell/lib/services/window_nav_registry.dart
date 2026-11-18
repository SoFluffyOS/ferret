import 'package:feature_kit/feature_kit.dart';
import 'package:shell/models/models.dart';
import 'package:shell/view_models/window_nav_view_model.dart';

/// Every view's navigation, so something that happens outside a view (a
/// feature opening its page, the menubar's Settings) lands in the view the
/// person is looking at.
class WindowNavRegistry {
  WindowNavRegistry(this._featureContext) {
    _featureContext.onOpenSection = openSection;
  }

  final FeatureContext _featureContext;
  final List<WindowNavViewModel> _views = [];

  /// The navigation of the view in front, or null before any view shows.
  WindowNavViewModel? get active {
    final navigator = _featureContext.navigatorKey.currentState;
    for (final view in _views) {
      if (navigator != null && view.navigatorKey.currentState == navigator) {
        return view;
      }
    }

    return _views.firstOrNull;
  }

  void add(WindowNavViewModel view) => _views.add(view);

  void remove(WindowNavViewModel view) => _views.remove(view);

  void open(WindowDestination destination) => active?.open(destination);

  Future<void> openSection(String deviceId, String sectionId) async =>
      open(DeviceDestination(deviceId, sectionId: sectionId));
}
