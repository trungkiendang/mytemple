import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Incense sticks, glowing tips, ash, sparks and smoke, drawn over the (fixed-camera) 3D censer.
///
/// The camera of the 3D view is fixed ([IncenseFx.orbitTheta] …), so 3D points on the censer
/// can be projected to screen with the same maths and the sticks stay planted in the ash.
/// Smoke style depends on the number of sticks:
///  * 1 stick  → a thin straight column that sways gently,
///  * 3 sticks → three strands that braid / coil around each other as they rise,
///  * 5 sticks → five strands that merge into a big swirling plume with curls.
class IncenseFx extends CustomPainter {
  // Camera used by the 3D view (keep in sync with IncenseScreen's O3D settings).
  static const orbitTheta = 30.0; // degrees around Y
  static const orbitPhi = 80.0; // degrees from +Y
  static const orbitRadius = 4.9; // metres (leaves head-room for the smoke)
  static const fovDeg = 30.0; // vertical field of view
  static const target = [0.0, 0.88, 0.0];

  static const ashY = 0.55; // height of the ash surface in the censer model
  static const stickLen = 0.72; // visible length of a fresh stick (m)
  static const lean = 0.18; // radians

  /// [base x, base z, lean direction x, lean direction z] per stick count.
  static const layouts = <int, List<List<double>>>{
    1: [
      [0, 0, 0, 0],
    ],
    3: [
      [-0.11, 0.03, -1, 0.15],
      [0.0, -0.04, 0, -0.2],
      [0.11, 0.03, 1, 0.15],
    ],
    5: [
      [0, 0, 0, 0],
      [-0.12, 0.0, -1, 0],
      [0.12, 0.0, 1, 0],
      [0.0, 0.12, 0, 1],
      [0.0, -0.12, 0, -1],
    ],
  };

  final int sticks;
  final bool burning;
  final bool burntOut; // timer finished: only ash stubs are left
  final double burn; // 0 (just lit) .. 1 (burnt down)
  final double t; // seconds, for animation

  IncenseFx({
    required this.sticks,
    required this.burning,
    required this.burn,
    required this.t,
    this.burntOut = false,
  });

  // ── projection ────────────────────────────────────────────────────────
  static List<double> _norm(List<double> v) {
    final l = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    return [v[0] / l, v[1] / l, v[2] / l];
  }

  static List<double> _cross(List<double> a, List<double> b) => [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  ];

  static double _dot(List<double> a, List<double> b) =>
      a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

  /// Projects a world point to the 3D view's pixel coordinates; z = pixels per metre there.
  static ({Offset p, double scale}) project(
    Size size,
    double x,
    double y,
    double z,
  ) {
    final th = orbitTheta * math.pi / 180, ph = orbitPhi * math.pi / 180;
    final cam = [
      target[0] + orbitRadius * math.sin(ph) * math.sin(th),
      target[1] + orbitRadius * math.cos(ph),
      target[2] + orbitRadius * math.sin(ph) * math.cos(th),
    ];
    final f = _norm([
      target[0] - cam[0],
      target[1] - cam[1],
      target[2] - cam[2],
    ]);
    final r = _norm(_cross(f, [0, 1, 0]));
    final u = _cross(r, f);
    final v = [x - cam[0], y - cam[1], z - cam[2]];
    final depth = _dot(v, f);
    final tanHalf = math.tan(fovDeg * math.pi / 360);
    final aspect = size.width / size.height;
    final ndcX = _dot(v, r) / (depth * tanHalf * aspect);
    final ndcY = _dot(v, u) / (depth * tanHalf);
    final pxPerMetre = size.height / (2 * tanHalf * depth);
    return (
      p: Offset(size.width / 2 * (1 + ndcX), size.height / 2 * (1 - ndcY)),
      scale: pxPerMetre,
    );
  }

  // ── geometry of one stick ─────────────────────────────────────────────
  ({Offset base, Offset tip, double scale, double remaining}) _stick(
    Size size,
    int i,
  ) {
    final l = layouts[sticks]![i];
    final leanAngle = sticks == 1 ? 0.0 : lean;
    final rz = -l[2] * leanAngle, rx = l[3] * leanAngle;
    final dir = [
      -math.cos(rx) * math.sin(rz),
      math.cos(rx) * math.cos(rz),
      math.sin(rx),
    ];
    // every stick burns at a slightly different pace
    // (they all finish within a few percent of the chosen time; a short stub stays until the end)
    final pace = 0.95 + 0.05 * _hash(i * 7.31);
    final remaining = burntOut
        ? 0.05
        : (burning ? math.max(0.05, 1 - burn * pace) : 1.0);
    final len = stickLen * remaining;
    final b = project(size, l[0], ashY, l[1]);
    final tip = project(
      size,
      l[0] + dir[0] * len,
      ashY + dir[1] * len,
      l[1] + dir[2] * len,
    );
    return (base: b.p, tip: tip.p, scale: b.scale, remaining: remaining);
  }

