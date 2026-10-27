import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-drawn icons for the spiritual features (Flutter has no built-in ones).
/// Each icon is drawn on a 24x24 grid and scales to the requested size; the colour
/// comes from [color] or the surrounding [IconTheme] (so they work in nav bars).
class AppIcon extends StatelessWidget {
  final void Function(Canvas canvas, Paint fill, Paint stroke) _draw;
  final double? size;
  final Color? color;

  const AppIcon._(this._draw, {this.size, this.color});

  /// Mõ (wooden fish) with its mallet.
  const AppIcon.moBell({double? size, Color? color}) : this._(_drawMo, size: size, color: color);

  /// Incense sticks in a censer with a curl of smoke.
  const AppIcon.incense({double? size, Color? color}) : this._(_drawIncense, size: size, color: color);

  /// Open scripture book.
  const AppIcon.scripture({double? size, Color? color}) : this._(_drawBook, size: size, color: color);

  /// Calendar with a crescent moon (lunar calendar).
  const AppIcon.lunar({double? size, Color? color}) : this._(_drawLunar, size: size, color: color);

  /// Lotus flower (profile / practitioner).
  const AppIcon.lotus({double? size, Color? color}) : this._(_drawLotus, size: size, color: color);

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 24;
    final c = color ?? theme.color ?? Colors.black;
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(painter: _IconPainter(_draw, c)),
    );
  }
}

class _IconPainter extends CustomPainter {
  final void Function(Canvas, Paint, Paint) draw;
  final Color color;
  _IconPainter(this.draw, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    draw(canvas, fill, stroke);
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.color != color || old.draw != draw;
}

void _drawMo(Canvas c, Paint fill, Paint stroke) {
  // dome with a mouth cut-out
  final body = Path()..addOval(const Rect.fromLTWH(2.5, 6.5, 15, 12.5));
  final mouth = Path()..addOval(const Rect.fromLTWH(9, 13.6, 7.4, 2.4));
  c.drawPath(Path.combine(PathOperation.difference, body, mouth), fill);
  // fish tail / handle
  c.drawCircle(const Offset(4.2, 8.2), 1.9, fill);
  // cushion
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 20, 15.5, 2.4), const Radius.circular(1.2)), fill);
  // mallet
  c.drawLine(const Offset(21.2, 2.6), const Offset(16.6, 8.4), stroke);
  c.drawCircle(const Offset(15.9, 9.3), 1.9, fill);
}

void _drawIncense(Canvas c, Paint fill, Paint stroke) {
  // censer
  final bowl = Path()
    ..moveTo(3.5, 14.5)
    ..lineTo(20.5, 14.5)
    ..quadraticBezierTo(20, 20.5, 16, 21.2)
    ..lineTo(8, 21.2)
    ..quadraticBezierTo(4, 20.5, 3.5, 14.5)
    ..close();
  c.drawPath(bowl, fill);
  c.drawLine(const Offset(2.6, 14.5), const Offset(21.4, 14.5), stroke);
  // sticks
  final thin = Paint()
    ..color = stroke.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  c.drawLine(const Offset(8.6, 14), const Offset(7.6, 6.2), thin);
  c.drawLine(const Offset(12, 14), const Offset(12, 4.4), thin);
  c.drawLine(const Offset(15.4, 14), const Offset(16.4, 6.2), thin);
  for (final p in const [Offset(7.5, 5.6), Offset(12, 3.8), Offset(16.5, 5.6)]) {
    c.drawCircle(p, 0.85, fill);
  }
  // smoke
  final smoke = Path()
    ..moveTo(12, 2.6)
    ..cubicTo(10.6, 1.8, 13.4, 0.8, 12, 0.2);
  c.drawPath(smoke, thin);
}

void _drawBook(Canvas c, Paint fill, Paint stroke) {
  // two pages with a thin gap at the spine
  final left = Path()
    ..moveTo(11.3, 6.4)
    ..cubicTo(9, 4.4, 6, 4.2, 2.8, 5.2)
    ..lineTo(2.8, 19)
    ..cubicTo(6, 18, 9, 18.3, 11.3, 20.4)
    ..close();
  final right = Path()
    ..moveTo(12.7, 6.4)
    ..cubicTo(15, 4.4, 18, 4.2, 21.2, 5.2)
    ..lineTo(21.2, 19)
    ..cubicTo(18, 18, 15, 18.3, 12.7, 20.4)
    ..close();
  c.drawPath(left, fill);
  c.drawPath(right, fill);
}

void _drawLunar(Canvas c, Paint fill, Paint stroke) {
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 4.5, 18, 16.5), const Radius.circular(3)), stroke);
  c.drawLine(const Offset(3, 9.5), const Offset(21, 9.5), stroke);
  c.drawLine(const Offset(8, 2.8), const Offset(8, 6), stroke);
  c.drawLine(const Offset(16, 2.8), const Offset(16, 6), stroke);
  // crescent moon
  final moon = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: const Offset(12, 15.2), radius: 3.6)),
    Path()..addOval(Rect.fromCircle(center: const Offset(13.6, 14.4), radius: 3.2)),
  );
  c.drawPath(moon, fill);
}

void _drawLotus(Canvas c, Paint fill, Paint stroke) {
  Path petal(double len, double width) => Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(width, -len * 0.5, 0, -len)
    ..quadraticBezierTo(-width, -len * 0.5, 0, 0);
  c.save();
  c.translate(12, 20);
  for (final a in const [-70.0, 70.0]) {
    c.save();
    c.rotate(a * math.pi / 180);
    c.drawPath(petal(11, 4.2), fill);
    c.restore();
  }
  for (final a in const [-36.0, 36.0]) {
    c.save();
    c.rotate(a * math.pi / 180);
    c.drawPath(petal(14.5, 4.6), fill);
    c.restore();
  }
  c.drawPath(petal(17, 4.4), fill);
  c.restore();
  c.drawLine(const Offset(5, 21.4), const Offset(19, 21.4), stroke);
}
