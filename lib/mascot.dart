// Maskot HADI: digambar dengan kode. Punya banyak pose dan ekspresi.
// Letakkan di: lib/mascot.dart

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

const kMascotBlue = Color(0xFF6CC4FF);
const kMascotPink = Color(0xFFFFABBA);
const _armLeftColor = Color(0xFFDBECFA);
const _armRightColor = Color(0xFFD4E7F7);

/// true  = Hadi mengangkat tangan KANAN-nya (tampak di sisi kiri layar).
/// false = tangan kiri (sisi kanan layar).
const kHadiRaisesRightHand = true;

/// Pose Hadi:
///  down     = kedua tangan turun
///  wave     = satu tangan terangkat (melambai)
///  cheer    = kedua tangan naik, mata menutup senang
///  heart    = memeluk hati besar
///  envelope = memegang amplop bercap hati
///  think    = berpikir keras, tangan di mulut
enum HadiPose { down, wave, cheer, heart, envelope, think }

enum _Face { smile, open, happy, flat }

class _Spec {
  final Offset pl, pr; // bahu (sisi kiri / kanan layar)
  final double al, ar; // sudut lengan (radian, searah jarum jam)
  final double rl, rr; // panjang lengan
  final double heart; // 0..1 hati besar
  final double env; // 0..1 amplop
  final _Face face;

  const _Spec(this.pl, this.pr, this.al, this.ar, this.rl, this.rr,
      {this.heart = 0, this.env = 0, this.face = _Face.smile});

  static _Spec lerp(_Spec a, _Spec b, double t) => _Spec(
        Offset.lerp(a.pl, b.pl, t)!,
        Offset.lerp(a.pr, b.pr, t)!,
        lerpDouble(a.al, b.al, t)!,
        lerpDouble(a.ar, b.ar, t)!,
        lerpDouble(a.rl, b.rl, t)!,
        lerpDouble(a.rr, b.rr, t)!,
        heart: lerpDouble(a.heart, b.heart, t)!,
        env: lerpDouble(a.env, b.env, t)!,
        face: t < 0.5 ? a.face : b.face,
      );
}

const _pL = Offset(800, 1170);
const _pR = Offset(1120, 1170);

const _specs = <HadiPose, _Spec>{
  HadiPose.down: _Spec(_pL, _pR, 1.99, 1.15, 480, 480),
  HadiPose.wave: _Spec(_pL, _pR, 3.75, 0.35, 600, 560, face: _Face.open),
  HadiPose.cheer: _Spec(Offset(730, 1190), Offset(1190, 1190), 4.0, -0.858, 620, 620,
      face: _Face.happy),
  HadiPose.heart: _Spec(Offset(780, 1115), Offset(1140, 1115), 1.40, 1.74, 560, 560,
      heart: 1),
  HadiPose.envelope: _Spec(Offset(780, 1115), Offset(1140, 1115), 1.40, 1.74, 420, 420,
      env: 1),
  HadiPose.think: _Spec(Offset(668, 1295), Offset(1070, 1010), 5.38, 0.745, 520, 640,
      face: _Face.flat),
};

class _PoseHolder {
  _Spec from = _specs[HadiPose.wave]!;
  _Spec to = _specs[HadiPose.wave]!;
  HadiPose fromPose = HadiPose.wave;
  HadiPose toPose = HadiPose.wave;
}

// ───────────────────────── Widget ─────────────────────────

/// Maskot Hadi.
///  - [pose]       : pose saat ini (berpindah dengan halus).
///  - [animate]    : gerak halus terus-menerus (napas, goyang lengan, kedip).
///                   false = diam (hemat baterai, cocok untuk logo kecil).
///  - [autoWave]   : melambai cepat dua kali sesaat setelah muncul.
///  - [background] : gambar lingkaran biru di belakang.
/// Panggil `key.currentState?.waveOnce()` untuk lambaian dua ayunan.
class HadiMascot extends StatefulWidget {
  final double size;
  final HadiPose pose;
  final bool animate;
  final bool autoWave;
  final bool background;

  const HadiMascot({
    super.key,
    this.size = 160,
    this.pose = HadiPose.wave,
    this.animate = true,
    this.autoWave = false,
    this.background = true,
  });

  @override
  State<HadiMascot> createState() => HadiMascotState();
}

