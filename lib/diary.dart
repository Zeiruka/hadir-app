// Diary pribadi (tersimpan hanya di perangkat ini).
// Letakkan di: lib/diary.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'mascot.dart';

class DiaryEntry {
  final String id;
  DateTime date;
  int? mood;
  String text;
  DiaryEntry({required this.id, required this.date, this.mood, required this.text});

  Map<String, dynamic> toJson() =>
      {'id': id, 'date': date.toIso8601String(), 'mood': mood, 'text': text};

  factory DiaryEntry.fromJson(Map<String, dynamic> j) => DiaryEntry(
        id: j['id'],
        date: DateTime.parse(j['date']),
        mood: j['mood'],
        text: j['text'] ?? '',
      );
}

class DiaryStore extends ChangeNotifier {
  late SharedPreferences _p;
  List<DiaryEntry> entries = [];

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p.getString('diary');
    if (raw != null) {
      entries = (jsonDecode(raw) as List)
          .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _save() =>
      _p.setString('diary', jsonEncode(entries.map((e) => e.toJson()).toList()));

  void upsert(DiaryEntry e) {
    final i = entries.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      entries[i] = e;
    } else {
      entries.add(e);
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    _save();
  }

  void remove(String id) {
    entries.removeWhere((e) => e.id == id);
    notifyListeners();
    _save();
  }

  Future<void> wipe() async {
    entries = [];
    notifyListeners();
    await _p.remove('diary');
  }
}

final diary = DiaryStore();

String _fmt(DateTime d) =>
    '${kMonths[d.month - 1]} ${d.day}, ${d.year} • ${two(d.hour)}:${two(d.minute)}';

// ───────────────────────── Daftar diary ─────────────────────────

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Diary', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: diary,
          builder: (context, _) {
            return Column(children: [
              Expanded(
                child: diary.entries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(mainAxisSize: MainAxisSize.min, children: const [
                            HadiMascot(size: 150, pose: HadiPose.think),
                            SizedBox(height: 16),
                            Text('Your diary is empty',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            SizedBox(height: 6),
                            Text(
                                'Write anything: how today felt, what made you smile, or what is on your mind. It stays on this device.',
                                textAlign: TextAlign.center),
                          ]),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: diary.entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final e = diary.entries[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => DiaryEditorPage(entry: e))),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: kBlueSoft,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(e.mood == null ? '📝' : kMoodEmoji[e.mood!],
                                          style: const TextStyle(fontSize: 20)),
                                      const SizedBox(width: 8),
                                      Text(_fmt(e.date),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.black54)),
                                    ]),
                                    const SizedBox(height: 8),
                                    Text(e.text,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(height: 1.4)),
                                  ]),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: BlueButton('New entry',
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DiaryEditorPage()))),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

// ───────────────────────── Editor ─────────────────────────

class DiaryEditorPage extends StatefulWidget {
  final DiaryEntry? entry;
  final int? initialMood;
  const DiaryEditorPage({super.key, this.entry, this.initialMood});

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  late final _ctl = TextEditingController(text: widget.entry?.text ?? '');
  late int? _mood = widget.entry?.mood ?? widget.initialMood;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _save() {
    final text = _ctl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Write something first.')));
      return;
    }
    diary.upsert(DiaryEntry(
      id: widget.entry?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      date: widget.entry?.date ?? DateTime.now(),
      mood: _mood,
      text: text,
    ));
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this entry?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: kRed))),
        ],
      ),
    );
    if (ok == true) {
      diary.remove(widget.entry!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.entry == null ? 'New entry' : 'Edit entry',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (widget.entry != null)
            IconButton(icon: const Icon(Icons.delete_outline, color: kRed), onPressed: _delete),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(_fmt(widget.entry?.date ?? DateTime.now()),
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Mood', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            for (var i = 0; i < 3; i++)
              GestureDetector(
                onTap: () => setState(() => _mood = _mood == i ? null : i),
                child: Container(
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _mood == i ? kBlueSoft : Colors.white,
                    border: Border.all(color: _mood == i ? kBlue : kGrey, width: 2),
                  ),
                  child: Icon(kMoodIcons[i], size: 28),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _ctl,
            minLines: 10,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 17, height: 1.5),
            decoration: InputDecoration(
              hintText: 'How was today? What is on your mind?',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: kBlue, width: 2)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: kBlue, width: 2)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: kBlueDark, width: 2)),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Only stored on this device. Never shared with your contacts.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 18),
          BlueButton('Save', _save),
        ]),
      ),
    );
  }
}