  static double _hash(double x) {
    final s = math.sin(x * 12.9898) * 43758.5453;
    return s - s.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final geo = [for (var i = 0; i < sticks; i++) _stick(size, i)];
    // far sticks first
    final order = List<int>.generate(sticks, (i) => i)
      ..sort((a, b) => geo[a].base.dy.compareTo(geo[b].base.dy));

    for (final i in order) {
      _drawStick(canvas, geo[i], i);
    }
    if (burning) {
      _drawSmoke(canvas, size, [for (final g in geo) g.tip]);
      for (var i = 0; i < sticks; i++) {
        _drawEmber(canvas, geo[i].tip, i);
      }
    }
  }

  // ── stick + ash + ember ───────────────────────────────────────────────
  void _drawStick(
    Canvas canvas,
    ({Offset base, Offset tip, double scale, double remaining}) g,
    int i,
  ) {
    final width = (g.scale * 0.024).clamp(2.2, 7.0);
    final dir = g.tip - g.base;
    final len = dir.distance;
    if (len < 0.5) return;
    final unit = dir / len;

    // burnt (ash) segment at the top once lit
    final ashLen = burntOut
        ? len
        : (burning ? math.min(len * 0.5, 3 + 16 * burn) : 0.0);
    final bodyEnd = g.tip - unit * ashLen;

    if (!burntOut) {
      canvas.drawLine(
        g.base,
        bodyEnd,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF7A2415), Color(0xFFC24A2E)],
          ).createShader(Rect.fromPoints(g.base, bodyEnd).inflate(1))
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }
    if (!burning && !burntOut) {
      // unlit: the pasted tip of a fresh stick
      canvas.drawLine(
        g.tip - unit * math.min(len * 0.12, 14),
        g.tip,
        Paint()
          ..color = const Color(0xFFE2B35A)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    } else if (ashLen > 0.5) {
      // ash: pale, slightly thicker and slightly bent
      final bend = Offset(unit.dy, -unit.dx) * (2.0 * math.sin(i + t * 0.3));
      final path = Path()
        ..moveTo(bodyEnd.dx, bodyEnd.dy)
        ..quadraticBezierTo(
          (bodyEnd.dx + g.tip.dx) / 2 + bend.dx,
          (bodyEnd.dy + g.tip.dy) / 2 + bend.dy,
          g.tip.dx,
          g.tip.dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFD9D2C8)
          ..strokeWidth = width * 1.15
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawEmber(Canvas canvas, Offset tip, int i) {
    final flicker =
        0.5 + 0.5 * math.sin(t * 9 + i * 1.7) * math.sin(t * 5.3 + i);
    final radius = 12 + 5 * flicker;
    canvas.drawCircle(
      tip,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF9A2E).withValues(alpha: 0.55 + 0.25 * flicker),
            const Color(0xFFFF5A00).withValues(alpha: 0.18),
            const Color(0x00FF5A00),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: tip, radius: radius)),
    );
    canvas.drawCircle(
      tip,
      2.6 + 0.9 * flicker,
      Paint()..color = const Color(0xFFFFD27A),
    );
    canvas.drawCircle(
      tip,
      1.4,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // sparks drifting up from the tip
    for (var j = 0; j < 3; j++) {
      final u = ((t * 0.7 + j / 3.0 + _hash(i * 3.0 + j)) % 1.0);
      final gate = _hash(
        (t * 0.7 + j / 3.0 + _hash(i * 3.0 + j)).floorToDouble() * 3 +
            i +
            j * 11,
      );
      if (gate < 0.45) continue;
      final px = tip.dx + math.sin(u * 9 + j * 2.1 + i) * 7 * u;
      final py = tip.dy - u * 34;
      canvas.drawCircle(
        Offset(px, py),
        1.5 * (1 - u) + 0.3,
        Paint()
          ..color = const Color(0xFFFFB347).withValues(alpha: (1 - u) * 0.9),
      );
    }
  }

  // ── smoke ─────────────────────────────────────────────────────────────
  void _drawSmoke(Canvas canvas, Size size, List<Offset> tips) {
    final cx = tips.fold<double>(0, (a, o) => a + o.dx) / tips.length;
    final top = tips.map((o) => o.dy).reduce(math.min);
    final height = math.min(size.height * 0.62, top - 6);
    if (height < 20) return;
    const n = 64;

    // centre line of one strand; [phaseShift]/[ampScale] let a thin "wisp" curl around the main strand
    List<Offset> strand(
      int i,
      double phaseShift,
      double ampScale,
      List<double> widths,
    ) {
      final e = tips[i];
      final phase = i * 2 * math.pi / tips.length + phaseShift;
      final pts = <Offset>[];
      for (var k = 0; k <= n; k++) {
        final s = k / n;
        double x, y, w;
        switch (sticks) {
          case 1: // straight column, gentle sway
            x =
                e.dx +
                ampScale *
                    (6 *
                            s *
                            math.sin(
                              2 * math.pi * 1.1 * s - t * 1.3 + phaseShift,
                            ) +
                        3 * s * math.sin(t * 0.6));
            y = e.dy - s * height;
            w = 1.6 + 7 * math.pow(s, 1.1);
            break;
          case 3: // braid: strands converge and wind around each other
            final conv = _smooth(0, 0.55, s);
            final amp = ampScale * (3 + 26 * s);
            final ang = 2 * math.pi * 1.7 * s - t * 1.5 + phase;
            x = _lerp(e.dx, cx, conv) + amp * math.sin(ang);
            y = e.dy - s * height + 0.22 * amp * math.cos(ang);
            w = 1.8 + 6 * s;
            break;
          default: // 5 → a big swirling plume with curls
            final conv = _smooth(0, 0.4, s);
            final amp = ampScale * (5 + 42 * s);
            final ang = 2 * math.pi * 2.2 * s - t * 1.9 + phase;
            x =
                _lerp(e.dx, cx, conv) +
                amp * math.sin(ang) +
                8 * s * math.sin(t * 0.5 + i);
            y = e.dy - s * height + 0.95 * amp * math.cos(ang) * s;
            w = 2 + 8 * s;
        }
        pts.add(Offset(x, y));
        widths.add(w);
      }
      return pts;
    }

    for (var i = 0; i < tips.length; i++) {
      final e = tips[i];
      final widths = <double>[];
      final pts = strand(i, 0, 1, widths);
      // 1) faint soft body (narrow, barely blurred so it does not smear)
      _ribbon(canvas, pts, widths, e.dy, e.dy - height, strong: 0.2);
      // 2) crisp dark core line – the readable "line" of the smoke
      _core(
        canvas,
        pts,
        e.dy,
        e.dy - height,
        width: sticks == 1 ? 2.4 : 2.0,
        alpha: 0.85,
      );
      // 3) a thin wisp that curls around the main strand
      final wispW = <double>[];
      final wisp = strand(i, math.pi * 0.7, sticks == 1 ? 2.2 : 0.75, wispW);
      _core(canvas, wisp, e.dy, e.dy - height * 0.85, width: 1.3, alpha: 0.5);
    }

    if (sticks >= 3) {
      // very light haze where the strands have merged
      final haze = Paint()
        ..color = const Color(
          0xFFB9B0A5,
        ).withValues(alpha: sticks == 5 ? 0.07 : 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      for (var j = 0; j < (sticks == 5 ? 3 : 2); j++) {
        final s = 0.55 + 0.35 * ((t * 0.25 + j * 0.37) % 1.0);
        canvas.drawCircle(
          Offset(cx + math.sin(t * 0.8 + j * 1.9) * 22, top - s * height),
          10 + 16 * s,
          haze,
        );
      }
    }
  }

  /// A crisp, thin line that fades towards the top (no blur).
  void _core(
    Canvas canvas,
    List<Offset> pts,
    double yStart,
    double yEnd, {
    required double width,
    required double alpha,
  }) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var k = 1; k < pts.length; k++) {
      final mid = (pts[k - 1] + pts[k]) / 2;
      path.quadraticBezierTo(pts[k - 1].dx, pts[k - 1].dy, mid.dx, mid.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width
        ..isAntiAlias = true
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF6B635B).withValues(alpha: alpha),
            const Color(0xFF857D74).withValues(alpha: alpha * 0.7),
            const Color(0x00857D74),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(Rect.fromLTRB(0, yEnd, 4000, yStart)),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _smooth(double a, double b, double x) {
    final u = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return u * u * (3 - 2 * u);
  }

  void _ribbon(
    Canvas canvas,
    List<Offset> pts,
    List<double> widths,
    double yStart,
    double yEnd, {
    required double strong,
  }) {
    final left = <Offset>[], right = <Offset>[];
    for (var k = 0; k < pts.length; k++) {
      final a = pts[math.max(k - 1, 0)],
          b = pts[math.min(k + 1, pts.length - 1)];
      var d = b - a;
      if (d.distance == 0) d = const Offset(0, -1);
      final nrm = Offset(-d.dy, d.dx) / d.distance;
      left.add(pts[k] + nrm * (widths[k] / 2));
      right.add(pts[k] - nrm * (widths[k] / 2));
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    final rect = Rect.fromLTRB(0, yEnd, 4000, yStart);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF8C847B).withValues(alpha: strong),
            const Color(0xFFA89F94).withValues(alpha: strong * 0.55),
            const Color(0x00A89F94),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );
  }

  @override
  bool shouldRepaint(IncenseFx old) => true;
}