class HadiMascotState extends State<HadiMascot> with TickerProviderStateMixin {
  late final AnimationController _loop;
  late final AnimationController _pose;
  late final AnimationController _burst;
  final _holder = _PoseHolder();

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3600));
    if (widget.animate) {
      _loop.repeat();
    } else {
      _loop.value = 1.0; // posisi netral
    }
    _pose = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600), value: 1.0);
    _burst = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    final s = _specs[widget.pose]!;
    _holder.from = s;
    _holder.to = s;
    _holder.fromPose = widget.pose;
    _holder.toPose = widget.pose;

    if (widget.autoWave) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) waveOnce();
      });
    }
  }

  @override
  void didUpdateWidget(covariant HadiMascot old) {
    super.didUpdateWidget(old);
    if (old.pose != widget.pose) _goTo(widget.pose);
    if (old.animate != widget.animate) {
      if (widget.animate) {
        _loop.repeat();
      } else {
        _loop.animateTo(1.0,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      }
    }
  }

  void _goTo(HadiPose p) {
    final tp = Curves.easeInOutCubic.transform(_pose.value.clamp(0.0, 1.0));
    _holder.from = _Spec.lerp(_holder.from, _holder.to, tp);
    _holder.fromPose = _holder.toPose;
    _holder.to = _specs[p]!;
    _holder.toPose = p;
    _pose.forward(from: 0);
  }

  /// Lambaian dua ayunan (terlihat pada pose wave dan cheer).
  void waveOnce({Duration duration = const Duration(milliseconds: 900)}) {
    _burst.duration = duration;
    _burst.forward(from: 0);
  }

  @override
  void dispose() {
    _loop.dispose();
    _pose.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: MascotPainter(
          loop: _loop,
          pose: _pose,
          burst: _burst,
          holder: _holder,
          background: widget.background,
        ),
      ),
    );
  }
}

// ───────────────────────── Painter ─────────────────────────

Path _heartPath(double visW, double visH) {
  final w = visW / 0.8, h = visH / 0.79;
  final dy = -0.106 * h;
  return Path()
    ..moveTo(0, h * 0.5 + dy)
    ..cubicTo(-w * 0.62, h * 0.05 + dy, -w * 0.45, -h * 0.55 + dy, 0, -h * 0.2 + dy)
    ..cubicTo(w * 0.45, -h * 0.55 + dy, w * 0.62, h * 0.05 + dy, 0, h * 0.5 + dy)
    ..close();
}

class MascotPainter extends CustomPainter {
  final Animation<double> loop;
  final Animation<double> pose;
  final Animation<double> burst;
  final _PoseHolder holder;
  final bool background;

  MascotPainter({
    required this.loop,
    required this.pose,
    required this.burst,
    required this.holder,
    required this.background,
  }) : super(repaint: Listenable.merge([loop, pose, burst]));

  static const _origin = Offset(200, 204);
  static const _viewSize = 1532.0;
  static const _center = Offset(966, 970);
  static const _radius = 766.0;

  static final Path _body = Path()
    ..moveTo(560, 1850)
    ..cubicTo(600, 1400, 700, 1180, 860, 1040)
    ..quadraticBezierTo(960, 990, 1060, 1040)
    ..cubicTo(1230, 1150, 1320, 1450, 1345, 1850)
    ..close();

  void _arm(Canvas c, Paint p, Offset pivot, double angle, double reach) {
    c.save();
    c.translate(pivot.dx, pivot.dy);
    c.rotate(angle);
    c.drawOval(Rect.fromLTRB(-40, -115, reach, 115), p);
    c.restore();
  }

