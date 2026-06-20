import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Color tokens mirrored from the panel app's Section 6 style spec
/// (Themes/Theme.cs) so the remote matches the touchscreen exactly.
class VentColors {
  static const background = Color(0xFF0C1013);
  static const panel = Color(0xFF141B20);
  static const panelAlt = Color(0xFF1A2228);
  static const line = Color(0xFF26333C);

  static const ch1Cyan = Color(0xFF35D6C8);
  static const ch2Amber = Color(0xFFFFB13C);
  static const runGreen = Color(0xFF4ADE80);
  static const reverseViolet = Color(0xFFC77DFF);
  static const faultRed = Color(0xFFFF5247);

  static const text = Color(0xFFE6EEF2);
  static const muted = Color(0xFF7C8B95);

  /// Per-channel accent fallback by id (the API also sends a hex accent).
  static Color accentFor(int id) => id == 1 ? ch1Cyan : ch2Amber;
}

/// Parse a `#rrggbb` (or `#aarrggbb`) hex string from the API into a [Color].
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var s = hex.replaceFirst('#', '').trim();
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final v = int.tryParse(s, radix: 16);
  return v == null ? null : Color(v);
}

ThemeData buildVentTheme() {
  const mono = 'monospace';
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: VentColors.background,
    colorScheme: base.colorScheme.copyWith(
      surface: VentColors.panel,
      primary: VentColors.ch1Cyan,
      error: VentColors.faultRed,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: VentColors.text,
      displayColor: VentColors.text,
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 8,
      overlayShape: RoundSliderOverlayShape(overlayRadius: 22),
    ),
    extensions: const [_Mono(mono)],
  );
}

class _Mono extends ThemeExtension<_Mono> {
  const _Mono(this.family);
  final String family;
  @override
  ThemeExtension<_Mono> copyWith({String? family}) => _Mono(family ?? this.family);
  @override
  ThemeExtension<_Mono> lerp(covariant ThemeExtension<_Mono>? other, double t) => this;
}

/// Monospace TextStyle helper used for readouts (Chakra/JetBrains-Mono vibe).
const TextStyle monoStyle = TextStyle(fontFamily: 'monospace', fontFamilyFallback: ['Menlo', 'Consolas']);

/// Frosted-glass card surface used across the UI: a faint top-lit gradient,
/// a hairline border, and a soft drop shadow. Pass [accent] to tint the edge.
BoxDecoration glassCard({Color? accent, double radius = 22}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF18222A), Color(0xFF101820)],
    ),
    border: Border.all(
      color: accent?.withValues(alpha: 0.22) ?? Colors.white.withValues(alpha: 0.06),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 12)),
      if (accent != null) BoxShadow(color: accent.withValues(alpha: 0.06), blurRadius: 30, spreadRadius: -4),
    ],
  );
}

/// Deep ambient backdrop: two soft radial glows (cyan left, amber right) that
/// slowly drift and breathe over the near-black background — living depth that
/// mirrors the panel's Section 6 ambience.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: VentColors.background),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final p = _c.value * 2 * math.pi;
          final breathe = 0.5 + 0.5 * math.sin(p); // 0..1
          return Stack(
            children: [
              Positioned(
                left: -180 + 30 * math.sin(p),
                top: -120 + 24 * math.cos(p),
                child: _glow(VentColors.ch1Cyan.withValues(alpha: 0.14 + 0.07 * breathe), 560),
              ),
              Positioned(
                right: -200 - 26 * math.sin(p),
                bottom: -160 - 20 * math.cos(p),
                child: _glow(VentColors.ch2Amber.withValues(alpha: 0.10 + 0.07 * (1 - breathe)), 620),
              ),
              widget.child,
            ],
          );
        },
      ),
    );
  }

  Widget _glow(Color color, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );
}
