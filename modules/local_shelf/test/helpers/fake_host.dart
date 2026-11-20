import 'package:core/core.dart';
import 'package:engine/engine.dart';

/// Just the settings of the engine, which is all the shelf asks for.
class FakeHost implements FeatureHost {
  @override
  final MemorySettingsStore settings = MemorySettingsStore();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
