// Warna, helper tanggal, tombol, dan judul bergaya "HADIR".
// Letakkan di: lib/app_theme.dart

import 'package:flutter/material.dart';

// ───────────────────────── Warna ─────────────────────────

const kBlue = Color(0xFF60A5FA);
const kBlueDark = Color(0xFF2563EB);
const kBlueSoft = Color(0xFFDBEAFE);
const kInk = Color(0xFF172554);
const kGrey = Color(0xFFEEF2F7);
const kRed = Color(0xFFE02020);
const kPink = Color(0xFFFFABBA);
const kPinkDark = Color(0xFFFF7EA8);

const kAppName = 'HADIR';
const kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

// Mood: 0 = Good, 1 = Okay, 2 = Low
const kMoodLabels = ['Good', 'Okay', 'Low'];
const kMoodEmoji = ['😊', '😐', '😔'];
const kMoodIcons = [
  Icons.sentiment_satisfied_alt,
  Icons.sentiment_neutral,
  Icons.sentiment_dissatisfied
];
const kMoodColors = [kBlue, Color(0xFFFFD58A), kPinkDark];

// ───────────────────────── Helper tanggal ─────────────────────────

String two(int n) => n.toString().padLeft(2, '0');
String dayKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

// ───────────────────────── Hati ─────────────────────────

/// Bentuk hati yang mengisi [r].
Path heartPath(Rect r) {
  final w = r.width, h = r.height;
  return Path()
    ..moveTo(r.left + w * 0.5, r.top + h * 0.95)
    ..cubicTo(r.left - w * 0.15, r.top + h * 0.55, r.left + w * 0.05,
        r.top - h * 0.10, r.left + w * 0.5, r.top + h * 0.28)
    ..cubicTo(r.left + w * 0.95, r.top - h * 0.10, r.left + w * 1.15,
        r.top + h * 0.55, r.left + w * 0.5, r.top + h * 0.95)
    ..close();
}

class HeartIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool outline;
  const HeartIcon(
      {super.key, this.size = 24, this.color = kPinkDark, this.outline = false});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _HeartPainter(color, outline));
}

class _HeartPainter extends CustomPainter {
  final Color color;
  final bool outline;
  _HeartPainter(this.color, this.outline);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = outline ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = s.width * 0.1
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(heartPath(Rect.fromLTWH(1, 1, s.width - 2, s.height - 2)), p);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter old) =>
      old.color != color || old.outline != outline;
}

// ───────────────────────── Tombol ─────────────────────────

class BlueButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double height;
  const BlueButton(this.label, this.onTap, {super.key, this.height = 58});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height * 0.38),
          gradient: const LinearGradient(colors: [kBlue, kBlueDark]),
          boxShadow: [
            BoxShadow(
                color: kBlue.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8))
          ],
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class OutlineBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool dashed;
  const OutlineBtn(this.label, this.onTap,
      {super.key, this.icon, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: kBlue.withOpacity(dashed ? 0.5 : 0.6), width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) Icon(icon, color: kBlueDark),
          if (icon != null) const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: kBlueDark, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ───────────────────────── Judul HADIR ─────────────────────────

/// Teks medium berujung bulat. Huruf digambar dua kali (isi + garis tepi
/// bersambungan bulat) sehingga semua sudut membulat, tanpa paket font.
/// Atur ketebalan lewat [weight] (w400-w700) dan kegemukan lewat [puff].
class ChubbyText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight weight;
  final double? puff;
  final double letterSpacing;

  const ChubbyText(
    this.text, {
    super.key,
    this.fontSize = 28,
    this.color = kBlueDark,
    this.weight = FontWeight.w500,
    this.puff,
    this.letterSpacing = 2,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
        fontSize: fontSize, fontWeight: weight, letterSpacing: letterSpacing);
    return Stack(children: [
      Text(text,
          style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = puff ?? fontSize * 0.06
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..color = color)),
      Text(text, style: base.copyWith(color: color)),
    ]);
  }
}
