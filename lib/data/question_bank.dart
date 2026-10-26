import '../models/models.dart';

const _yn = AnswerScale.yesNo;

/// Bank of 100 questions (original, written with reference to the domains of
/// common instruments: PHQ-9, GAD-7, C-SSRS, loneliness scales, and suicide
/// risk/protective factors).
/// MUST be reviewed and validated by a licensed clinical psychologist before release.
const List<Question> questionBank = [
  // A. Daily activities
  Question('A01', Domain.aktivitas, 'I have lost interest or pleasure in activities I usually enjoy.'),
  Question('A02', Domain.aktivitas, 'I find it hard to start basic routines like showering, changing clothes, or making my bed.'),
  Question('A03', Domain.aktivitas, 'I put off or avoid work, school, or daily responsibilities.'),
  Question('A04', Domain.aktivitas, 'I have trouble concentrating when working, studying, or reading.'),
  Question('A05', Domain.aktivitas, 'I spend most of the day just lying down or sitting without doing anything.'),
  Question('A06', Domain.aktivitas, 'I have stopped doing hobbies I used to enjoy.'),
  Question('A07', Domain.aktivitas, 'Daily activities feel too heavy to get through.'),
  Question('A08', Domain.aktivitas, 'I neglect my personal hygiene or the cleanliness of my home.'),
  Question('A09', Domain.aktivitas, 'I find it hard to make simple decisions, such as choosing food or clothes.'),
  Question('A10', Domain.aktivitas, 'I feel I have no energy to finish the things that need to be done.'),

  // B. Sleep, eating, and physical health
  Question('B01', Domain.tubuh, 'I have trouble falling asleep at night.'),
  Question('B02', Domain.tubuh, "I wake up too early and can't get back to sleep."),
  Question('B03', Domain.tubuh, 'I sleep much longer than usual but still feel tired.'),
  Question('B04', Domain.tubuh, 'My appetite has decreased, or I forget to eat.'),
  Question('B05', Domain.tubuh, 'I overeat to calm my feelings.'),
  Question('B06', Domain.tubuh, 'My body feels tired even though I have rested enough.'),
  Question('B07', Domain.tubuh, 'I have headaches, muscle pain, or stomach problems with no clear medical cause.'),
  Question('B08', Domain.tubuh, 'My heart pounds, my breathing feels tight, or my hands shake when I think about my problems.'),
  Question('B09', Domain.tubuh, 'I have reduced my physical activity or rarely leave the house.'),
  Question('B10', Domain.tubuh, 'I use alcohol, cigarettes, drugs, or other means excessively to ease my feelings.'),

  // C. Anxiety
  Question('C01', Domain.cemas, 'I feel nervous, anxious, or on edge.'),
  Question('C02', Domain.cemas, 'I cannot stop or control my worrying.'),
  Question('C03', Domain.cemas, 'I worry too much about too many things at once.'),
  Question('C04', Domain.cemas, 'I have trouble relaxing.'),
  Question('C05', Domain.cemas, 'I am so restless that it is hard to sit still.'),
  Question('C06', Domain.cemas, 'I get easily annoyed or irritable.'),
  Question('C07', Domain.cemas, 'I feel afraid, as if something bad might happen.'),
  Question('C08', Domain.cemas, 'I have panic attacks, which are sudden episodes of intense fear.'),
  Question('C09', Domain.cemas, 'Repetitive thoughts make it hard for me to calm down, especially at night.'),
  Question('C10', Domain.cemas, 'I avoid certain places or situations because of anxiety.'),

  // D. Fear of loss
  Question('D01', Domain.kehilangan, 'I am afraid of being abandoned by people close to me.'),
  Question('D02', Domain.kehilangan, 'I get very anxious when a loved one is slow to reply to messages or calls.'),
  Question('D03', Domain.kehilangan, 'I am afraid of losing my job, income, or home.'),
  Question('D04', Domain.kehilangan, 'I am afraid that someone I love will become seriously ill or die.'),
  Question('D05', Domain.kehilangan, 'I keep thinking about a loss that has already happened, whether a person, a relationship, or a job.'),
  Question('D06', Domain.kehilangan, 'I sacrifice my own needs to keep a relationship.'),
  Question('D07', Domain.kehilangan, 'I feel I am about to lose everything that matters to me.'),
  Question('D08', Domain.kehilangan, "I find it hard to accept a separation or someone's departure."),
  Question('D09', Domain.kehilangan, 'I am convinced people will leave because I am not valuable enough.'),
  Question('D10', Domain.kehilangan, 'The sense of loss is so strong that it interferes with my activities.'),

  // E. Loneliness
  Question('E01', Domain.kesepian, 'I feel lonely.'),
  Question('E02', Domain.kesepian, 'I feel that no one truly understands me.'),
  Question('E03', Domain.kesepian, 'I feel isolated, even when I am among many people.'),
  Question('E04', Domain.kesepian, 'I feel that I have no close friends.'),
  Question('E05', Domain.kesepian, 'I feel there is no one I can reach out to when I need help.'),
  Question('E06', Domain.kesepian, 'I feel abandoned or forgotten.'),
  Question('E07', Domain.kesepian, 'I spend more time alone than I would like.'),
  Question('E08', Domain.kesepian, "I feel that I don't belong to any group."),
  Question('E09', Domain.kesepian, 'I feel that my relationships with others are only superficial.'),
  Question('E10', Domain.kesepian, 'I feel that this loneliness will never change.'),

  // F. Mood and self-view
  Question('F01', Domain.suasanaHati, 'I feel sad, gloomy, or empty.'),
  Question('F02', Domain.suasanaHati, 'I feel hopeless about the future.'),
  Question('F03', Domain.suasanaHati, 'I feel like a failure or that I have let my family down.'),
  Question('F04', Domain.suasanaHati, 'I feel that I am worthless.'),
  Question('F05', Domain.suasanaHati, 'I blame myself excessively.'),
  Question('F06', Domain.suasanaHati, 'I cry easily for no clear reason, or I feel numb instead.'),
  Question('F07', Domain.suasanaHati, 'I feel that things will never get better.'),
  Question('F08', Domain.suasanaHati, 'I feel that I am a burden to others.'),
  Question('F09', Domain.suasanaHati, 'I feel trapped in a situation with no way out.'),
  Question('F10', Domain.suasanaHati, 'I feel very tired of living.'),

  // G. Social relationships and life events
  Question('G01', Domain.sosial, 'I avoid meeting friends or family.'),
  Question('G02', Domain.sosial, "I don't reply to messages or calls from people who care about me."),
  Question('G03', Domain.sosial, 'I withdraw from group activities, such as worship, community, or family gatherings.'),
  Question('G04', Domain.sosial, 'I find it hard to tell others how I feel.'),
  Question('G05', Domain.sosial, 'I am going through serious arguments or conflicts with family, a partner, or colleagues.'),
  Question('G06', Domain.sosial, "I feel that the people around me don't care."),
  Question('G07', Domain.sosial, 'I am experiencing bullying, threats, or violence from others.'),
  Question('G08', Domain.sosial, 'I feel ashamed or afraid of being judged if I ask for help.'),
  Question('G09', Domain.sosial, 'I interact mostly through screens rather than face to face, and I feel unsatisfied.'),
  Question('G10', Domain.sosial, 'I have recently gone through something hard, such as a breakup, the death of someone close, losing a job, or money problems.'),

  // H. Thoughts about death and self-harm (critical)
  Question('H01', Domain.pikiranBunuhDiri, 'I wish I could go to sleep and not wake up.', critical: true),
  Question('H02', Domain.pikiranBunuhDiri, 'I think I would be better off not alive.', critical: true),
  Question('H03', Domain.pikiranBunuhDiri, 'I have thoughts of ending my own life.', critical: true),
  Question('H04', Domain.pikiranBunuhDiri, 'Thoughts of suicide come up again and again.', critical: true),
  Question('H05', Domain.pikiranBunuhDiri, 'I find it hard to control or stop thoughts about ending my life.', critical: true),
  Question('H06', Domain.pikiranBunuhDiri, 'I imagine that others would be better off without me.', critical: true),
  Question('H07', Domain.pikiranBunuhDiri, 'I have urges to hurt myself without intending to end my life.', critical: true),
  Question('H08', Domain.pikiranBunuhDiri, 'I deliberately hurt myself when I am very distressed.', critical: true),
  Question('H09', Domain.pikiranBunuhDiri, 'I think about when or where I would end my life.', critical: true),
  Question('H10', Domain.pikiranBunuhDiri, 'I dream or imagine about my own death.', critical: true),

  // I. Plans, intent, and safety (critical, Yes/No)
  Question('I01', Domain.rencanaBunuhDiri, 'In the past 3 months, I have thought about a specific way to end my life.', scale: _yn, critical: true),
  Question('I02', Domain.rencanaBunuhDiri, 'In the past 3 months, I have intended to actually do it.', scale: _yn, critical: true),
  Question('I03', Domain.rencanaBunuhDiri, 'I have made a detailed plan, such as a time or place.', scale: _yn, critical: true),
  Question('I04', Domain.rencanaBunuhDiri, 'I have made preparations, such as writing a goodbye note, giving away belongings, or putting my affairs in order.', scale: _yn, critical: true),
  Question('I05', Domain.rencanaBunuhDiri, 'I have access to something I could use to harm myself.', scale: _yn, critical: true),
  Question('I06', Domain.rencanaBunuhDiri, 'In the past 3 months, I started to act to end my life but stopped or was stopped.', scale: _yn, critical: true),
  Question('I07', Domain.rencanaBunuhDiri, 'In my lifetime, I have attempted to end my own life.', scale: _yn, critical: true),
  Question('I08', Domain.rencanaBunuhDiri, 'A family member or close friend of mine died by suicide.', scale: _yn, critical: true),
  Question('I09', Domain.rencanaBunuhDiri, 'I feel I might act soon, today or in the next few days.', scale: _yn, critical: true),
  Question('I10', Domain.rencanaBunuhDiri, 'Right now I feel unable to keep myself safe.', scale: _yn, critical: true),

  // J. Strengths and sources of support (reverse-scored)
  Question('J01', Domain.pelindung, 'I have reasons to keep living, such as family, pets, goals, or beliefs.', reverse: true),
  Question('J02', Domain.pelindung, 'There is at least one person I can reach out to when I feel very distressed.', reverse: true),
  Question('J03', Domain.pelindung, 'I am willing to talk to a psychologist, counselor, or health professional.', reverse: true),
  Question('J04', Domain.pelindung, 'I am able to do calming things, such as deep breathing, walking, prayer, or listening to music.', reverse: true),
  Question('J05', Domain.pelindung, 'My beliefs, values, or community give me strength.', reverse: true),
  Question('J06', Domain.pelindung, 'I can picture something in the future that I want to live for.', reverse: true),
  Question('J07', Domain.pelindung, 'I still keep up basic routines like eating, sleeping, and bathing.', reverse: true),
  Question('J08', Domain.pelindung, 'I remember getting through hard times before and know what helped me.', reverse: true),
  Question('J09', Domain.pelindung, 'I feel safe where I live right now.', reverse: true),
  Question('J10', Domain.pelindung, 'I am willing to ask a trusted person to keep dangerous items away when I am very distressed.', reverse: true),
];
