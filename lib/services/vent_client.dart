import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

/// Thrown when the panel returns a non-2xx response or the JSON is malformed.
class VentApiException implements Exception {
  VentApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => 'VentApiException($statusCode): $message';
}

/// HTTP/JSON client for the panel's LAN control API (docs/API.md §2).
///
/// Every write returns the freshly-updated `/api/status` body, so callers get
/// new state without a second request.
class VentClient {
  VentClient(this.apiBase, {http.Client? client, this.timeout = const Duration(seconds: 4)})
      : _http = client ?? http.Client();

  /// e.g. "http://172.16.100.187:8787"
  final String apiBase;
  final Duration timeout;
  final http.Client _http;

  Uri _uri(String path) => Uri.parse('$apiBase$path');

  /// Identity payload — same shape as the discovery reply.
  Future<PanelInfo> info() async {
    final r = await _http.get(_uri('/api/info')).timeout(timeout);
    return PanelInfo.fromJson(_decode(r));
  }

  /// Full live system + per-channel snapshot. Poll this ~1 Hz.
  Future<VentStatus> status() async {
    final r = await _http.get(_uri('/api/status')).timeout(timeout);
    return VentStatus.fromJson(_decode(r));
  }

  Future<VentStatus> _postStatus(String path, Map<String, dynamic> body) async {
    final r = await _http
        .post(_uri(path), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(timeout);
    return VentStatus.fromJson(_decode(r));
  }

  /// Engage / release the latched E-Stop.
  Future<VentStatus> eStop(bool engaged) => _postStatus('/api/estop', {'engaged': engaged});

  /// Set fan speed setpoint (0..100).
  Future<VentStatus> setSpeed(int id, int percent) =>
      _postStatus('/api/channels/$id/speed', {'percent': percent});

  /// Direction: true = IN (forward), false = OUT (reverse).
  Future<VentStatus> setDirection(int id, bool forward) =>
      _postStatus('/api/channels/$id/direction', {'forward': forward});

  /// Enable / disable the channel.
  Future<VentStatus> setPower(int id, bool on) =>
      _postStatus('/api/channels/$id/power', {'on': on});

  /// Set any subset of {percent, forward, power} in one call.
  Future<VentStatus> setChannel(int id, {int? percent, bool? forward, bool? power}) =>
      _postStatus('/api/channels/$id', {
        if (percent != null) 'percent': percent,
        if (forward != null) 'forward': forward,
        if (power != null) 'power': power,
      });

  Map<String, dynamic> _decode(http.Response r) {
    Map<String, dynamic>? json;
    if (r.body.isNotEmpty) {
      try {
        json = jsonDecode(r.body) as Map<String, dynamic>;
      } catch (_) {
        json = null;
      }
    }
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (json == null) throw VentApiException('Malformed JSON response', r.statusCode);
      return json;
    }
    final err = json?['error']?.toString() ?? 'HTTP ${r.statusCode}';
    throw VentApiException(err, r.statusCode);
  }

  void dispose() => _http.close();
}
