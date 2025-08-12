import 'package:flutter/material.dart';

class TanqueVisual extends StatelessWidget {
  final double nivel; // de 0.0 a 1.0

  const TanqueVisual({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 100,
      child: CustomPaint(painter: _TanquePainter(nivel: nivel)),
    );
  }
}

//Pintura do tanque
class _TanquePainter extends CustomPainter {
  final double nivel;

  _TanquePainter({required this.nivel});

  @override
  void paint(Canvas canvas, Size size) {
    final paintTanque =
        Paint()
          ..color = Colors.grey.shade700
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

    final paintLeite =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final tanqueRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    canvas.drawRRect(tanqueRect, paintTanque);

    double alturaLeite = size.height * nivel;
    final rectLeite = Rect.fromLTWH(
      0,
      size.height - alturaLeite,
      size.width,
      alturaLeite,
    );

    canvas.clipRRect(tanqueRect); // evita overflow do leite
    canvas.drawRect(rectLeite, paintLeite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
