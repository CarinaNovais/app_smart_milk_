import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class TanqueVisual extends StatelessWidget {
  /// Nível entre 0.0 e 1.0
  final double nivel;

  /// Fonte reativa opcional do nível. Se informado, o widget ignora [nivel]
  /// e passa a rebuildar automaticamente quando o valor mudar.
  final ValueListenable<double>? nivelListenable;

  /// Largura e altura do tanque.
  final double width;
  final double height;

  /// Exibir percentual abaixo do tanque.
  final bool showPercent;

  const TanqueVisual({
    super.key,
    required this.nivel,
    this.nivelListenable,
    this.width = 120,
    this.height = 240,
    this.showPercent = true,
  });

  @override
  Widget build(BuildContext context) {
    if (nivelListenable != null) {
      return ValueListenableBuilder<double>(
        valueListenable: nivelListenable!,
        builder: (context, value, _) {
          final clamped = value.clamp(0.0, 1.0).toDouble();
          return _buildWithNivel(context, clamped);
        },
      );
    }

    final clamped = nivel.clamp(0.0, 1.0).toDouble();
    return _buildWithNivel(context, clamped);
  }

  Widget _buildWithNivel(BuildContext context, double clamped) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: height,
          // Força rebuild visual quando o valor muda
          child: CustomPaint(
            key: ValueKey(clamped),
            painter: _TanquePainter(nivel: clamped),
          ),
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
    const r = 22.0;
    final tanque = RRect.fromRectAndRadius(rect, const Radius.circular(r));

    // ===== Outline “metálico” (gradiente) =====
    final outline =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFCBD5E1), // slate-300
              Color(0xFF94A3B8), // slate-400
              Color(0xFF64748B), // slate-500
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

    // Clip do tanque e fundo
    canvas.save();
    canvas.clipRRect(tanque);
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
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC), // off-white
              Color(0xFFFFFFFF),
            ],
          ).createShader(leiteRect);

    canvas.drawRect(leiteRect, leitePaint);

    // ===== Onda sutil na superfície =====
    if (alturaLeite > 2) {
      final ySurface = size.height - alturaLeite;
      final path = Path();
      const amplitude = 4.0;
      final wavelength = size.width / 1.2;
      path.moveTo(0, ySurface);

      for (double x = 0; x <= size.width; x += 1) {
        final y =
            ySurface + math.sin((x / wavelength) * 2 * math.pi) * amplitude;
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      final ondaPaint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.white.withOpacity(0.55);

      canvas.drawPath(path, ondaPaint);
    }

    // ===== Reflexo vertical (highlight) =====
    final highlight =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(51, 255, 255, 255), // 0.20
              Colors.transparent,
              Color.fromARGB(26, 255, 255, 255), // 0.10
            ],
            stops: [0.0, 0.45, 1.0],
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
  bool shouldRepaint(covariant _TanquePainter oldDelegate) {
    // Tolerância para doubles evita “não repintar” por arredondamentos
    return (oldDelegate.nivel - nivel).abs() > 0.0001;
  }
}