  void _face(Canvas c, _Face f, double eyeH) {
    final fill = Paint()..color = kMascotBlue;
    final pen = Paint()
      ..color = kMascotBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    if (f == _Face.happy) {
      for (final x in const [870.0, 1046.0]) {
        c.drawPath(
            Path()
              ..moveTo(x - 34, 800)
              ..quadraticBezierTo(x, 742, x + 34, 800),
            pen);
      }
    } else {
      for (final x in const [870.0, 1046.0]) {
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, 781), width: 52, height: eyeH),
              const Radius.circular(26)),
          fill,
        );
      }
    }

    switch (f) {
      case _Face.smile:
        c.drawPath(
            Path()
              ..moveTo(922, 892)
              ..quadraticBezierTo(962, 944, 1002, 890),
            pen);
        break;
      case _Face.open:
        c.drawPath(
            Path()
              ..moveTo(893, 877)
              ..arcTo(
                  Rect.fromCenter(
                      center: const Offset(958, 877), width: 130, height: 126),
                  0,
                  math.pi,
                  false)
              ..close(),
            fill);
        break;
      case _Face.happy:
        c.drawOval(
            Rect.fromCenter(center: const Offset(960, 912), width: 92, height: 96),
            fill);
        break;
      case _Face.flat:
        c.drawLine(const Offset(938, 905), const Offset(984, 905), pen);
        break;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = loop.value;
    final tp = Curves.easeInOutCubic.transform(pose.value.clamp(0.0, 1.0));
    final s = _Spec.lerp(holder.from, holder.to, tp);

    double weight(HadiPose p) =>
        (holder.toPose == p ? tp : 0.0) + (holder.fromPose == p ? 1 - tp : 0.0);
    final waveW = weight(HadiPose.wave);
    final cheerW = weight(HadiPose.cheer);

    final b = burst.value;
    final bw = (b > 0 && b < 1) ? math.sin(b * math.pi * 4) * (1 - b * 0.35) : 0.0;

    final angL = s.al + math.sin(t * 2 * math.pi) * 0.035 + bw * 0.22 * (waveW + cheerW);
    final angR =
        s.ar + math.sin(t * 2 * math.pi + 1.4) * 0.035 - bw * 0.22 * cheerW;

    final bob = math.sin(t * 2 * math.pi) * 8;
    final beat = math.max(0.0, math.sin(t * math.pi * 4));
    final blinkDip = math.max(0.0, 1 - (t - 0.48).abs() / 0.02);
    final eyeH = 92 * (1 - 0.9 * blinkDip);

    final white = Paint()..color = Colors.white;
    final pink = Paint()..color = kMascotPink;

    canvas.save();
    canvas.scale(size.width / _viewSize);
    canvas.translate(-_origin.dx, -_origin.dy);

    if (background) canvas.drawCircle(_center, _radius, Paint()..color = kMascotBlue);

    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: _center, radius: _radius)));

    if (!kHadiRaisesRightHand) {
      canvas.translate(_center.dx * 2, 0);
      canvas.scale(-1, 1);
    }
    canvas.translate(0, bob);

    // Badan
    canvas.drawPath(_body, white);

    // Hati kecil di dada
    canvas.save();
    canvas.translate(966, 1218);
    final k = 1 + 0.08 * beat;
    canvas.scale(k, k);
    canvas.drawPath(_heartPath(200, 165), pink);
    canvas.restore();

    // Kepala + wajah
    canvas.drawCircle(const Offset(955, 780), 256, white);
    _face(canvas, s.face, eyeH);

    // Lengan (biru muda, digambar di depan badan dan kepala)
    _arm(canvas, Paint()..color = _armLeftColor, s.pl, angL, s.rl);
    _arm(canvas, Paint()..color = _armRightColor, s.pr, angR, s.rr);

    // Hati besar
    if (s.heart > 0.02) {
      canvas.save();
      canvas.translate(975, 1303);
      final hs = s.heart * (1 + 0.04 * beat);
      canvas.scale(hs, hs);
      canvas.drawPath(_heartPath(465, 387), pink);
      canvas.restore();
    }

    // Amplop bercap hati
    if (s.env > 0.02) {
      canvas.save();
      canvas.translate(995, 1385);
      canvas.rotate(-0.05);
      canvas.scale(s.env, s.env);
      final r = Rect.fromCenter(center: Offset.zero, width: 880, height: 300);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(24));
      canvas.drawRRect(rr, Paint()..color = const Color(0xFFC9E6FF));
      final line = Paint()
        ..color = const Color(0xFF8DCBFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      canvas.drawRRect(rr, line);
      canvas.drawLine(r.topLeft, Offset.zero, line);
      canvas.drawLine(r.topRight, Offset.zero, line);
      canvas.drawLine(r.bottomLeft, Offset.zero, line);
      canvas.drawLine(r.bottomRight, Offset.zero, line);
      canvas.drawPath(_heartPath(150, 125), pink);
      canvas.restore();
    }

    canvas.restore(); // clip
    canvas.restore(); // skala
  }

  @override
  bool shouldRepaint(covariant MascotPainter old) =>
      old.background != background || old.holder != holder;
}
