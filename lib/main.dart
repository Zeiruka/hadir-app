// HADIR - aplikasi check-in harian dengan maskot Hadi.
// Letakkan file ini di: lib/main.dart
// Dependensi (pubspec.yaml): shared_preferences, image_picker, url_launcher
// File lain di folder lib/:
//   app_theme.dart, mascot.dart, hadi_companion.dart, letters.dart, diary.dart,
//   hope_box.dart, feature_menu.dart, splash_screen.dart, screening_screens.dart,
//   models/models.dart, data/question_bank.dart, services/scoring.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'diary.dart';
import 'feature_menu.dart';
import 'hadi_companion.dart';
import 'hope_box.dart';
import 'mascot.dart';
import 'splash_screen.dart';

// ───────────────────────── Model & state ─────────────────────────

class Contact {
  String email, name, relation;
  bool digest, moods;
  Contact({
    required this.email,
    this.name = '',
    required this.relation,
    this.digest = true,
    this.moods = false,
  });

  String get label => name.isNotEmpty ? name : email;

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'relation': relation,
        'digest': digest,
        'moods': moods,
      };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        email: j['email'],
        name: j['name'] ?? '',
        relation: j['relation'],
        digest: j['digest'] ?? true,
        moods: j['moods'] ?? false,
      );
}

const kRelations = [
  'Parent', 'Child', 'Spouse/Partner', 'Brother', 'Sister', 'Other relative',
  'Friend', 'Colleague', 'Classmate', 'Neighbor', 'Other'
];

class AppState extends ChangeNotifier {
  late SharedPreferences _p;

  bool loggedIn = false;
  bool onboarded = false;
  String accountEmail = '';
  int textSize = 0; // 0 small, 1 medium, 2 large
  String name = '';
  int gender = 1; // 0 male, 1 female, 2 other
  List<Contact> contacts = [];
  int threshold = 2;
  int alertHour = 9;
  List<String> reminders = ['09:00', '21:00'];
  DateTime? pauseUntil;
  bool chime = false;
  bool digestMe = true;
  bool waves = true;
  Set<String> checkins = {};
  Map<String, int> moods = {};
  DateTime? lastCheckin;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    loggedIn = _p.getBool('loggedIn') ?? false;
    onboarded = _p.getBool('onboarded') ?? false;
    accountEmail = _p.getString('accountEmail') ?? '';
    textSize = _p.getInt('textSize') ?? 0;
    name = _p.getString('name') ?? '';
    gender = _p.getInt('gender') ?? 1;
    threshold = _p.getInt('threshold') ?? 2;
    alertHour = _p.getInt('alertHour') ?? 9;
    reminders = _p.getStringList('reminders') ?? ['09:00', '21:00'];
    chime = _p.getBool('chime') ?? false;
    digestMe = _p.getBool('digestMe') ?? true;
    waves = _p.getBool('waves') ?? true;
    checkins = (_p.getStringList('checkins') ?? []).toSet();
    final c = _p.getString('contacts');
    if (c != null) {
      contacts = (jsonDecode(c) as List)
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final m = _p.getString('moods');
    if (m != null) {
      moods = (jsonDecode(m) as Map)
          .map((k, v) => MapEntry(k as String, v as int));
    }
    final lc = _p.getString('lastCheckin');
    if (lc != null) lastCheckin = DateTime.tryParse(lc);
    final pu = _p.getString('pauseUntil');
    if (pu != null) pauseUntil = DateTime.tryParse(pu);
  }

  Future<void> save() async {
    await _p.setBool('loggedIn', loggedIn);
    await _p.setBool('onboarded', onboarded);
    await _p.setString('accountEmail', accountEmail);
    await _p.setInt('textSize', textSize);
    await _p.setString('name', name);
    await _p.setInt('gender', gender);
    await _p.setInt('threshold', threshold);
    await _p.setInt('alertHour', alertHour);
    await _p.setStringList('reminders', reminders);
    await _p.setBool('chime', chime);
    await _p.setBool('digestMe', digestMe);
    await _p.setBool('waves', waves);
    await _p.setStringList('checkins', checkins.toList());
    await _p.setString(
        'contacts', jsonEncode(contacts.map((e) => e.toJson()).toList()));
    await _p.setString('moods', jsonEncode(moods));
    if (lastCheckin != null) {
      await _p.setString('lastCheckin', lastCheckin!.toIso8601String());
    }
    if (pauseUntil != null) {
      await _p.setString('pauseUntil', pauseUntil!.toIso8601String());
    } else {
      await _p.remove('pauseUntil');
    }
  }

  void update(VoidCallback fn) {
    fn();
    notifyListeners();
    save();
  }

