import 'package:flutter/material.dart';

import '../models.dart';
import '../services/vent_controller.dart';
import '../theme.dart';

/// Top bar: title, link/reachability pill, and the latched E-STOP button.
class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key, required this.controller, required this.onDisconnect});

  final VentController controller;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final status = controller.status;
    final estopEngaged = status?.eStop ?? false;

    const subtitle = 'FV-SERIES  ·  ROBOCLAW 2x200A';

    final controls = [
      _linkPill(controller),
      const SizedBox(width: 12),
      _eStopButton(context, estopEngaged),
      const SizedBox(width: 4),
      IconButton(
        tooltip: 'Disconnect',
        onPressed: onDisconnect,
        icon: const Icon(Icons.logout, color: VentColors.muted),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ENGINE ROOM VENTILATION',
              style: TextStyle(color: VentColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5, height: 1.1),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: VentColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        );

        // Narrow (phone portrait): title on its own line, controls beneath.
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              Row(children: [const Spacer(), ...controls]),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Expanded(child: title), ...controls],
        );
      },
    );
  }

  Widget _linkPill(VentController controller) {
    final (label, color) = _linkLabel(controller);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 12)],
            ),
          ),
          const SizedBox(width: 9),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  (String, Color) _linkLabel(VentController controller) {
    if (controller.reachability == Reachability.offline) {
      return ('OFFLINE', VentColors.faultRed);
    }
    switch (controller.status?.link) {
      case LinkState.linked:
        return ('LINKED', VentColors.runGreen);
      case LinkState.lost:
        return ('LOST', VentColors.faultRed);
      default:
        return ('CONNECTING', VentColors.muted);
    }
  }

  Widget _eStopButton(BuildContext context, bool engaged) {
    return GestureDetector(
      onTap: () => controller.setEStop(!engaged),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: engaged ? null : const LinearGradient(colors: [Color(0xFFFF6B5E), VentColors.faultRed]),
          color: engaged ? VentColors.faultRed.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VentColors.faultRed, width: engaged ? 1.6 : 0),
          boxShadow: engaged ? null : [BoxShadow(color: VentColors.faultRed.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(engaged ? Icons.lock_open : Icons.pan_tool, size: 17, color: engaged ? VentColors.faultRed : Colors.white),
            const SizedBox(width: 8),
            Text(
              engaged ? 'RELEASE' : 'E-STOP',
              style: TextStyle(color: engaged ? VentColors.faultRed : Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}
