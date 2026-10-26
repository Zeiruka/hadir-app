/// Data models for the screening of anxiety, loneliness, fear of loss,
/// and suicide risk.

enum AnswerScale { frequency, yesNo }

class AnswerOption {
  final String label;
  final int value;
  const AnswerOption(this.label, this.value);
}

const _frequencyOptions = [
  AnswerOption('Not at all', 0),
  AnswerOption('Several days', 1),
  AnswerOption('More than half the days', 2),
  AnswerOption('Nearly every day', 3),
];

const _yesNoOptions = [
  AnswerOption('No', 0),
  AnswerOption('Yes', 3),
];

/// 10 domains x 10 questions = 100 questions.
/// The order deliberately moves from light to sensitive topics (the pattern
/// of a clinical interview) and closes with protective factors, so the
/// session ends on something reinforcing.
///
/// NOTE: the enum names (aktivitas, tubuh, ...) are kept as-is so other files
/// that reference them (scoring.dart, screening_screens.dart) keep working.
enum Domain {
  aktivitas(
    'Daily activities',
    'This section is about how you have been getting through your days lately.',
  ),
  tubuh(
    'Sleep, eating, and physical health',
    'Emotional stress is often felt in the body. Answer honestly.',
  ),
  cemas(
    'Anxiety',
    'This section is about feeling anxious, tense, and worried.',
  ),
  kehilangan(
    'Fear of loss',
    'This section is about fear or grief over losing something '
        'or someone important.',
  ),
  kesepian(
    'Loneliness',
    'This section is about feeling connected to, or cut off from, other people.',
  ),
  suasanaHati(
    'Mood and self-view',
    'This section is about how you feel about yourself and your future.',
  ),
  sosial(
    'Social relationships and life events',
    'This section is about the people around you and any hard events '
        'you may have gone through.',
  ),
  pikiranBunuhDiri(
    'Thoughts about death and self-harm',
    'The next section asks about heavy and sensitive matters. Asking '
        'does not increase risk, and your honest answers help us '
        'suggest the right support. You may skip any question.',
  ),
  rencanaBunuhDiri(
    'Plans, intent, and safety',
    'The following questions help assess how urgently you may need '
        'support. There are no wrong answers.',
  ),
  pelindung(
    'Strengths and sources of support',
    'The last section is about the things that help you keep going.',
  );

  final String label;
  final String intro;
  const Domain(this.label, this.intro);
}

class Question {
  final String id;
  final Domain domain;
  final String text;
  final AnswerScale scale;

  /// true for positive statements (protective factors): a high value = low risk.
  final bool reverse;

  /// true when any answer > 0 must trigger the safety protocol.
  final bool critical;

  const Question(
    this.id,
    this.domain,
    this.text, {
    this.scale = AnswerScale.frequency,
    this.reverse = false,
    this.critical = false,
  });

  List<AnswerOption> get options =>
      scale == AnswerScale.yesNo ? _yesNoOptions : _frequencyOptions;

  String get prompt => scale == AnswerScale.yesNo
      ? 'Answer according to your situation.'
      : 'Over the last 2 weeks, how often does this statement apply to you?';
}
