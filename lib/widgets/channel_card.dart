import 'package:flutter/material.dart';

import '../models.dart';
import '../services/vent_controller.dart';
import '../theme.dart';
import 'propeller_gauge.dart';

/// One fan channel: gauge, live stat tiles, speed slider, direction & power.
class ChannelCard extends StatelessWidget {
  const ChannelCard({super.key, required this.controller, required this.channel, required this.enabled});

  final VentController controller;
  final ChannelStatus channel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = channel.accent;
    final setpoint = controller.displaySetpoint(channel);

    return Container(
      decoration: glassCard(accent: accent),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(accent),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: PropellerGauge(
                  percent: channel.livePercent,
                  accent: accent,
                  spinning: channel.livePercent > 0 && (channel.isRunning || channel.isFailsafe),
                  reversed: !channel.forward,
                  spinFactor: channel.livePercent / 100.0,
                  stateLabel: _stateLabel(channel.state),
                  stateColor: channel.stateColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _statTiles(accent),
          const SizedBox(height: 18),
          _speedRow(accent, setpoint),
          _slider(accent, setpoint),
          const SizedBox(height: 12),
          _controls(accent),
        ],
      ),
    );
  }

  Widget _header(Color accent) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.7), blurRadius: 10)],
          ),
        ),
        const SizedBox(width: 12),
        Text(channel.name, style: const TextStyle(color: VentColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('CH${channel.id}', style: monoStyle.copyWith(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _statTiles(Color accent) {
    return Row(
      children: [
        Expanded(child: _tile('SPEED', channel.rpm.toString(), 'rpm', accent)),
        const SizedBox(width: 10),
        Expanded(child: _tile('CURRENT', channel.amps == null ? '--' : channel.amps!.toStringAsFixed(1), 'A', accent)),
        const SizedBox(width: 10),
        Expanded(child: _tileState('STATUS', _stateLabel(channel.state), channel.stateColor)),
      ],
    );
  }

  Widget _tile(String label, String value, String unit, Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: VentColors.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(child: Text(value, style: monoStyle.copyWith(color: VentColors.text, fontSize: 19, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 3),
                Text(unit, style: monoStyle.copyWith(color: VentColors.muted, fontSize: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _tileState(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: VentColors.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 5),
            Text(value, style: monoStyle.copyWith(color: color, fontSize: 16, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _speedRow(Color accent, int setpoint) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('SPEED SETPOINT', style: TextStyle(color: VentColors.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            Text('$setpoint%', style: monoStyle.copyWith(color: accent, fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _slider(Color accent, int setpoint) => SliderTheme(
        data: SliderThemeData(
          activeTrackColor: accent,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
          thumbColor: Colors.white,
          overlayColor: accent.withValues(alpha: 0.18),
          trackHeight: 6,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
        ),
        child: Slider(
          value: setpoint.toDouble().clamp(0, 100),
          min: 0,
          max: 100,
          onChanged: enabled ? (v) => controller.previewSpeed(channel.id, v.round()) : null,
          onChangeEnd: enabled ? (v) => controller.commitSpeed(channel.id, v.round()) : null,
        ),
      );

  Widget _controls(Color accent) {
    return Row(
      children: [
        Expanded(flex: 3, child: _directionToggle()),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _powerToggle()),
      ],
    );
  }

  /// Segmented OUT | IN direction control.
  Widget _directionToggle() {
    final forward = channel.forward;
    Widget seg(String label, bool active, Color color, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? color.withValues(alpha: 0.22) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? color : Colors.transparent, width: 1.4),
              ),
              child: Text(label, style: TextStyle(color: active ? color : VentColors.muted, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ),
        );
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            seg('◀ OUT', !forward, VentColors.reverseViolet, () => controller.setDirection(channel.id, false)),
            const SizedBox(width: 4),
            seg('IN ▶', forward, VentColors.runGreen, () => controller.setDirection(channel.id, true)),
          ],
        ),
      ),
    );
  }

  Widget _powerToggle() {
    final on = channel.power;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? () => controller.setPower(channel.id, !on) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: on
                ? LinearGradient(colors: [VentColors.runGreen.withValues(alpha: 0.30), VentColors.runGreen.withValues(alpha: 0.16)])
                : null,
            color: on ? null : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? VentColors.runGreen : Colors.white.withValues(alpha: 0.08), width: 1.4),
            boxShadow: on ? [BoxShadow(color: VentColors.runGreen.withValues(alpha: 0.18), blurRadius: 16)] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.power_settings_new, color: on ? VentColors.runGreen : VentColors.muted, size: 20),
              const SizedBox(height: 2),
              Text(on ? 'ON' : 'OFF', style: TextStyle(color: on ? VentColors.runGreen : VentColors.muted, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  static String _stateLabel(String s) => s == 'EStop' ? 'E-STOP' : s.toUpperCase();
}
