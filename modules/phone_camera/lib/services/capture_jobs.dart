import 'dart:async';

import 'package:phone_camera/models/models.dart';

/// A computer's requests for pictures, newest first, for Activity. Keeps
/// the last [keep] finished ones.
class CaptureJobs {
  CaptureJobs({this.keep = 8});

  final int keep;
  final List<CaptureJob> _jobs = [];
  final StreamController<void> _changes = .broadcast();

  List<CaptureJob> get all => List.unmodifiable(_jobs);

  Stream<void> get changes => _changes.stream;

  CaptureJob? operator [](String id) {
    for (final job in _jobs) {
      if (job.id == id) {
        return job;
      }
    }

    return null;
  }

  /// The requests to [deviceId] still waiting or arriving.
  List<CaptureJob> openFor(String deviceId) => [
    for (final job in _jobs)
      if (job.deviceId == deviceId && job.status.isOpen) job,
  ];

  void add(CaptureJob job) {
    _jobs.insert(0, job);
    _trim();
    _notify();
  }

  void update(String id, CaptureJob Function(CaptureJob job) change) {
    final index = _jobs.indexWhere((job) => job.id == id);
    if (index < 0) {
      return;
    }

    _jobs[index] = change(_jobs[index]);
    _trim();
    _notify();
  }

  void remove(String id) {
    _jobs.removeWhere((job) => job.id == id);
    _notify();
  }

  void _notify() {
    if (_changes.isClosed) {
      return;
    }

    _changes.add(null);
  }

  void _trim() {
    final finished = _jobs.where((job) => !job.status.isOpen).toList();
    if (finished.length <= keep) {
      return;
    }

    for (final old in finished.skip(keep)) {
      _jobs.remove(old);
    }
  }

  Future<void> dispose() => _changes.close();
}
