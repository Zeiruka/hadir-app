// Emotional screening module for HADIR.
// Place at: lib/screening_screens.dart
// Requires: lib/models/models.dart, lib/data/question_bank.dart,
//           lib/services/scoring.dart (created earlier).
// No new dependencies.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/question_bank.dart';
import 'app_theme.dart';
import 'models/models.dart';
import 'services/scoring.dart';

const _kRedSoft = Color(0xFFFDECEC);

// ----- Button on the main menu -----

/// Square button to place at the bottom of HomeScreen.
class ScreeningEntryButton extends StatelessWidget {
  const ScreeningEntryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScreeningIntroPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kBlueSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kBlue, width: 1.5),
        ),
        child: Row(children: const [
          Icon(Icons.favorite_border, color: kBlueDark, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Emotional Wellbeing Check',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Anxiety, fear of loss, loneliness, and personal safety. '
                  '100 questions, your answers are not saved.',
                  style: TextStyle(fontSize: 14, height: 1.35)),
            ]),
          ),
          Icon(Icons.chevron_right),
        ]),
      ),
    );
  }
}

// ----- Crisis contact card -----

class CrisisCard extends StatelessWidget {
  final bool emphasize;
  const CrisisCard({super.key, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emphasize ? _kRedSoft : kGrey,
        borderRadius: BorderRadius.circular(18),
        border: emphasize ? Border.all(color: kRed, width: 1.5) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Need help right now?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final r in crisisResources)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${r.name}: ${r.contact}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(r.note),
            trailing: r.contact == '-'
                ? null
                : IconButton(
                    tooltip: 'Copy number',
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: r.contact));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Number copied')));
                    },
                  ),
          ),
      ]),
    );
  }
}

// ----- Intro page -----

class ScreeningIntroPage extends StatelessWidget {
  const ScreeningIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Emotional Wellbeing Check',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Before you start',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            'There are ${questionBank.length} questions about your daily activities, anxiety, '
            'fear of loss, loneliness, and safety. It takes about 15 minutes. '
            'Answer honestly, there are no right or wrong answers. You may '
            'skip any question and stop at any time.',
            style: const TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 12),
          const Text(
            'This is a screening tool, not a diagnosis and not a replacement for '
            'a psychologist or psychiatrist. Your answers are not saved and are '
            'not sent to your emergency contacts.',
            style: TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 20),
          const CrisisCard(),
          const SizedBox(height: 24),
          BlueButton(
            'I understand, start',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuestionnairePage()),
            ),
          ),
        ]),
      ),
    );
  }
}

// ----- Questionnaire -----

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  int _index = 0;
  final Map<String, int> _answers = {};
  bool _safetyShown = false;

  Question get _q => questionBank[_index];

  bool get _isFirstOfDomain =>
      _index == 0 || questionBank[_index - 1].domain != _q.domain;

  void _select(int value) {
    setState(() => _answers[_q.id] = value);
    if (_q.critical && value > 0 && !_safetyShown) {
      _safetyShown = true;
      _showSafetySheet();
    }
  }

  void _showSafetySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thank you for being honest',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                "What you are feeling is real, and you don't have to face it "
                'alone. You can reach out to the help below at any time, even '
                'before you finish the questions.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 12),
              const CrisisCard(emphasize: true),
              const SizedBox(height: 16),
              BlueButton('Continue questions', () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    );
  }

  void _next() {
    if (_index < questionBank.length - 1) {
      setState(() => _index++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultPage(answers: _answers)),
      );
    }
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    final selected = _answers[q.id];
    final last = _index == questionBank.length - 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('${_index + 1} / ${questionBank.length}',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_index + 1) / questionBank.length,
            minHeight: 6,
            color: kBlue,
            backgroundColor: kGrey,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Emergency help',
            icon: const Icon(Icons.support_agent, color: kBlueDark),
            onPressed: _showSafetySheet,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(q.domain.label,
              style: const TextStyle(
                  color: kBlueDark, fontSize: 15, fontWeight: FontWeight.w800)),
          if (_isFirstOfDomain) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: kBlueSoft, borderRadius: BorderRadius.circular(16)),
              child: Text(q.domain.intro, style: const TextStyle(height: 1.4)),
            ),
          ],
          const SizedBox(height: 18),
          Text(q.prompt, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(q.text,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
          const SizedBox(height: 22),
          for (final o in q.options)
            _OptionTile(
              label: o.label,
              selected: selected == o.value,
              onTap: () => _select(o.value),
            ),
          const SizedBox(height: 16),
          Row(children: [
            TextButton(
              onPressed: _index > 0 ? _back : null,
              child: const Text('Back', style: TextStyle(color: kInk)),
            ),
            TextButton(
              onPressed: _next,
              child: const Text('Skip', style: TextStyle(color: kInk)),
            ),
            const Spacer(),
            SizedBox(
              width: 140,
              child: IgnorePointer(
                ignoring: selected == null,
                child: Opacity(
                  opacity: selected == null ? 0.4 : 1,
                  child: BlueButton(last ? 'Finish' : 'Next', _next),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? kBlueSoft : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? kBlue : kGrey, width: 2),
          ),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
            ),
            if (selected) const Icon(Icons.check_circle, color: kBlueDark),
          ]),
        ),
      ),
    );
  }
}

// ----- Results -----

class ResultPage extends StatelessWidget {
  final Map<String, int> answers;
  const ResultPage({super.key, required this.answers});

  @override
  Widget build(BuildContext context) {
    final r = Scoring.evaluate(answers);
    final urgent = r.level == RiskLevel.high || r.level == RiskLevel.imminent;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Screening results',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          if (urgent) ...[
            const CrisisCard(emphasize: true),
            const SizedBox(height: 18),
          ],
          Text(Scoring.title(r.level),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 10),
          Text(Scoring.message(r.level),
              style: const TextStyle(fontSize: 16, height: 1.45)),
          if (r.skippedCritical > 0) ...[
            const SizedBox(height: 10),
            Text(
              'You skipped ${r.skippedCritical} safety questions, so '
              'this result may not fully reflect how you are doing.',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 28),
          const Text('Summary by section',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final d in r.domains.where((d) => d.max > 0))
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.protective
                    ? '${d.domain.label} (higher is better)'
                    : d.domain.label),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: d.shownPercent / 100,
                    minHeight: 10,
                    color: d.protective ? kBlue : kBlueDark,
                    backgroundColor: kGrey,
                  ),
                ),
              ]),
            ),
          if (!urgent) ...[
            const SizedBox(height: 10),
            const CrisisCard(),
          ],
          const SizedBox(height: 16),
          const Text(
            'This result is not a diagnosis. Only a psychologist or psychiatrist '
            'can assess your condition thoroughly.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 20),
          BlueButton('Back to main menu',
              () => Navigator.of(context).popUntil((route) => route.isFirst)),
        ]),
      ),
    );
  }
}
