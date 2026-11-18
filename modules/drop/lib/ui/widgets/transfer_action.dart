import 'package:flutter/widgets.dart';

/// One button under a transfer, such as Open or Retry.
class TransferAction {
  const TransferAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
}
