import 'dart:math' as math;
import 'package:flutter/material.dart';

class TanqueVisual extends StatelessWidget {
  final double nivel; // 0.0 a 1.0
  final double width; // largura do tanque
  final double height; // altura do tanque
  final bool showPercent; // mostra % no rodapé

  const TanqueVisual({
    super.key,
    required this.nivel,
    this.width = 120,
    this.height = 240,
    this.showPercent = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = nivel.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(painter: _TanquePainter(nivel: clamped)),
        ),
        if (showPercent) ...[
          const SizedBox(height: 8),
          Text(
            '${(clamped * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color.fromARGB(255, 255, 255, 255),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _TanquePainter extends CustomPainter {
  final double nivel;
  _TanquePainter({required this.nivel});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final r = 22.0;
    final tanque = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // ===== Outline “metálico” (gradiente) =====
    final outline =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFCBD5E1), // slate-300
              const Color(0xFF94A3B8), // slate-400
              const Color(0xFF64748B), // slate-500
            ],
          ).createShader(rect);

    // ===== Fundo sutil dentro do tanque (glass) =====
    final fundo =
        Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF).withOpacity(0.08),
              const Color(0xFFFFFFFF).withOpacity(0.14),
            ],
          ).createShader(rect);

    // Clip do tanque
    canvas.save();
    canvas.clipRRect(tanque);
    // Fundo
    canvas.drawRect(rect, fundo);

    // ===== Leite com gradiente off-white =====
    final alturaLeite = size.height * nivel;
    final leiteRect = Rect.fromLTWH(
      0,
      size.height - alturaLeite,
      size.width,
      alturaLeite,
    );

    final leitePaint =
        Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8FAFC), // off-white
              const Color(0xFFFFFFFF),
            ],
          ).createShader(leiteRect);

    canvas.drawRect(leiteRect, leitePaint);

    // ===== Onda sutil na superfície =====
    if (alturaLeite > 2) {
      final ySurface = size.height - alturaLeite;
      final path = Path();
      final amplitude = 4.0;
      final wavelength = size.width / 1.2;
      path.moveTo(0, ySurface);

      for (double x = 0; x <= size.width; x += 1) {
        final y =
            ySurface + math.sin((x / wavelength) * 2 * math.pi) * amplitude;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final ondaPaint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.white.withOpacity(0.55);

      canvas.drawPath(path, ondaPaint);
    }

    // ===== Reflexo vertical (highlight) =====
    final highlight =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.20),
              Colors.transparent,
              Colors.white.withOpacity(0.10),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(
            Rect.fromLTWH(size.width * 0.12, 0, size.width * 0.18, size.height),
          );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.12, 0, size.width * 0.18, size.height),
      highlight,
    );

    // ===== Marcação de nível (tic marks) =====
    final tickPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.28)
          ..strokeWidth = 1.2;
    const ticks = 6;
    for (int i = 1; i < ticks; i++) {
      final ty = size.height * (i / ticks);
      canvas.drawLine(
        Offset(size.width - 10, ty),
        Offset(size.width, ty),
        tickPaint,
      );
    }

    canvas.restore();

    // Outline por cima
    canvas.drawRRect(tanque, outline);

    // ===== Sombra externa suave =====
    final shadowPath = Path()..addRRect(tanque);
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.25), 8, false);
  }

  @override
  bool shouldRepaint(covariant _TanquePainter oldDelegate) =>
      oldDelegate.nivel != nivel;
}
