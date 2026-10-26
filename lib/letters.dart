// Surat penyemangat anonim: layanan kirim, pembatas sesi, arsip, dan halaman surat.
// Letakkan di: lib/letters.dart

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'mascot.dart';

/// Pesan dipilih sistem (bukan diketik pengguna) agar tidak bisa dipakai melecehkan.
const kLetters = [
  "I don't know you, but I hope today is gentle with you.",
  "You've made it through every hard day so far. That's a perfect record.",
  "Someone you've never met is rooting for you.",
  "It's okay if today was just about getting through. That's enough.",
  'You matter more than you think.',
  "Whatever you're carrying, you don't have to carry it alone.",
  'I hope something small and good happens to you today.',
  "Take a breath. You're doing fine.",
  'Your presence makes the world a little warmer.',
  "Be as kind to yourself as you'd be to a good friend.",
  'Tomorrow gets to be a fresh start.',
  "You don't owe anyone a perfect day.",
  'Thank you for being here today.',
  'Rest if you need to. The world can wait a moment.',
  "There's a lot of good ahead of you, even if it's hard to see right now.",
  'You are not a burden. You are someone worth knowing.',
  'Proud of you for checking in today.',
  'I hope you get a good meal and a good night of sleep.',
  "Hard days don't erase the good ones. Hold on to those.",
  'Hi stranger! Sending you a little sunshine ☀️',
];

/// Satu pertukaran surat per kali aplikasi dibuka. Flag ini hidup di memori,
/// jadi otomatis ter-reset saat aplikasi dibuka lagi.
class LetterGate {
  static bool exchanged = false;
}

// ───────────────────────── Layanan kirim ─────────────────────────

abstract class LetterService {
  Future<int> remainingToday();
  Future<bool> send(String message);
}

/// Simulasi lokal agar UI bisa dicoba tanpa server.
/// TODO: ganti dengan backend sungguhan yang memilih penerima acak
/// (hanya pengguna yang menyalakan "Receive waves"), tidak pernah mengirim
/// identitas pengirim, membatasi surat masuk per orang, dan menyediakan
/// tombol laporkan/blokir.
class LocalLetterService implements LetterService {
  static const dailyLimit = 5;

  @override
  Future<int> remainingToday() async {
    final p = await SharedPreferences.getInstance();
    final used =
        p.getString('letterDay') == dayKey(DateTime.now()) ? (p.getInt('letterCount') ?? 0) : 0;
    return math.max(0, dailyLimit - used);
  }

  @override
  Future<bool> send(String message) async {
    if (await remainingToday() <= 0) return false;
    await Future.delayed(const Duration(milliseconds: 1200));
    final p = await SharedPreferences.getInstance();
    final today = dayKey(DateTime.now());
    final used = p.getString('letterDay') == today ? (p.getInt('letterCount') ?? 0) : 0;
    await p.setString('letterDay', today);
    await p.setInt('letterCount', used + 1);
    return true;
  }
}

final LetterService letterService = LocalLetterService();

// ───────────────────────── Arsip surat ─────────────────────────

class SavedLetter {
  final String text;
  final DateTime date;
  SavedLetter(this.text, this.date);
}

class LetterStore {
  static Future<List<SavedLetter>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('savedLetters');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => SavedLetter(e['t'] as String, DateTime.parse(e['d'] as String)))
        .toList();
  }

  static Future<void> save(String text) async {
    final p = await SharedPreferences.getInstance();
    final list = await load();
    list.insert(0, SavedLetter(text, DateTime.now()));
    final kept = list.take(30).toList();
    await p.setString(
        'savedLetters',
        jsonEncode(kept
            .map((e) => {'t': e.text, 'd': e.date.toIso8601String()})
            .toList()));
  }
}

// ───────────────────────── Halaman surat ─────────────────────────

String _fmtDate(DateTime d) => '${kMonths[d.month - 1]} ${d.day}, ${d.year}';

class LetterPage extends StatelessWidget {
  final String text;
  final DateTime date;
  LetterPage({super.key, required this.text, DateTime? date})
      : date = date ?? DateTime.now();

