import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Bottom system summary strip: total draw, supply voltage, controller status,
/// and per-channel setpoint chips — mirrors the panel's system strip.
class SystemStrip extends StatelessWidget {
  const SystemStrip({super.key, required this.status});
  final VentStatus status;

  @override
  Widget build(BuildContext context) {
    final controllerColor = status.fault
        ? VentColors.faultRed
        : (status.link == LinkState.linked ? VentColors.runGreen : VentColors.muted);
    final controllerText = status.eStop
        ? 'E-STOP ENGAGED'
        : (status.link == LinkState.lost ? 'FAILSAFE (controller holding)' : status.statusText.isEmpty ? '—' : status.statusText);

    return Container(
      decoration: glassCard(radius: 18),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Wrap(
        spacing: 36,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _metric('TOTAL DRAW', status.totalAmps == null ? '--' : status.totalAmps!.toStringAsFixed(1), 'A'),
          _metric('SUPPLY', status.mainVoltage == null ? '--' : status.mainVoltage!.toStringAsFixed(1), 'V'),
          if (status.temperature != null) _metric('TEMP', status.temperature!.toStringAsFixed(0), '°C'),
          _statusBlock('CONTROLLER', controllerText, controllerColor),
          ...status.channels.map(_channelChip),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, String unit) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: VentColors.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: monoStyle.copyWith(color: VentColors.text, fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text(unit, style: monoStyle.copyWith(color: VentColors.muted, fontSize: 12)),
            ],
          ),
        ],
      );

  Widget _statusBlock(String label, String value, Color color) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: VentColors.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 3),
          Text(value, style: monoStyle.copyWith(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _channelChip(ChannelStatus c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(c.name, style: monoStyle.copyWith(color: VentColors.muted, fontSize: 12)),
          const SizedBox(width: 5),
          Text('${c.livePercent}%', style: monoStyle.copyWith(color: VentColors.text, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      );
}
