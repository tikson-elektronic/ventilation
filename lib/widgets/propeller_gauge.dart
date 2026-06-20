import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Premium circular gauge: a glowing value arc with a luminous end-knob, a
/// subtle spinning rotor behind a crisp centre readout. The rotor is intentionally
/// faint — it reads as motion, never clutter over the number.
class PropellerGauge extends StatefulWidget {
  const PropellerGauge({
    super.key,
    required this.percent,
    required this.accent,
    required this.spinning,
    required this.reversed,
    required this.stateLabel,
    required this.stateColor,
    this.spinFactor = 1.0,
  });

  final int percent; // 0..100 live output
  final Color accent;
  final bool spinning;
  final bool reversed;
  final double spinFactor;
  final String stateLabel;
  final Color stateColor;

  @override
  State<PropellerGauge> createState() => _PropellerGaugeState();
}

class _PropellerGaugeState extends State<PropellerGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late int _displayPct = widget.percent;

  @override
  void didUpdateWidget(covariant PropellerGauge old) {
    super.didUpdateWidget(old);
    _displayPct = widget.percent; // arc tween handled by TweenAnimationBuilder below
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _displayPct.clamp(0, 100);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft accent halo that breathes while running.
              AnimatedBuilder(
                animation: _spin,
                builder: (context, _) {
                  final breathe = widget.spinning ? (0.5 + 0.5 * math.sin(_spin.value * 2 * math.pi)) : 0.0;
                  return Container(
                    width: size * (0.70 + 0.06 * breathe),
                    height: size * (0.70 + 0.06 * breathe),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        widget.accent.withValues(alpha: 0.04 + 0.09 * breathe),
                        widget.accent.withValues(alpha: 0),
                      ]),
                    ),
                  );
                },
              ),
              // Faint spinning rotor, behind the number.
              AnimatedBuilder(
                animation: _spin,
                builder: (context, _) {
                  final dir = widget.reversed ? -1.0 : 1.0;
                  final speed = widget.spinning ? (0.25 + widget.spinFactor * 0.9) : 0.0;
                  return Transform.rotate(
                    angle: _spin.value * 2 * math.pi * speed * dir,
                    child: CustomPaint(
                      size: Size.square(size * 0.62),
                      painter: _RotorPainter(accent: widget.accent, active: widget.spinning),
                    ),
                  );
                },
              ),
              // Animated value arc + track.
              TweenAnimationBuilder<double>(
                tween: Tween(end: pct.toDouble()),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CustomPaint(
                  size: Size.square(size),
                  painter: _ArcPainter(percent: value, accent: widget.accent),
                ),
              ),
              // Centre readout.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$pct',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.27,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            letterSpacing: -1,
                            shadows: [Shadow(color: widget.accent.withValues(alpha: 0.45), blurRadius: 24)],
                          ),
                        ),
                        TextSpan(
                          text: ' %',
                          style: TextStyle(
                            color: widget.accent.withValues(alpha: 0.85),
                            fontSize: size * 0.10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: size * 0.04, vertical: size * 0.012),
                    decoration: BoxDecoration(
                      color: widget.stateColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.stateLabel.toUpperCase(),
                      style: monoStyle.copyWith(
                        color: widget.stateColor,
                        fontSize: size * 0.052,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.percent, required this.accent});
  final double percent;
  final Color accent;

  static const double _start = math.pi * 0.75; // 135°
  static const double _sweep = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.055;
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2 + size.width * 0.06);
    final center = inset.center;
    final radius = inset.width / 2;

    // Track.
    canvas.drawArc(
      inset,
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    if (percent <= 0) return;
    final frac = percent / 100;
    final sweep = _sweep * frac;

    final shader = SweepGradient(
      startAngle: _start,
      endAngle: _start + _sweep,
      colors: [accent.withValues(alpha: 0.45), accent],
      transform: const GradientRotation(_start),
    ).createShader(inset);

    // Glow underlay.
    canvas.drawArc(
      inset,
      _start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.6
        ..strokeCap = StrokeCap.round
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Crisp arc.
    canvas.drawArc(
      inset,
      _start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );

    // Luminous end-knob.
    final end = _start + sweep;
    final knob = Offset(center.dx + radius * math.cos(end), center.dy + radius * math.sin(end));
    canvas.drawCircle(knob, stroke * 0.9, Paint()
      ..color = accent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(knob, stroke * 0.55, Paint()..color = Colors.white);
    canvas.drawCircle(knob, stroke * 0.30, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.percent != percent || old.accent != accent;
}

class _RotorPainter extends CustomPainter {
  _RotorPainter({required this.accent, required this.active});
  final Color accent;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final color = (active ? accent : VentColors.muted).withValues(alpha: active ? 0.24 : 0.08);
    final blade = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * 2 * math.pi / 3);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(r * 0.50, -r * 0.24, r, 0)
        ..quadraticBezierTo(r * 0.50, r * 0.12, 0, 0)
        ..close();
      canvas.drawPath(path, blade);
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.12, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RotorPainter old) => old.accent != accent || old.active != active;
}
