import 'dart:async';

class OfflineSyncService {
  Timer? _t;

  void start() {
    _t?.cancel();
  }

  void stop() => _t?.cancel();
}