  Future<void> wipe() async {
    await _p.clear();
    await diary.wipe();
    await hope.wipe();
    loggedIn = false;
    onboarded = false;
    accountEmail = '';
    textSize = 0;
    name = '';
    gender = 1;
    contacts = [];
    threshold = 2;
    alertHour = 9;
    reminders = ['09:00', '21:00'];
    pauseUntil = null;
    chime = false;
    digestMe = true;
    waves = true;
    checkins = {};
    moods = {};
    lastCheckin = null;
    notifyListeners();
  }

  // ── logika check-in ──
  DateTime get today => dateOnly(DateTime.now());
  bool get checkedToday => checkins.contains(dayKey(today));
  bool get isPaused =>
      pauseUntil != null && pauseUntil!.isAfter(DateTime.now());

  void checkIn() {
    if (checkedToday) return;
    update(() {
      checkins.add(dayKey(today));
      lastCheckin = DateTime.now();
    });
  }

  void setMood(int m) => update(() => moods[dayKey(today)] = m);

  int get streak {
    var d = today;
    if (!checkins.contains(dayKey(d))) d = addDays(d, -1);
    var n = 0;
    while (checkins.contains(dayKey(d))) {
      n++;
      d = addDays(d, -1);
    }
    return n;
  }

  int get bestRun {
    if (checkins.isEmpty) return 0;
    final days = checkins.map((k) => DateTime.parse(k)).toList()..sort();
    var best = 1, run = 1;
    for (var i = 1; i < days.length; i++) {
      final diff = DateTime.utc(days[i].year, days[i].month, days[i].day)
          .difference(DateTime.utc(
              days[i - 1].year, days[i - 1].month, days[i - 1].day))
          .inDays;
      run = diff == 1 ? run + 1 : 1;
      if (run > best) best = run;
    }
    return best;
  }

  int daysInWeek(DateTime monday) {
    var n = 0;
    for (var i = 0; i < 7; i++) {
      if (checkins.contains(dayKey(addDays(monday, i)))) n++;
    }
    return n;
  }

  /// Jumlah mood [Good, Okay, Low] pada pekan yang dimulai [monday].
  List<int> moodCounts(DateTime monday) {
    final c = [0, 0, 0];
    for (var i = 0; i < 7; i++) {
      final m = moods[dayKey(addDays(monday, i))];
      if (m != null && m >= 0 && m < 3) c[m]++;
    }
    return c;
  }
}

final app = AppState();

// ───────────────────────── Main ─────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  await diary.load();
  await hope.load();
  runApp(const HadirApp());
}

class HadirApp extends StatelessWidget {
  const HadirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        const scales = [1.0, 1.15, 1.3];
        return MaterialApp(
          title: kAppName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: kBlue, primary: kBlueDark),
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'Roboto',
            textTheme: ThemeData.light()
                .textTheme
                .apply(bodyColor: kInk, displayColor: kInk),
          ),
          // Semua layar dipusatkan dan dibatasi lebarnya, jadi di Chrome atau
          // tablet tampilannya tetap seperti layar ponsel di tengah.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scales[app.textSize])),
            child: ColoredBox(
              color: const Color(0xFFEFF4FB),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: child!,
                ),
              ),
            ),
          ),
          home: SplashGate(
            next: () => !app.loggedIn
                ? const WelcomeScreen()
                : !app.onboarded
                    ? const OnboardingScreen()
                    : const HomeScreen(),
          ),
        );
      },
    );
  }
}

// ───────────────────────── Widget umum ─────────────────────────

/// Logo kecil aplikasi = Hadi (diam, hemat baterai).
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) =>
      HadiMascot(size: size, pose: HadiPose.wave, animate: false);
}

class SelectCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double height;

  const SelectCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kBlue : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? kBlueDark : kGrey, width: 2),
          ),
          child: child,
        ),
      ),
    );
  }
}

class TextSizePicker extends StatelessWidget {
  const TextSizePicker({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['Small', 'Medium', 'Large'];
    const sizes = [18.0, 22.0, 26.0];

    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Row(
          children: List.generate(3, (i) {
            final selected = app.textSize == i;
            return SelectCard(
              selected: selected,
              onTap: () => app.update(() => app.textSize = i),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('A',
                    style: TextStyle(
                        fontSize: sizes[i],
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : kInk)),
                const SizedBox(height: 4),
                Text(labels[i],
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : kInk)),
              ]),
            );
          }),
        );
      },
    );
  }
}

class GenderPicker extends StatelessWidget {
  const GenderPicker({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['Male (he/him)', 'Female (she/her)', 'Other (they/them)'];
    const icons = [Icons.male, Icons.female, Icons.wc];

    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Row(
          children: List.generate(3, (i) {
            final selected = app.gender == i;
            return SelectCard(
              height: 76,
              selected: selected,
              onTap: () => app.update(() => app.gender = i),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icons[i], color: selected ? Colors.white : kInk),
                const SizedBox(height: 4),
                Text(labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : kInk)),
              ]),
            );
          }),
        );
      },
    );
  }
}

