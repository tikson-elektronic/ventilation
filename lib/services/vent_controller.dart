import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models.dart';
import 'vent_client.dart';

/// Connection health from the *remote app's* point of view (distinct from the
/// panel↔controller serial [LinkState]). "offline" = the app can't reach the
/// panel over HTTP at all.
enum Reachability { connecting, online, offline }

/// Owns the connection to one panel: polls `/api/status` ~1 Hz, exposes the
/// latest snapshot, and issues control commands with optimistic local echo so
/// the slider/toggles feel instant while the poll reconciles.
class VentController extends ChangeNotifier {
  VentController({required this.panel, VentClient? client})
      : client = client ?? VentClient(panel.apiBase);

  final PanelInfo panel;
  final VentClient client;

  VentStatus? _status;
  VentStatus? get status => _status;

  Reachability _reachability = Reachability.connecting;
  Reachability get reachability => _reachability;

  String? _lastError;
  String? get lastError => _lastError;

  Timer? _pollTimer;
  bool _busy = false;
  int _consecutiveFailures = 0;

  /// Optimistic setpoint overrides while a slider is being dragged / a write is
  /// in flight, keyed by channel id. Cleared once the poll catches up.
  final Map<int, int> _localSpeed = {};

  /// Effective setpoint to show for a channel: local override if present,
  /// otherwise the server value.
  int displaySetpoint(ChannelStatus c) => _localSpeed[c.id] ?? c.setpointPercent;

  void start() {
    _poll();
    _pollTimer ??= Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_busy) return;
    _busy = true;
    try {
      final s = await client.status();
      _applyStatus(s);
      _reachability = Reachability.online;
      _lastError = null;
      _consecutiveFailures = 0;
    } catch (e) {
      _consecutiveFailures++;
      _lastError = e is VentApiException ? e.message : e.toString();
      // One blip shouldn't flip the whole UI to offline; require a couple.
      if (_consecutiveFailures >= 2) _reachability = Reachability.offline;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _applyStatus(VentStatus s) {
    _status = s;
    // Drop any optimistic override the server has now caught up to.
    _localSpeed.removeWhere((id, pct) => s.channel(id)?.setpointPercent == pct);
  }

  // --- Commands -------------------------------------------------------------

  /// Live echo while dragging the slider (no network).
  void previewSpeed(int id, int percent) {
    _localSpeed[id] = percent;
    notifyListeners();
  }

  Future<void> commitSpeed(int id, int percent) async {
    _localSpeed[id] = percent;
    await _run(() => client.setSpeed(id, percent));
  }

  Future<void> setDirection(int id, bool forward) => _run(() => client.setDirection(id, forward));

  Future<void> setPower(int id, bool on) => _run(() => client.setPower(id, on));

  Future<void> setEStop(bool engaged) => _run(() => client.eStop(engaged));

  /// Run a write, fold its returned status into state, and surface errors.
  Future<void> _run(Future<VentStatus> Function() action) async {
    try {
      final s = await action();
      _applyStatus(s);
      _reachability = Reachability.online;
      _lastError = null;
      _consecutiveFailures = 0;
    } catch (e) {
      _lastError = e is VentApiException ? e.message : e.toString();
      _consecutiveFailures++;
      if (_consecutiveFailures >= 2) _reachability = Reachability.offline;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    client.dispose();
    super.dispose();
  }
}
