import '../data/question_bank.dart';
import '../models/models.dart';

enum RiskLevel { low, mild, moderate, high, imminent }

class CrisisResource {
  final String name;
  final String contact;
  final String note;
  const CrisisResource(this.name, this.contact, this.note);
}

/// Make sure these numbers are re-verified before release.
/// NOTE: these are Indonesian services. If your users are in another country,
/// replace them with that country's emergency and crisis numbers.
const crisisResources = [
  CrisisResource('Emergency services', '112', 'If there is immediate danger to life.'),
  CrisisResource('Ministry of Health mental health service', '119 ext. 8', 'Mental health crisis counseling.'),
  CrisisResource('Nearest ER / hospital', '-', 'Go in person and ask someone you trust to come with you.'),
];

class DomainResult {
  final Domain domain;
  final int score;
  final int max;
  const DomainResult(this.domain, this.score, this.max);

  bool get protective => domain == Domain.pelindung;
  double get riskPercent => max == 0 ? 0 : score / max * 100;

  /// For the protective domain this is shown as a strength (inverted).
  double get shownPercent => protective ? 100 - riskPercent : riskPercent;
}

class AssessmentResult {
  final RiskLevel level;
  final List<DomainResult> domains;
  final double distressPercent;
  final List<Question> flagged;
  final int skippedCritical;
  const AssessmentResult(
    this.level,
    this.domains,
    this.distressPercent,
    this.flagged,
    this.skippedCritical,
  );
}

class Scoring {
  /// The thresholds below are a starting point. A clinical psychologist must
  /// calibrate and validate them before real-world use.
  static AssessmentResult evaluate(Map<String, int> answers) {
    int v(String id) => answers[id] ?? 0;
    bool yes(String id) => v(id) > 0;

    final domainResults = <DomainResult>[];
    for (final d in Domain.values) {
      var score = 0;
      var max = 0;
      for (final q in questionBank.where((q) => q.domain == d)) {
        final a = answers[q.id];
        if (a == null) continue;
        score += q.reverse ? 3 - a : a;
        max += 3;
      }
      domainResults.add(DomainResult(d, score, max));
    }

    final distress = domainResults.where((r) => !r.protective);
    final dScore = distress.fold<int>(0, (s, r) => s + r.score);
    final dMax = distress.fold<int>(0, (s, r) => s + r.max);
    final distressPercent = dMax == 0 ? 0.0 : dScore / dMax * 100;

    final ideation = questionBank
        .where((q) => q.domain == Domain.pikiranBunuhDiri)
        .any((q) => yes(q.id));

    final imminent = yes('I09') || yes('I10') || (yes('I02') && yes('I03'));

    final high = const ['I01', 'I02', 'I03', 'I04', 'I06'].any(yes) ||
        const ['H03', 'H04', 'H05', 'H09'].any((id) => v(id) >= 2) ||
        (yes('I07') && ideation);

    final moderate = ideation ||
        yes('I07') ||
        yes('I05') ||
        v('F08') >= 2 ||
        v('F09') >= 2 ||
        v('F10') >= 2;

    final RiskLevel level;
    if (imminent) {
      level = RiskLevel.imminent;
    } else if (high) {
      level = RiskLevel.high;
    } else if (moderate) {
      level = RiskLevel.moderate;
    } else if (distressPercent >= 33) {
      level = RiskLevel.mild;
    } else {
      level = RiskLevel.low;
    }

    final flagged = questionBank
        .where((q) => q.critical && (answers[q.id] ?? 0) > 0)
        .toList();
    final skipped = questionBank
        .where((q) => q.critical && !answers.containsKey(q.id))
        .length;

    return AssessmentResult(level, domainResults, distressPercent, flagged, skipped);
  }

  static String title(RiskLevel l) => switch (l) {
        RiskLevel.low => 'Low emotional distress',
        RiskLevel.mild => 'Mild emotional distress',
        RiskLevel.moderate => 'Needs attention and support',
        RiskLevel.high => 'It would be best to talk to a professional soon',
        RiskLevel.imminent => 'Your safety is the priority right now',
      };

  static String message(RiskLevel l) => switch (l) {
        RiskLevel.low =>
          'Your answers suggest low distress. Keep up your routines, your sleep, and your connections with the people close to you.',
        RiskLevel.mild =>
          'There are signs of anxiety or loneliness worth paying attention to. Talking to someone you trust or a counselor can help before the burden grows.',
        RiskLevel.moderate =>
          'You are carrying a heavy load, and there are thoughts or signs worth talking about. We suggest scheduling a session with a psychologist or psychiatrist soon.',
        RiskLevel.high =>
          'Your answers point to serious thoughts or preparations related to your safety. Please contact a crisis service or a mental health professional today, and do not face this alone.',
        RiskLevel.imminent =>
          'If you feel you might act soon, call 112 or go to the nearest emergency room right now. Ask someone to stay with you, and keep away anything that could hurt you.',
      };
}