class InputBox extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? type;
  final ValueChanged<String>? onChanged;
  const InputBox(
      {super.key,
      required this.controller,
      required this.icon,
      required this.hint,
      this.type,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: kInk),
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: kBlue, width: 2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: kBlue, width: 2)),
      ),
    );
  }
}

class ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  const ContactTile(this.contact, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Text(contact.label[0].toUpperCase(),
          style: const TextStyle(
              color: kBlueDark, fontSize: 20, fontWeight: FontWeight.w800)),
      title: Row(children: [
        Flexible(
            child: Text(contact.label,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        const SizedBox(width: 8),
        Text(contact.relation,
            style: const TextStyle(
                color: kBlueDark, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
      subtitle: Text(
        '${contact.email}${contact.digest ? '  ✉ Gets the digest' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

Future<void> editContact(BuildContext context, {Contact? existing}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => ContactSheet(existing: existing),
  );
}

class ContactSheet extends StatefulWidget {
  final Contact? existing;
  const ContactSheet({super.key, this.existing});

  @override
  State<ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<ContactSheet> {
  late final email = TextEditingController(text: widget.existing?.email ?? '');
  late final name = TextEditingController(text: widget.existing?.name ?? '');
  late String? relation = widget.existing?.relation;
  late bool digest = widget.existing?.digest ?? true;
  late bool moods = widget.existing?.moods ?? false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    name.dispose();
    super.dispose();
  }

  void _save() {
    final e = email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      setState(() => error = 'Enter a valid email address.');
      return;
    }
    if (relation == null) {
      setState(() => error = 'Choose a relationship.');
      return;
    }
    final c = Contact(
        email: e,
        name: name.text.trim(),
        relation: relation!,
        digest: digest,
        moods: moods);
    app.update(() {
      if (widget.existing != null) {
        final i = app.contacts.indexOf(widget.existing!);
        if (i >= 0) {
          app.contacts[i] = c;
        } else {
          app.contacts.add(c);
        }
      } else {
        app.contacts.add(c);
      }
    });
    Navigator.pop(context);
  }

  Widget _label(String l, String tag, {bool isRequired = false}) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: const TextStyle(fontSize: 15)),
          Text(tag, style: TextStyle(color: isRequired ? kRed : Colors.black54)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.existing == null ? 'Add contact' : 'Edit contact',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          _label('Email', 'Required', isRequired: true),
          InputBox(
              controller: email,
              icon: Icons.mail_outline,
              hint: 'name@email.com',
              type: TextInputType.emailAddress),
          _label('Name', 'Optional'),
          InputBox(controller: name, icon: Icons.badge_outlined, hint: 'Name'),
          _label('Relationship', 'Required', isRequired: true),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kRelations.map((r) {
              final sel = relation == r;
              return ChoiceChip(
                label: Text(r,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: sel ? kBlueDark : kInk)),
                selected: sel,
                showCheckmark: false,
                selectedColor: Colors.white,
                backgroundColor: Colors.white,
                shape: StadiumBorder(
                    side: BorderSide(color: sel ? kBlue : kGrey, width: 1.5)),
                onSelected: (_) => setState(() => relation = r),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Text('Weekly digest', style: TextStyle(fontSize: 15)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Send them the weekly digest',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle:
                const Text('Their copy includes a one-click unsubscribe link.'),
            value: digest,
            activeColor: Colors.white,
            activeTrackColor: kBlue,
            onChanged: (v) => setState(() => digest = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include my moods',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text("Affects the contact's copy only."),
            value: moods,
            activeColor: Colors.white,
            activeTrackColor: kBlue,
            onChanged: (v) => setState(() => moods = v),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(error!, style: const TextStyle(color: kRed)),
            ),
          BlueButton('Save', _save),
          if (widget.existing != null)
            Center(
              child: TextButton(
                onPressed: () {
                  app.update(() => app.contacts.remove(widget.existing));
                  Navigator.pop(context);
                },
                child: const Text('Remove this contact',
                    style: TextStyle(
                        color: kRed, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ───────────────────────── Welcome / Login ─────────────────────────

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool agree = true;

  Future<void> _login(String provider) async {
    if (!agree) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Please agree to the Terms of Service and Privacy Policy.')));
      return;
    }
    // TODO: ganti dengan Firebase Auth / google_sign_in yang asli.
    final ctl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sign in with $provider'),
        content: TextField(
          controller: ctl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Your email'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctl.text.trim()),
              child: const Text('Continue')),
        ],
      ),
    );
    ctl.dispose();
    if (email == null || !email.contains('@')) return;
    app.update(() {
      app.loggedIn = true;
      app.accountEmail = email;
    });
  }

  Widget _signBtn(Widget icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 62,
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            icon,
            const SizedBox(width: 12),
            Text(label,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const SizedBox(height: 24),
            const ChubbyText(kAppName, fontSize: 34, letterSpacing: 4),
            const Spacer(flex: 2),
            // Melambai cepat dua kali, lalu diam dengan gerak halus.
            const HadiMascot(size: 190, pose: HadiPose.wave, autoWave: true),
            const SizedBox(height: 30),
            const Text('Welcome',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text('Stay connected with your loved ones',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 36),
            _signBtn(
                const Text('G',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4285F4))),
                'Sign in with Google',
                () => _login('Google')),
            _signBtn(const Icon(Icons.mail_outline, color: kBlueDark),
                'Sign in with Email', () => _login('Email')),
            const Spacer(flex: 3),
            Row(children: [
              Checkbox(
                value: agree,
                activeColor: kBlue,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (v) => setState(() => agree = v ?? false),
              ),
              const Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                          color: kBlueDark, fontWeight: FontWeight.w700)),
                  TextSpan(text: ' and '),
                  TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                          color: kBlueDark, fontWeight: FontWeight.w700)),
                ])),
              ),
            ]),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Onboarding ─────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  late final nameCtl = TextEditingController(text: app.name);

  @override
  void dispose() {
    nameCtl.dispose();
    super.dispose();
  }

  void _finish() => app.update(() => app.onboarded = true);

  void _next() {
    if (step == 1) app.update(() => app.name = nameCtl.text.trim());
    if (step < 2) {
      setState(() => step++);
    } else {
      if (app.contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Add at least one emergency contact.')));
        return;
      }
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: ListenableBuilder(
            listenable: app,
            builder: (context, _) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ...List.generate(
                    3,
                    (i) => Container(
                          width: 36,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: i <= step ? kBlue : kGrey,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                const Spacer(),
                TextButton(
                    onPressed: _finish,
                    child: const Text('Skip',
                        style: TextStyle(color: kInk, fontSize: 16))),
              ]),
              const SizedBox(height: 28),
              Text('${step + 1} / 3'),
              const SizedBox(height: 10),
              Expanded(child: SingleChildScrollView(child: _stepBody())),
              BlueButton(step == 2 ? "Done, let's start" : 'Next', _next),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _stepBody() {
    const h = TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.2);
    switch (step) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pick a text size you can read easily', style: h),
          const SizedBox(height: 14),
          const Text(
              'Every screen will use this size. You can change it any time in Settings.'),
          const SizedBox(height: 28),
          const TextSizePicker(),
          const SizedBox(height: 28),
          const Text('Preview', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          const Text(
              'Check in once a day. If you miss a few days in a row, we notify your emergency contacts.',
              style: TextStyle(fontSize: 18, height: 1.5)),
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('What should we call you?', style: h),
          const SizedBox(height: 14),
          const Text('This is how alert emails will address you.'),
          const SizedBox(height: 28),
          InputBox(
              controller: nameCtl, icon: Icons.badge_outlined, hint: 'Your name'),
          const SizedBox(height: 22),
          const Text('Gender', style: TextStyle(fontSize: 15)),
          const SizedBox(height: 8),
          const GenderPicker(),
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('If you go quiet, who should know?', style: h),
          const SizedBox(height: 14),
          const Text(
              'Add at least one emergency contact. If you stop checking in for a few days, we email them.'),
          const SizedBox(height: 20),
          for (final c in app.contacts)
            ContactTile(c, () => editContact(context, existing: c)),
          const SizedBox(height: 8),
          OutlineBtn('Add another', () => editContact(context), icon: Icons.add),
          const SizedBox(height: 14),
          const Text(
              'Make sure this person is willing to be contacted. We email them on your behalf when you stop checking in.'),
        ]);
    }
  }
}

// ───────────────────────── Kisi hati (check-in) ─────────────────────────

/// Kotak-kotak riwayat check-in berbentuk hati, dipusatkan.
/// Hati merah muda = check-in, abu-biru = terlewat, garis biru = hari ini.
class HeartGrid extends StatelessWidget {
  final int columns;
  final int days;
  const HeartGrid({super.key, this.columns = 12, this.days = 84});

  Widget _cell(int i, double size) {
    final d = addDays(app.today, -(days - 1 - i));
    final ok = app.checkins.contains(dayKey(d));
    final isToday = d == app.today;
    if (ok) return HeartIcon(size: size, color: kPinkDark);
    if (isToday) return HeartIcon(size: size, color: kBlue, outline: true);
    return HeartIcon(size: size, color: const Color(0xFFE3EBF6));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 6.0;
      final size = ((c.maxWidth - gap * (columns - 1)) / columns).clamp(12.0, 26.0);
      final rows = (days / columns).ceil();
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var r = 0; r < rows; r++)
            Padding(
              padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : gap),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var col = 0; col < columns; col++)
                  Padding(
                    padding: EdgeInsets.only(right: col == columns - 1 ? 0 : gap),
                    child: _cell(r * columns + col, size),
                  ),
              ]),
            ),
        ]),
      );
    });
  }
}

