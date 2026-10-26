// Hadi di halaman utama: pose dan kalimat acak saat dipencet. Bila dipencet
// berkali-kali ia pergi 10 detik, lalu kembali membawa surat untukmu.
// Letakkan di: lib/hadi_companion.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'letters.dart';
import 'mascot.dart';

class HadiChat {
  final HadiPose pose;
  final String text;
  const HadiChat(this.pose, this.text);
}

/// Semua kalimat orisinal, tanpa atribusi tokoh.
const kHadiChats = [
  HadiChat(HadiPose.wave, "Hi, I'm Hadi! I'm here every time you check in. 👋"),
  HadiChat(HadiPose.wave, 'Hope you have a lovely day! ☀️'),
  HadiChat(HadiPose.wave, 'Hello again! I never get tired of saying hi.'),
  HadiChat(HadiPose.cheer, 'You showed up today. That already counts! 🎉'),
  HadiChat(HadiPose.cheer, 'Small steps still move you forward!'),
  HadiChat(HadiPose.cheer, 'Look at you, doing your best! Yay!'),
  HadiChat(HadiPose.cheer, 'Hadi is so proud of you! 🥳'),
  HadiChat(HadiPose.heart, 'Sending you a really big heart 💙'),
  HadiChat(HadiPose.heart, "You don't have to be perfect to be loved."),
  HadiChat(HadiPose.heart, 'Your feelings are valid, even the messy ones.'),
  HadiChat(HadiPose.heart, 'Be gentle with yourself today.'),
  HadiChat(HadiPose.heart, 'If today feels heavy, talking to someone can help.'),
  HadiChat(HadiPose.think, 'Hmm… thinking very hard… what snack should I have? 🤔'),
  HadiChat(HadiPose.think, 'Let me think… did you drink water today? 💧'),
  HadiChat(HadiPose.think, 'Calculating how awesome you are… error: too much!'),
  HadiChat(HadiPose.think, 'If clouds are fluffy, are they soft to sit on?'),
  HadiChat(HadiPose.envelope, "I'm practicing my mail delivery. Letters are my thing ✉️"),
  HadiChat(HadiPose.envelope, 'Psst… someone might write to you soon.'),
  HadiChat(HadiPose.envelope, "I'm saving a special letter, just in case."),
  HadiChat(HadiPose.down, 'Just standing here, being supportive. 🧍'),
  HadiChat(HadiPose.down, 'Take a slow breath in… and out.'),
  HadiChat(HadiPose.down, 'Stretch your shoulders for a moment!'),
  HadiChat(HadiPose.down, 'Resting is not quitting.'),
];

enum _Phase { here, leaving, away, carrying }

class HadiCompanion extends StatefulWidget {
  const HadiCompanion({super.key});

  @override
  State<HadiCompanion> createState() => _HadiCompanionState();
}

class _HadiCompanionState extends State<HadiCompanion> {
  static const _tapsBeforeLeaving = 6;
  static const _awaySeconds = 30;

  final _key = GlobalKey<HadiMascotState>();
  final _rng = math.Random();
  final List<HadiChat> _bag = [];

  _Phase _phase = _Phase.here;
  HadiPose _pose = HadiPose.wave;
  String _msg = "Hi, I'm Hadi! 👋";
  int _taps = 0;
  Timer? _decay;
  Timer? _countdownTimer;
  bool _slideOut = false;

  int _countdown = _awaySeconds;
  bool _sending = false;
  String? _note;
  String _letter = '';

  @override
  void dispose() {
    _decay?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  HadiChat _nextChat() {
    if (_bag.isEmpty) {
      _bag.addAll(kHadiChats);
      _bag.shuffle(_rng);
    }
    return _bag.removeLast();
  }

  void _onTap() {
    if (_phase == _Phase.carrying) {
      _openLetter();
      return;
    }
    if (_phase != _Phase.here) return;

    _key.currentState?.waveOnce();
    HapticFeedback.selectionClick();

    _taps++;
    _decay?.cancel();
    _decay = Timer(const Duration(seconds: 5), () => _taps = 0);

    if (_taps >= _tapsBeforeLeaving) {
      _taps = 0;
      if (LetterGate.exchanged) {
        setState(() {
          _pose = HadiPose.heart;
          _msg = "I already delivered a letter this time! Open the app again later and I'll have another 💙";
        });
      } else {
        _leave();
      }
      return;
    }
    final c = _nextChat();
    setState(() {
      _pose = c.pose;
      _msg = c.text;
    });
  }

  Future<void> _leave() async {
    _decay?.cancel();
    setState(() {
      _phase = _Phase.leaving;
      _pose = HadiPose.wave;
      _msg = "Okay okay, I need a break! Wait for me, I'll be back in $_awaySeconds seconds! 💨";
    });
    _key.currentState?.waveOnce();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _slideOut = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _phase = _Phase.away;
      _countdown = _awaySeconds;
      _sending = false;
      _note = null;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        _comeBackWithLetter();
        return;
      }
      setState(() => _countdown--);
    });
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final ok = await letterService.send(kLetters[_rng.nextInt(kLetters.length)]);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _note = ok
          ? 'Letter sent 💌 It is on its way to a stranger. They will never know it was you.'
          : "Couldn't send right now. Maybe next time!";
    });
  }

  Future<void> _comeBackWithLetter() async {
    _letter = kLetters[_rng.nextInt(kLetters.length)];
    setState(() {
      _phase = _Phase.carrying;
      _pose = HadiPose.envelope;
      _slideOut = true;
      _msg = 'Tap me! A letter for you from someone out there 💌';
    });
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    setState(() => _slideOut = false);
  }

  Future<void> _openLetter() async {
    LetterGate.exchanged = true;
    await LetterStore.save(_letter);
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => LetterPage(text: _letter)));
    if (!mounted) return;
    setState(() {
      _phase = _Phase.here;
      _pose = HadiPose.heart;
      _msg = 'Hope that made you smile 💙';
    });
  }

  // ── tampilan ──

  Widget _bubble() {
    final highlight = _phase == _Phase.carrying;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(_msg),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kBlueSoft,
          borderRadius: BorderRadius.circular(18),
          border: highlight ? Border.all(color: kBlue, width: 2) : null,
        ),
        child: Text(_msg, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
      ),
    );
  }

  Widget _hadiRow() {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Flexible(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240), child: _bubble()),
      ),
      const SizedBox(width: 8),
      AnimatedSlide(
        offset: _slideOut ? const Offset(1.9, 0) : Offset.zero,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _slideOut ? 0 : 1,
          duration: const Duration(milliseconds: 550),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            child: HadiMascot(key: _key, size: 96, pose: _pose),
          ),
        ),
      ),
    ]);
  }

  Widget _awayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBlueSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBlue, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Hadi is off delivering letters 💌',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text('${_countdown}s',
                style: const TextStyle(fontWeight: FontWeight.w800, color: kBlueDark)),
          ),
        ]),
        const SizedBox(height: 6),
        const Text(
            "He'll be back soon with something for you. Want to send a little encouragement to a stranger while you wait? "
            'We choose the message and the person. They will never know it was you.',
            style: TextStyle(height: 1.4)),
        const SizedBox(height: 14),
        if (_note != null)
          Text(_note!, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4))
        else
          BlueButton(_sending ? 'Sending…' : 'Send anonymous letter',
              _sending ? () {} : _send),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        child: _phase == _Phase.away ? _awayCard() : _hadiRow(),
      ),
    );
  }
}
