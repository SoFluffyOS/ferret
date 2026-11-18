import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds [builder] whenever any of [features] reports a change, such as a
/// health chip turning green once the other device answers.
class FeatureChangesListener extends StatefulWidget {
  const FeatureChangesListener({
    super.key,
    required this.features,
    required this.builder,
  });

  final List<FeatureUi> features;
  final WidgetBuilder builder;

  @override
  State<FeatureChangesListener> createState() => _FeatureChangesListenerState();
}

class _FeatureChangesListenerState extends State<FeatureChangesListener> {
  late Listenable _merged;

  @override
  void initState() {
    super.initState();
    _merged = _merge(widget.features)..addListener(_onChanged);
  }

  @override
  void didUpdateWidget(FeatureChangesListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.features, widget.features)) {
      return;
    }

    _merged.removeListener(_onChanged);
    _merged = _merge(widget.features)..addListener(_onChanged);
  }

  @override
  void dispose() {
    _merged.removeListener(_onChanged);
    super.dispose();
  }

  Listenable _merge(List<FeatureUi> features) => Listenable.merge([
    for (final feature in features) ?feature.uiChanges,
  ]);

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