// ───────────────────────── Home ─────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);
  final _checkKey = GlobalKey<HadiMascotState>();
  bool _askDiary = false;
  String _diarySkippedFor = '';

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  void _tap() {
    if (app.checkedToday) {
      _checkKey.currentState?.waveOnce();
      _toast('You already checked in today.');
      return;
    }
    app.checkIn();
    HapticFeedback.heavyImpact();
    if (app.chime) SystemSound.play(SystemSoundType.click);
    _toast('Hadir! Check-in successful. Stay safe!');
    // Tunggu tangan Hadi naik, lalu melambai.
    Future.delayed(const Duration(milliseconds: 600), () {
      _checkKey.currentState?.waveOnce();
    });
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: kBlue),
        const SizedBox(width: 10),
        Expanded(child: Text(m)),
      ]),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  void _pickMood(int i) {
    app.setMood(i);
    if (_diarySkippedFor != dayKey(app.today)) setState(() => _askDiary = true);
  }

  String _fmtLast() {
    final d = app.lastCheckin;
    if (d == null) return 'Not yet';
    return '${kMonths[d.month - 1]} ${d.day}, ${d.year} • ${two(d.hour)}:${two(d.minute)}';
  }

  // ── bagian-bagian layar ──

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Row(children: [
        const AppLogo(size: 42),
        const SizedBox(width: 12),
        const ChubbyText(kAppName, fontSize: 24, letterSpacing: 2),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 30),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ]),
    );
  }

  /// Tombol check-in = Hadi. Sebelum check-in kedua tangannya turun; sesudahnya
  /// ia mengangkat tangan dan melambai ("Hadir!").
  Widget _checkButton(bool done) {
    return GestureDetector(
      onTap: _tap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          final t = done ? 0.0 : pulse.value;
          return SizedBox(
            width: 300,
            height: 300,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 300 - 12 * (1 - t),
                height: 300 - 12 * (1 - t),
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: kBlue.withOpacity(0.12)),
              ),
              Container(
                width: 232,
                height: 232,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: kBlue.withOpacity(0.35)),
              ),
              Container(
                width: 200,
                height: 200,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBlue,
                  boxShadow: [
                    BoxShadow(
                        color: kBlue.withOpacity(0.5), blurRadius: 30, spreadRadius: 2)
                  ],
                ),
                child: HadiMascot(
                  key: _checkKey,
                  size: 200,
                  pose: done ? HadiPose.wave : HadiPose.down,
                  background: false,
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _moodCard(int? mood) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kGrey, width: 2)),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  mood == null
                      ? 'How do you feel today?'
                      : "Today's mood: ${kMoodLabels[mood]}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                  mood == null
                      ? 'Optional. Private to you by default.'
                      : 'You can change it any time today.',
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ]),
          ),
          for (var i = 0; i < 3; i++)
            GestureDetector(
              onTap: () => _pickMood(i),
              child: Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mood == i ? kBlueSoft : Colors.white,
                  border: Border.all(color: mood == i ? kBlue : kGrey, width: 2),
                ),
                child: Icon(kMoodIcons[i], size: 30),
              ),
            ),
        ]),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: double.infinity,
            child: !_askDiary
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: kBlueSoft, borderRadius: BorderRadius.circular(18)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Want to write a diary entry about today?',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('Totally optional. You can skip.',
                            style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 10),
                        Row(children: [
                          TextButton(
                            onPressed: () => setState(() {
                              _askDiary = false;
                              _diarySkippedFor = dayKey(app.today);
                            }),
                            child: const Text('Skip', style: TextStyle(color: kInk)),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 150,
                            child: BlueButton('Write', () {
                              setState(() => _askDiary = false);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DiaryEditorPage(initialMood: mood)));
                            }, height: 44),
                          ),
                        ]),
                      ]),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _recordCard() {
    final monday = addDays(app.today, -(app.today.weekday - 1));
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kGrey, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.favorite, color: kPinkDark),
          const SizedBox(width: 10),
          const Text('Check-in record',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ReportScreen())),
            child: const Text('Report ›',
                style: TextStyle(
                    color: kBlueDark, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Last Check-In · ${_fmtLast()}',
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i < 7; i++)
            Builder(builder: (_) {
              final d = addDays(monday, i);
              final ok = app.checkins.contains(dayKey(d));
              final isToday = d == app.today;
              final future = d.isAfter(app.today);
              return Column(children: [
                HeartIcon(
                    size: 34,
                    color: ok
                        ? kPinkDark
                        : isToday
                            ? kBlue
                            : future
                                ? kGrey
                                : const Color(0xFFE3EBF6),
                    outline: !ok && isToday),
                const SizedBox(height: 4),
                Text(letters[i], style: const TextStyle(fontSize: 12)),
              ]);
            }),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🔥', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 6),
          Text('${app.streak}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          const Text('day streak'),
          const SizedBox(width: 28),
          const Text('🏅', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 6),
          Text('${app.bestRun}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          const Text('best run'),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final done = app.checkedToday;
        final mood = app.moods[dayKey(app.today)];
        return Scaffold(
          body: SafeArea(
            child: Column(children: [
              _header(context), // tetap di atas saat layar digulir
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  children: [
                    Center(
                        child: Text('Hi, ${app.name.isEmpty ? 'there' : app.name}!',
                            style: const TextStyle(fontSize: 20))),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(done ? 'Checked in today' : 'Tap to check in',
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 10),
                    const HadiCompanion(),
                    // Foto Hope Box melayang di belakang tombol check-in.
                    SizedBox(
                      height: 340,
                      width: double.infinity,
                      child: Stack(alignment: Alignment.center, children: [
                        const FloatingMemories(height: 340),
                        _checkButton(done),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    _moodCard(mood),
                    const SizedBox(height: 16),
                    const FeatureCarousel(),
                    const SizedBox(height: 16),
                    _recordCard(),
                    const SizedBox(height: 16),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.info_outline, color: kBlueDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            "If you haven't checked in for ${app.threshold} days, the system will send an email to your emergency contact in your name.",
                            style: const TextStyle(fontSize: 15, height: 1.4)),
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ───────────────────────── Weekly report ─────────────────────────

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int offset = 0; // 0 = minggu ini, -1 = minggu lalu, dst.

  DateTime get _thisMonday => addDays(app.today, -(app.today.weekday - 1));
  DateTime get _monday => addDays(_thisMonday, offset * 7);

  Widget _legend(Widget icon, String t) => Row(children: [
        icon,
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(fontSize: 13)),
      ]);

  Widget _moodSection(DateTime mon) {
    final counts = app.moodCounts(mon);
    final total = counts.fold<int>(0, (a, b) => a + b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('MOOD',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      const SizedBox(height: 10),
      if (total == 0)
        const Text('No mood recorded this week.', style: TextStyle(color: Colors.black54))
      else ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Row(children: [
              for (var i = 0; i < 3; i++)
                if (counts[i] > 0)
                  Expanded(flex: counts[i], child: Container(color: kMoodColors[i])),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 6, children: [
          for (var i = 0; i < 3; i++)
            if (counts[i] > 0)
              Text('${kMoodEmoji[i]} ${kMoodLabels[i]} ×${counts[i]}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final mon = _monday;
    final sun = addDays(mon, 6);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final count = app.daysInWeek(mon);
    final left = 7 - app.streak;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Weekly Report',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => offset--)),
            Text(
                '${kMonths[mon.month - 1]} ${mon.day} – ${kMonths[sun.month - 1]} ${sun.day}',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(offset == 0 ? ' · This week' : '',
                style: const TextStyle(fontSize: 14)),
            IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: offset < 0 ? () => setState(() => offset++) : null),
          ]),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final d = addDays(mon, i);
              final ok = app.checkins.contains(dayKey(d));
              return Column(children: [
                HeartIcon(
                    size: 38,
                    color: ok
                        ? kPinkDark
                        : d.isAfter(app.today)
                            ? kGrey
                            : const Color(0xFFE3EBF6)),
                const SizedBox(height: 6),
                Text(days[i], style: const TextStyle(fontSize: 13)),
              ]);
            }),
          ),
          const SizedBox(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Column(children: [
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: '$count',
                    style: const TextStyle(
                        fontSize: 38, fontWeight: FontWeight.w800)),
                const TextSpan(text: '/7', style: TextStyle(fontSize: 18)),
              ])),
              const Text('days checked in'),
            ]),
            Column(children: [
              Row(children: [
                const Text('🔥', style: TextStyle(fontSize: 36)),
                Text('${app.streak}',
                    style: const TextStyle(
                        fontSize: 38, fontWeight: FontWeight.w800)),
              ]),
              const Text('day streak'),
            ]),
          ]),
          const SizedBox(height: 22),
          if (left > 0)
            Text('🏅 $left more days to a 7-day streak',
                style: const TextStyle(
                    color: kBlueDark, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 28),
          _moodSection(mon),
          const SizedBox(height: 34),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Last 8 weeks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('days per week', style: TextStyle(fontSize: 13)),
          ]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(8, (i) {
              final weeksAgo = 7 - i;
              final n = app.daysInWeek(addDays(_thisMonday, -7 * weeksAgo));
              final current = weeksAgo == 0;
              return Column(children: [
                Text('$n',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: current ? kBlueDark : kInk)),
                const SizedBox(height: 6),
                Container(
                  width: 30,
                  height: 8 + n * 6.0,
                  decoration: BoxDecoration(
                    color: current ? kBlue : kBlue.withOpacity(n == 0 ? 0.25 : 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(current ? 'Now' : '$weeksAgo',
                    style: const TextStyle(fontSize: 12)),
              ]);
            }),
          ),
          const SizedBox(height: 34),
          const Text('Check-in record',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Each heart is a day. Best run: ${app.bestRun} days.'),
          const SizedBox(height: 16),
          const HeartGrid(),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legend(const HeartIcon(size: 14, color: kPinkDark), 'checked in'),
            const SizedBox(width: 16),
            _legend(const HeartIcon(size: 14, color: Color(0xFFE3EBF6)), 'missed'),
            const SizedBox(width: 16),
            _legend(const HeartIcon(size: 14, color: kBlue, outline: true), 'today'),
          ]),
        ]),
      ),
    );
  }
}

