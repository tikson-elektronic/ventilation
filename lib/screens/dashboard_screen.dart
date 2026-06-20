import 'package:flutter/material.dart';

import '../models.dart';
import '../services/vent_controller.dart';
import '../theme.dart';
import '../widgets/channel_card.dart';
import '../widgets/header_bar.dart';
import '../widgets/system_strip.dart';

/// Live control dashboard for one connected panel.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.panel});
  final PanelInfo panel;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final VentController _controller = VentController(panel: widget.panel)..start();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VentColors.background,
      body: AmbientBackground(
        child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final status = _controller.status;
            final offline = _controller.reachability == Reachability.offline;
            final controlsEnabled = !offline && status != null;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: HeaderBar(controller: _controller, onDisconnect: () => Navigator.of(context).pop()),
                ),
                if (offline) _offlineBanner(),
                Expanded(
                  child: status == null
                      ? const Center(child: CircularProgressIndicator())
                      : _body(status, controlsEnabled),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _offlineBanner() => Container(
        width: double.infinity,
        color: VentColors.faultRed.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: VentColors.faultRed, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cannot reach the panel${_controller.lastError != null ? ' — ${_controller.lastError}' : ''}. Retrying…',
                style: const TextStyle(color: VentColors.faultRed, fontSize: 13),
              ),
            ),
          ],
        ),
      );

  Widget _body(VentStatus status, bool controlsEnabled) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        final cards = status.channels
            .map((c) => ChannelCard(controller: _controller, channel: c, enabled: controlsEnabled))
            .toList();

        final Widget cardArea = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(child: cards[i]),
                  ],
                ],
              )
            : Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    // On narrow screens each card needs a bounded height.
                    SizedBox(height: 520, child: cards[i]),
                  ],
                ],
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              wide ? SizedBox(height: 560, child: cardArea) : cardArea,
              const SizedBox(height: 16),
              SystemStrip(status: status),
            ],
          ),
        );
      },
    );
  }
}
