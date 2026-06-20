import 'theme.dart';
import 'package:flutter/material.dart';

/// Identity of a panel, from UDP discovery or `GET /api/info`.
class PanelInfo {
  PanelInfo({
    required this.name,
    required this.vendor,
    required this.version,
    required this.host,
    required this.httpPort,
    required this.apiBase,
    required this.channels,
  });

  final String name;
  final String vendor;
  final String version;
  final String host;
  final int httpPort;
  final String apiBase;
  final List<ChannelDef> channels;

  factory PanelInfo.fromJson(Map<String, dynamic> j) {
    final host = (j['host'] ?? '').toString();
    final port = (j['httpPort'] as num?)?.toInt() ?? 8787;
    return PanelInfo(
      name: (j['name'] ?? 'Engine Room Ventilation').toString(),
      vendor: (j['vendor'] ?? '').toString(),
      version: (j['version'] ?? '').toString(),
      host: host,
      httpPort: port,
      apiBase: (j['apiBase'] ?? 'http://$host:$port').toString(),
      channels: ((j['channels'] as List?) ?? const [])
          .map((e) => ChannelDef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Static per-channel definition (id, name, rated values).
class ChannelDef {
  ChannelDef({required this.id, required this.name, required this.ratedRpm, required this.ratedAmps});
  final int id;
  final String name;
  final int ratedRpm;
  final double ratedAmps;

  factory ChannelDef.fromJson(Map<String, dynamic> j) => ChannelDef(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] ?? 'FAN').toString(),
        ratedRpm: (j['ratedRpm'] as num?)?.toInt() ?? 0,
        ratedAmps: (j['ratedAmps'] as num?)?.toDouble() ?? 0,
      );
}

/// Link state of the panel↔controller serial link (`GET /api/status`).
enum LinkState { connecting, linked, lost }

LinkState _linkFrom(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'linked':
      return LinkState.linked;
    case 'lost':
      return LinkState.lost;
    default:
      return LinkState.connecting;
  }
}

/// Full live system + per-channel snapshot from `GET /api/status`.
class VentStatus {
  VentStatus({
    required this.link,
    required this.linked,
    required this.eStop,
    required this.statusText,
    required this.fault,
    required this.mainVoltage,
    required this.temperature,
    required this.totalAmps,
    required this.secondsSinceGood,
    required this.activePort,
    required this.channels,
  });

  final LinkState link;
  final bool linked;
  final bool eStop;
  final String statusText;
  final bool fault;
  final double? mainVoltage;
  final double? temperature;
  final double? totalAmps;
  final double secondsSinceGood;
  final String activePort;
  final List<ChannelStatus> channels;

  factory VentStatus.fromJson(Map<String, dynamic> j) => VentStatus(
        link: _linkFrom(j['link'] as String?),
        linked: j['linked'] == true,
        eStop: j['eStop'] == true,
        statusText: (j['status'] ?? '').toString(),
        fault: j['fault'] == true,
        mainVoltage: (j['mainVoltage'] as num?)?.toDouble(),
        temperature: (j['temperature'] as num?)?.toDouble(),
        totalAmps: (j['totalAmps'] as num?)?.toDouble(),
        secondsSinceGood: (j['secondsSinceGood'] as num?)?.toDouble() ?? 0,
        activePort: (j['activePort'] ?? '').toString(),
        channels: ((j['channels'] as List?) ?? const [])
            .map((e) => ChannelStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  ChannelStatus? channel(int id) {
    for (final c in channels) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Per-channel live state. `state` ∈ Off | Run | Reverse | Failsafe | EStop.
class ChannelStatus {
  ChannelStatus({
    required this.id,
    required this.name,
    required this.setpointPercent,
    required this.forward,
    required this.power,
    required this.livePercent,
    required this.state,
    required this.rpm,
    required this.amps,
    required this.ratedRpm,
    required this.ratedAmps,
    required this.accent,
  });

  final int id;
  final String name;
  final int setpointPercent;
  final bool forward;
  final bool power;
  final int livePercent;
  final String state;
  final int rpm;
  final double? amps;
  final int ratedRpm;
  final double ratedAmps;
  final Color accent;

  factory ChannelStatus.fromJson(Map<String, dynamic> j) {
    final id = (j['id'] as num?)?.toInt() ?? 0;
    return ChannelStatus(
      id: id,
      name: (j['name'] ?? 'FAN').toString(),
      setpointPercent: (j['setpointPercent'] as num?)?.toInt() ?? 0,
      forward: j['forward'] != false,
      power: j['power'] == true,
      livePercent: (j['livePercent'] as num?)?.toInt() ?? 0,
      state: (j['state'] ?? 'Off').toString(),
      rpm: (j['rpm'] as num?)?.toInt() ?? 0,
      amps: (j['amps'] as num?)?.toDouble(),
      ratedRpm: (j['ratedRpm'] as num?)?.toInt() ?? 0,
      ratedAmps: (j['ratedAmps'] as num?)?.toDouble() ?? 0,
      accent: parseHexColor(j['accent'] as String?) ?? VentColors.accentFor(id),
    );
  }

  bool get isRunning => state == 'Run' || state == 'Reverse';
  bool get isFailsafe => state == 'Failsafe';
  bool get isEStop => state == 'EStop';

  /// Color for the state label, matching the panel's state→color mapping.
  Color get stateColor {
    switch (state) {
      case 'Run':
        return VentColors.runGreen;
      case 'Reverse':
        return VentColors.reverseViolet;
      case 'Failsafe':
      case 'EStop':
        return VentColors.faultRed;
      default:
        return VentColors.muted;
    }
  }
}
