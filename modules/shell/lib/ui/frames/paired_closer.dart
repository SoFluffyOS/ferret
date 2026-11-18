import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/view_models/view_models.dart';

/// Goes back to Home shortly after [viewModel] pairs a device, so the new
/// device is what the person sees next. Long enough to read "Paired with
/// Pixel 9" first.
class PairedCloser extends StatefulWidget {
  const PairedCloser({super.key, required this.viewModel, required this.child});

  final PairingViewModel viewModel;
  final Widget child;

  @override
  State<PairedCloser> createState() => _PairedCloserState();
}

class _PairedCloserState extends State<PairedCloser> {
  static const _readingTime = Duration(milliseconds: 1500);

  Timer? _closing;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onChanged);
    _closing?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _onChanged() {
    final state = widget.viewModel.state;
    if (_closing != null || state is! PairingDone || state.outcome is! Paired) {
      return;
    }

    _closing = Timer(_readingTime, _close);
  }

  void _close() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
