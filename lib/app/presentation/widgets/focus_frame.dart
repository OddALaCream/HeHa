import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Marco de enfoque con esquinas tipo visor. La opacidad late suavemente
/// cuando la app esta reconociendo, dando feedback animado controlado.
class FocusFrame extends StatelessWidget {
  const FocusFrame({super.key, required this.active});

  /// `true` mientras se procesa un frame (la animacion se intensifica).
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      tween: Tween<double>(begin: 0.45, end: active ? 1.0 : 0.55),
      builder: (context, opacity, _) {
        return CustomPaint(
          painter: _FocusFramePainter(opacity: opacity),
        );
      },
    );
  }
}

class _FocusFramePainter extends CustomPainter {
  _FocusFramePainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.white.withValues(alpha: opacity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final inset = size.shortestSide * 0.16;
    final rect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    const corner = 42.0;

    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(corner, 0), paint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft + const Offset(0, corner), paint);
    canvas.drawLine(
        rect.topRight, rect.topRight - const Offset(corner, 0), paint);
    canvas.drawLine(
        rect.topRight, rect.topRight + const Offset(0, corner), paint);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + const Offset(corner, 0), paint);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft - const Offset(0, corner), paint);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight - const Offset(corner, 0), paint);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight - const Offset(0, corner), paint);
  }

  @override
  bool shouldRepaint(covariant _FocusFramePainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