  Widget _paper() {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(32, 46, 32, 26),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 10))
          ],
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _DoodlePainter(text.hashCode))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Dear friend,',
                style: TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: kBlueDark)),
            const SizedBox(height: 18),
            Text(text,
                style: const TextStyle(
                    fontSize: 21, height: 1.65, fontStyle: FontStyle.italic, color: kInk)),
            const SizedBox(height: 26),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('With love,',
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
                  const Text('a stranger on HADIR 💙',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(_fmtDate(date),
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ),
              SizedBox(
                  width: 90,
                  height: 100,
                  child: CustomPaint(painter: _SketchPainter())),
            ]),
          ]),
        ]),
      ),
      Positioned(
        top: -12,
        left: 0,
        right: 0,
        child: Center(
          child: Transform.rotate(
            angle: 0.05,
            child: Container(
              width: 96,
              height: 26,
              decoration: BoxDecoration(
                  color: kPink.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(3)),
            ),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEAF4FF), Color(0xFFFFF0F5)]),
        ),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 60 * (1 - v)),
                        child: Transform.rotate(angle: -0.02 * v, child: child),
                      ),
                    ),
                    child: _paper(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: BlueButton('Thank you, stranger 💙', () => Navigator.pop(context)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Kotak surat (arsip) ─────────────────────────

class LettersArchivePage extends StatelessWidget {
  const LettersArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Letter Box', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: FutureBuilder<List<SavedLetter>>(
          future: LetterStore.load(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final list = snap.data!;
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: const [
                    HadiMascot(size: 150, pose: HadiPose.envelope),
                    SizedBox(height: 16),
                    Text('No letters yet',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text(
                        'Tap Hadi on the home screen a few times. He might have a letter for you.',
                        textAlign: TextAlign.center),
                  ]),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final l = list[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LetterPage(text: l.text, date: l.date))),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: kBlueSoft, borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      const Text('💌', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_fmtDate(l.date),
                              style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(l.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────── Gambar sketsa ─────────────────────────

class _DoodlePainter extends CustomPainter {
  final int seed;
  _DoodlePainter(this.seed);

  void _star(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(o.dx + rad * math.cos(a), o.dy + rad * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, p);
  }

  void _sparkle(Canvas c, Offset o, double s, Paint p) {
    c.drawLine(o + Offset(-s, 0), o + Offset(s, 0), p);
    c.drawLine(o + Offset(0, -s), o + Offset(0, s), p);
  }

  void _flower(Canvas c, Offset o, double r, Paint p) {
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * 1.1, r, p);
    }
    c.drawCircle(o, r * 0.5, p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);

    // Bingkai putus-putus
    final border = Paint()
      ..color = kPink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), const Radius.circular(10)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 7, m.length)), border);
        d += 13;
      }
    }

    // Coretan di tepi kiri dan kanan
    const n = 9;
    for (var i = 0; i < n; i++) {
      final left = i.isEven;
      final x = left ? 14 + rnd.nextDouble() * 14 : size.width - 30 + rnd.nextDouble() * 14;
      final y = size.height * (0.07 + 0.86 * i / (n - 1)) + rnd.nextDouble() * 8;
      final s = 10 + rnd.nextDouble() * 9;
      final color = (i % 3 == 0 ? kPinkDark : (i % 3 == 1 ? kMascotBlue : kBlue)).withOpacity(0.75);
      final pen = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final o = Offset(x, y);
      switch (rnd.nextInt(5)) {
        case 0:
          canvas.drawPath(
              heartPath(Rect.fromCenter(center: o, width: s * 1.4, height: s * 1.3)), pen);
          break;
        case 1:
          _star(canvas, o, s, pen);
          break;
        case 2:
          _sparkle(canvas, o, s, pen);
          break;
        case 3:
          _flower(canvas, o, s * 0.5, pen);
          break;
        default:
          final dot = Paint()..color = color;
          for (var k = -1; k <= 1; k++) {
            canvas.drawCircle(o + Offset(k * s * 0.7, 0), 1.8, dot);
          }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter old) => old.seed != seed;
}

/// Sketsa garis Hadi melambai, digambar seperti coretan pena.
class _SketchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final pen = Paint()
      ..color = kMascotBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // kepala
    canvas.drawCircle(const Offset(50, 30), 21, pen);
    // mata + senyum
    final dot = Paint()..color = kMascotBlue;
    canvas.drawCircle(const Offset(43, 29), 2.4, dot);
    canvas.drawCircle(const Offset(57, 29), 2.4, dot);
    canvas.drawPath(
        Path()
          ..moveTo(44, 38)
          ..quadraticBezierTo(50, 44, 56, 38),
        pen);
    // badan
    canvas.drawPath(
        Path()
          ..moveTo(20, 100)
          ..cubicTo(21, 72, 33, 54, 50, 54)
          ..cubicTo(67, 54, 79, 72, 80, 100),
        pen);
    // tangan melambai
    canvas.drawPath(
        Path()
          ..moveTo(72, 66)
          ..quadraticBezierTo(90, 56, 94, 36),
        pen);
    // hati kecil di dada
    canvas.drawPath(
        heartPath(const Rect.fromLTWH(43, 66, 14, 13)),
        Paint()
          ..color = kPinkDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
