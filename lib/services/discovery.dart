import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models.dart';

/// Finds Engine Room Ventilation panels on the local network via the UDP
/// discovery handshake documented in docs/API.md: broadcast the probe string,
/// collect identity-JSON replies for [timeout].
class PanelDiscovery {
  static const int discoveryPort = 48653;
  static const String probe = 'ENGINE_ROOM_VENT_DISCOVER';

  /// Broadcasts a probe and returns every distinct panel that replies within
  /// [timeout]. The reply's sender IP is the panel's IP, used as the dedup key.
  static Future<List<PanelInfo>> discover({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final found = <String, PanelInfo>{};
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = socket!.receive();
        if (dg == null) return;
        try {
          final info = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
          if (info['service'] == 'engine-room-vent') {
            // Prefer the advertised host; fall back to the sender IP.
            final host = (info['host'] ?? dg.address.address).toString();
            info['host'] = host;
            found[host] = PanelInfo.fromJson(info);
          }
        } catch (_) {
          /* ignore non-JSON datagrams */
        }
      });

      final payload = utf8.encode(probe);
      // Send a few probes — UDP can be lossy and Wi-Fi APs may drop the first.
      for (var i = 0; i < 3; i++) {
        socket.send(payload, InternetAddress('255.255.255.255'), discoveryPort);
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }

      await Future<void>.delayed(timeout);
    } catch (_) {
      /* discovery is best-effort; manual entry is always available */
    } finally {
      socket?.close();
    }
    return found.values.toList();
  }
}
