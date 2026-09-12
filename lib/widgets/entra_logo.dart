import 'package:flutter/material.dart';

class EntraLogo extends StatelessWidget {
  const EntraLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _EntraLogoPainter()),
    );
  }
}

class _EntraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mark = Paint()..color = const Color(0xFF09090B);
    final whiteLine = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.109375;

    final radius = Radius.circular(size.width * 0.25);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, radius), mark);

    Path line(double x1, double y1, double x2, double y2) => Path()
      ..moveTo(size.width * x1, size.height * y1)
      ..lineTo(size.width * x2, size.height * y2);

    canvas.drawPath(line(.328125, .28125, .328125, .71875), whiteLine);
    canvas.drawPath(line(.375, .28125, .71875, .28125), whiteLine);
    canvas.drawPath(line(.375, .5, .625, .5), whiteLine);
    canvas.drawPath(line(.375, .71875, .71875, .71875), whiteLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
