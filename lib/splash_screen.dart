// Splash / loading screen HADIR.
// Alur: fade in -> jeda singkat -> Hadi mengangkat tangan dan melambai dua kali
//       -> diam beberapa detik -> pindah (fade) ke aplikasi.
// Letakkan di: lib/splash_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'mascot.dart';

class SplashGate extends StatefulWidget {
  final Widget Function() next;
  const SplashGate({super.key, required this.next});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: _done
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.next())
          : SplashScreen(
              key: const ValueKey('splash'),
              onFinished: () => setState(() => _done = true),
            ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _word = 'HADIR';

  final _mascotKey = GlobalKey<HadiMascotState>();
  late final AnimationController _intro;
  late final Animation<double> _mascotFade;
  late final Animation<double> _tagline;
  late final List<Animation<double>> _letters;

  HadiPose _pose = HadiPose.down;
  bool _still = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700));

    _mascotFade = CurvedAnimation(
        parent: _intro, curve: const Interval(0.0, 0.45, curve: Curves.easeOut));
    _letters = List.generate(_word.length, (i) {
      final start = 0.30 + i * 0.08;
      return CurvedAnimation(
          parent: _intro,
          curve: Interval(start, start + 0.20, curve: Curves.easeOutCubic));
    });
    _tagline = CurvedAnimation(
        parent: _intro, curve: const Interval(0.78, 1.0, curve: Curves.easeOut));

    _intro.forward().whenComplete(_afterFade);
  }

  Future<void> _afterFade() async {
    await Future.delayed(const Duration(milliseconds: 300)); // jeda setelah fade in
    if (!mounted) return;
    setState(() => _pose = HadiPose.wave); // angkat tangan
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    _mascotKey.currentState
        ?.waveOnce(duration: const Duration(milliseconds: 1500)); // lambai dua kali
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    setState(() => _still = true); // diam dengan tangan terangkat
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FadeTransition(
            opacity: _mascotFade,
            child: HadiMascot(
                key: _mascotKey, size: 240, pose: _pose, animate: !_still),
          ),
          const SizedBox(height: 30),
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < _word.length; i++)
              FadeTransition(
                opacity: _letters[i],
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.5), end: Offset.zero)
                      .animate(_letters[i]),
                  child: ChubbyText(_word[i], fontSize: 52, letterSpacing: 5),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _tagline,
            child: const Text('Stay connected with your loved ones',
                style: TextStyle(fontSize: 15, color: kInk)),
          ),
          const SizedBox(height: 36),
          FadeTransition(opacity: _tagline, child: const _LoadingDots()),
        ]),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kBlue.withOpacity(0.25 +
                  0.75 * (0.5 + 0.5 * math.sin(2 * math.pi * (_c.value - i / 3)))),
            ),
          ),
      ]),
    );
  }
}