// ───────────────────────── Settings ─────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final nameCtl = TextEditingController(text: app.name);

  @override
  void dispose() {
    nameCtl.dispose();
    super.dispose();
  }

  Widget _section(IconData icon, String title, String? sub, Widget child,
      {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: kBlueDark),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (trailing != null) Text(trailing),
        ]),
        if (sub != null)
          Padding(
              padding: const EdgeInsets.only(top: 8, left: 36),
              child: Text(sub, style: const TextStyle(fontSize: 15, height: 1.4))),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _switch(String t, String s, bool v, ValueChanged<bool> on) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(s),
        value: v,
        activeColor: Colors.white,
        activeTrackColor: kBlue,
        onChanged: on,
      );

  Future<void> _addReminder() async {
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
    if (t == null) return;
    final s = '${two(t.hour)}:${two(t.minute)}';
    if (!app.reminders.contains(s)) {
      app.update(() => app.reminders = ([...app.reminders, s]..sort()));
    }
  }

  Future<void> _pause() async {
    final days = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pause for how long?'),
        children: [
          for (final d in [1, 3, 7, 14])
            SimpleDialogOption(
                onPressed: () => Navigator.pop(context, d),
                child: Text('$d day${d > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 17))),
          if (app.isPaused)
            SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 0),
                child: const Text('Resume now',
                    style: TextStyle(fontSize: 17, color: kRed))),
        ],
      ),
    );
    if (days == null) return;
    app.update(() => app.pauseUntil =
        days == 0 ? null : DateTime.now().add(Duration(days: days)));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently removes your account and all of your data, including your diary and Hope Box.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (ok == true) {
      await app.wipe();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final digestCount = app.contacts.where((c) => c.digest).length;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: const Text('Settings', style: TextStyle(fontSize: 24)),
          ),
          body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: kBlueSoft,
                      child: Text(
                          app.name.isEmpty ? '?' : app.name[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: kBlueDark)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app.name,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w800)),
                            Text(app.accountEmail),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 34),
                  _section(
                      Icons.text_fields,
                      'Text size',
                      'Applies to every screen. Pick Large if the text is hard to read.',
                      const TextSizePicker()),
                  _section(
                    Icons.contact_emergency_outlined,
                    'Emergency Contact',
                    'We email every one of them if you go quiet.',
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      for (final c in app.contacts)
                        ContactTile(c, () => editContact(context, existing: c)),
                      const SizedBox(height: 8),
                      if (app.contacts.length < 5)
                        OutlineBtn('Add contact', () => editContact(context),
                            icon: Icons.add),
                      const SizedBox(height: 12),
                      const Text(
                          'Make sure this person is willing to be contacted. We email them on your behalf when you stop checking in.'),
                    ]),
                    trailing: '${app.contacts.length} / 5',
                  ),
                  _section(
                      Icons.person_outline,
                      'Personal Information',
                      'This is how alert emails will address you.',
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        InputBox(
                          controller: nameCtl,
                          icon: Icons.badge_outlined,
                          hint: 'Your name',
                          onChanged: (v) => app.update(() => app.name = v.trim()),
                        ),
                        const SizedBox(height: 18),
                        const Text('Gender'),
                        const SizedBox(height: 8),
                        const GenderPicker(),
                      ])),
                  _section(
                    Icons.schedule,
                    'Alert Threshold',
                    'How many days without a check-in before your emergency contact is notified.',
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: '${app.threshold}',
                            style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: kBlueDark)),
                        TextSpan(
                            text: app.threshold == 1 ? ' day' : ' days',
                            style: const TextStyle(fontSize: 18)),
                      ])),
                      Slider(
                        value: app.threshold.toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        activeColor: kBlue,
                        onChanged: (v) =>
                            app.update(() => app.threshold = v.round()),
                      ),
                      const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text('1 day'), Text('7 days')]),
                      const SizedBox(height: 22),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Alert email time',
                                style: TextStyle(fontSize: 17)),
                            Text('${two(app.alertHour)}:00',
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w900)),
                          ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 24,
                          itemBuilder: (_, h) {
                            final sel = app.alertHour == h;
                            return GestureDetector(
                              onTap: () => app.update(() => app.alertHour = h),
                              child: Container(
                                width: 78,
                                margin: const EdgeInsets.only(right: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: sel ? kBlue : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14)),
                                child: Text('${two(h)}:00',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: sel ? Colors.white : kInk)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.info_outline, color: kBlueDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                              "If you don't check in for ${app.threshold} days, an alert email is sent to your Emergency Contact the next day at ${two(app.alertHour)}:00.",
                              style: const TextStyle(fontSize: 16, height: 1.4)),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      const Text(
                          '$kAppName is not an emergency service. It sends an email — it cannot call an ambulance or the police. In an emergency, contact your local emergency number.',
                          style: TextStyle(height: 1.4)),
                    ]),
                  ),
                  _section(
                    Icons.notifications_none,
                    'Check-in reminders',
                    "Pushed at the times you set — only if you haven't checked in yet that day.",
                    Column(children: [
                      for (final r in app.reminders)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule),
                          title: Text(r,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                app.update(() => app.reminders.remove(r)),
                          ),
                        ),
                      if (app.reminders.length < 5)
                        OutlineBtn('Add a reminder', _addReminder,
                            icon: Icons.add, dashed: true),
                      const SizedBox(height: 14),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.info_outline, color: kBlueDark),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                app.reminders.isEmpty
                                    ? 'No reminders set.'
                                    : "Every day at ${app.reminders.join(', ')}, $kAppName reminds you if you haven't checked in yet.",
                                style: const TextStyle(fontSize: 16, height: 1.4))),
                      ]),
                    ]),
                    trailing: '${app.reminders.length}/5',
                  ),
                  _section(
                    Icons.pause_circle_outline,
                    'Pause Check-ins',
                    'Set a period without check-ins: no reminders, no alerts, and your streak is protected. Up to 14 days at a time; resumes automatically.',
                    Column(children: [
                      if (app.isPaused)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                              'Paused until ${kMonths[app.pauseUntil!.month - 1]} ${app.pauseUntil!.day}',
                              style: const TextStyle(
                                  color: kBlueDark, fontWeight: FontWeight.w800)),
                        ),
                      OutlineBtn(
                          app.isPaused ? 'Change pause…' : 'Set a pause…', _pause),
                    ]),
                  ),
                  _section(
                    Icons.volume_up_outlined,
                    'Sound',
                    null,
                    _switch(
                        'Check-in chime',
                        'Play a short chime after a successful check-in. Vibration stays on either way.',
                        app.chime,
                        (v) => app.update(() => app.chime = v)),
                  ),
                  _section(
                    Icons.mark_email_read_outlined,
                    'Weekly digest',
                    "A Monday-morning email summarizing last week's check-ins.",
                    Column(children: [
                      _switch(
                          'Send to me',
                          'Days checked in, streak, and your moods.',
                          app.digestMe,
                          (v) => app.update(() => app.digestMe = v)),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.people_outline, color: kBlueDark),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                'The digest for contacts is switched on per contact. $digestCount ${digestCount == 1 ? 'contact gets' : 'contacts get'} it.')),
                      ]),
                    ]),
                  ),
                  _section(
                    Icons.waving_hand_outlined,
                    'Waves',
                    null,
                    _switch(
                        'Receive waves from strangers',
                        "When off, you won't get waves or anonymous letters, or be picked for one.",
                        app.waves,
                        (v) => app.update(() => app.waves = v)),
                  ),
                  BlueButton('Save Settings', () async {
                    await app.save();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings saved.')));
                    }
                  }),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _delete,
                      child: const Text('Delete Account',
                          style: TextStyle(
                              color: kRed,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const Center(
                      child: Text(
                          'Permanently remove your account and all of your data.')),
                ]),
          ),
        );
      },
    );
  }
}
