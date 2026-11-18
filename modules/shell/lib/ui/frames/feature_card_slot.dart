import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One feature's home card. Rebuilds when the feature says something changed,
/// and takes no space when the feature has nothing to show.
class FeatureCardSlot extends StatefulWidget {
  const FeatureCardSlot({
    super.key,
    required this.feature,
    required this.featureContext,
  });

  final FeatureUi feature;
  final FeatureContext featureContext;

  @override
  State<FeatureCardSlot> createState() => _FeatureCardSlotState();
}

class _FeatureCardSlotState extends State<FeatureCardSlot> {
  Listenable? _listening;

  @override
  void initState() {
    super.initState();
    _listen(widget.feature.uiChanges);
  }

  @override
  void didUpdateWidget(FeatureCardSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listen(widget.feature.uiChanges);
  }

  @override
  void dispose() {
    _listening?.removeListener(_onChanged);
    super.dispose();
  }

  void _listen(Listenable? listenable) {
    if (identical(listenable, _listening)) {
      return;
    }

    _listening?.removeListener(_onChanged);
    _listening = listenable;
    listenable?.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (!widget.feature.hasHomeCard(widget.featureContext)) {
      return const SizedBox.shrink();
    }

    final card = widget.feature.buildHomeCard(context, widget.featureContext);
    if (card == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: card,
    );
  }
}
