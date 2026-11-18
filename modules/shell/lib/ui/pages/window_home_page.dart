import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/pages/destination_page.dart';
import 'package:shell/ui/pages/home_page.dart';
import 'package:shell/view_models/view_models.dart';

/// The first page of a view, by its width: Home where there is one column
/// (a phone, the popover), and what the device list has selected where
/// there is a list. Pages opened on top stay when a resize swaps the two.
class WindowHomePage extends StatelessWidget {
  const WindowHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!WindowLayout.splits(context)) {
      return const HomePage();
    }

    final selection = context.select<WindowNavViewModel, WindowDestination?>(
      (viewModel) => viewModel.selection,
    );
    if (selection == null) {
      return const HomePage();
    }

    return DestinationPage(destination: selection);
  }
}
