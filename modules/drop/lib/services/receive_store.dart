import 'dart:io';

import 'package:drop/models/models.dart';
import 'package:drop/services/receive_part.dart';

/// Where received files land. Ferret transfers write each file to a
/// [ReceivePart] from [partsFor] and save it from there once it verified.
/// LocalSend and Quick Share write a part file in [partsDirectory], then
/// [save] moves it in place.
abstract interface class ReceiveStore {
  /// A folder for files still arriving. Parts stay there across dropped
  /// sessions so transfers can resume.
  Future<Directory> partsDirectory();

  /// Claims a new folder called [name] (already made safe) in the receive
  /// folder for a folder that is arriving, and returns the name it got.
  /// It never reuses a folder that is there: `Photos` becomes
  /// `Photos (2)`, so nothing merges into what the person already has.
  Future<String> reserveFolder(String name);

  /// Moves a verified [part] to its final place as [name] (already made
  /// safe), never overwriting an existing file. [folder] is the path inside
  /// the receive folder, separated by `/`, whose first part came from
  /// [reserveFolder]. [modified] is kept where the platform allows.
  Future<ReceivedFile> save(
    File part, {
    required String name,
    required String mime,
    String? folder,
    DateTime? modified,
  });

  /// Where each file of Ferret transfer [id] is written while it arrives,
  /// one part per entry of [files], in order. Nothing is made on disk
  /// until a part is opened.
  Future<List<ReceivePart>> partsFor(String id, List<PartTarget> files);

  /// Bytes free where parts and saved files land, or null when that can't
  /// be told here. Offers that don't fit are turned down before anything
  /// is written.
  Future<int?> freeBytes();
}
