import 'package:flutter/material.dart';

import '../models.dart';
import '../services/discovery.dart';
import '../services/vent_client.dart';
import '../theme.dart';
import 'dashboard_screen.dart';

/// Landing screen: auto-discover panels on the LAN (UDP) and let the user pick
/// one, or connect by typing a host/IP manually.
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  bool _scanning = false;
  List<PanelInfo> _panels = [];
  String? _manualError;
  final _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scan();
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
    });
    final panels = await PanelDiscovery.discover(timeout: const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _panels = panels;
      _scanning = false;
    });
  }

  void _open(PanelInfo panel) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DashboardScreen(panel: panel)));
  }

  Future<void> _connectManual() async {
    final raw = _manualController.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _manualError = null;
      _scanning = true;
    });
    final apiBase = _normalizeBase(raw);
    final client = VentClient(apiBase, timeout: const Duration(seconds: 3));
    try {
      final info = await client.info();
      if (!mounted) return;
      _open(info);
    } catch (e) {
      if (!mounted) return;
      setState(() => _manualError = 'Could not reach a panel at $apiBase');
    } finally {
      client.dispose();
      if (mounted) setState(() => _scanning = false);
    }
  }

  String _normalizeBase(String raw) {
    var s = raw;
    if (!s.startsWith('http')) s = 'http://$s';
    final uri = Uri.parse(s);
    final port = uri.hasPort ? uri.port : 8787;
    return 'http://${uri.host}:$port';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VentColors.background,
      body: AmbientBackground(
        child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [VentColors.ch1Cyan, VentColors.ch2Amber]),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: VentColors.ch1Cyan.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: const Icon(Icons.air, color: Colors.black87, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ENGINE ROOM\nVENTILATION', style: TextStyle(color: VentColors.text, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 0.3)),
                            const SizedBox(height: 4),
                            Text('Remote  ·  find a panel on the network', style: TextStyle(color: VentColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      Text('PANELS', style: TextStyle(color: VentColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const Spacer(),
                      if (_scanning)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        TextButton.icon(
                          onPressed: _scan,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Scan'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _panelList(),
                  const SizedBox(height: 28),
                  Text('OR CONNECT MANUALLY', style: TextStyle(color: VentColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualController,
                          style: const TextStyle(color: VentColors.text),
                          keyboardType: TextInputType.url,
                          onSubmitted: (_) => _connectManual(),
                          decoration: InputDecoration(
                            hintText: '172.16.100.187  (or host:8787)',
                            hintStyle: const TextStyle(color: VentColors.muted),
                            filled: true,
                            fillColor: VentColors.panel,
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VentColors.line)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VentColors.ch1Cyan)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _scanning ? null : _connectManual,
                        style: FilledButton.styleFrom(backgroundColor: VentColors.ch1Cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
                        child: const Text('Connect'),
                      ),
                    ],
                  ),
                  if (_manualError != null) ...[
                    const SizedBox(height: 8),
                    Text(_manualError!, style: const TextStyle(color: VentColors.faultRed, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _panelList() {
    if (_panels.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: glassCard(radius: 14),
        child: Center(
          child: Text(
            _scanning ? 'Scanning the network…' : 'No panels found. Make sure you are on the boat LAN, or connect manually below.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: VentColors.muted, fontSize: 13),
          ),
        ),
      );
    }
    return Column(
      children: _panels.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _open(p),
              child: Container(
                decoration: glassCard(accent: VentColors.ch1Cyan, radius: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: VentColors.ch1Cyan.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.developer_board, color: VentColors.ch1Cyan, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(color: VentColors.text, fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('v${p.version}  ·  ${p.channels.length} channels', style: const TextStyle(color: VentColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: VentColors.muted),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
