// Kotak Harapan (Hope Box): foto momen bahagia + catatan + link, yang bisa
// melayang di belakang tombol check-in.
// Letakkan di: lib/hope_box.dart
// Dependensi baru: image_picker, url_launcher

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_theme.dart';
import 'mascot.dart';

// ───────────────────────── Bentuk ─────────────────────────

enum HopeShape { heart, circle, diamond, square, star }

String hopeShapeLabel(HopeShape s) => switch (s) {
      HopeShape.heart => 'Heart',
      HopeShape.circle => 'Circle',
      HopeShape.diamond => 'Diamond',
      HopeShape.square => 'Square',
      HopeShape.star => 'Star',
    };

Path hopeShapePath(HopeShape s, Size size) {
  final w = size.width, h = size.height;
  switch (s) {
    case HopeShape.circle:
      return Path()..addOval(Rect.fromLTWH(0, 0, w, h));
    case HopeShape.heart:
      return heartPath(Rect.fromLTWH(0, 0, w, h));
    case HopeShape.diamond:
      return Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w / 2, h)
        ..lineTo(0, h / 2)
        ..close();
    case HopeShape.square:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h), const Radius.circular(12)));
    case HopeShape.star:
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final r = (i.isEven ? 0.5 : 0.23) * math.min(w, h);
        final a = -math.pi / 2 + i * math.pi / 5;
        final x = w / 2 + r * math.cos(a), y = h / 2 + r * math.sin(a);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      return path..close();
  }
}

class _ShapeClipper extends CustomClipper<Path> {
  final HopeShape shape;
  _ShapeClipper(this.shape);
  @override
  Path getClip(Size size) => hopeShapePath(shape, size);
  @override
  bool shouldReclip(covariant _ShapeClipper old) => old.shape != shape;
}

class _ShapePreview extends CustomPainter {
  final HopeShape shape;
  final Color color;
  _ShapePreview(this.shape, this.color);
  @override
  void paint(Canvas canvas, Size s) =>
      canvas.drawPath(hopeShapePath(shape, s), Paint()..color = color);
  @override
  bool shouldRepaint(covariant _ShapePreview old) =>
      old.shape != shape || old.color != color;
}

// ───────────────────────── Data ─────────────────────────

class HopeItem {
  final String id;
  final String b64;
  String note;
  String link;
  bool show;
  final DateTime created;
  Uint8List? _bytes;

  HopeItem({
    required this.id,
    required this.b64,
    this.note = '',
    this.link = '',
    this.show = true,
    DateTime? created,
  }) : created = created ?? DateTime.now();

  Uint8List get bytes => _bytes ??= base64Decode(b64);

  Map<String, dynamic> toJson() => {
        'id': id,
        'b64': b64,
        'note': note,
        'link': link,
        'show': show,
        'created': created.toIso8601String(),
      };

  factory HopeItem.fromJson(Map<String, dynamic> j) => HopeItem(
        id: j['id'],
        b64: j['b64'],
        note: j['note'] ?? '',
        link: j['link'] ?? '',
        show: j['show'] ?? true,
        created: DateTime.tryParse(j['created'] ?? ''),
      );
}

class HopeStore extends ChangeNotifier {
  static const maxItems = 30;
  late SharedPreferences _p;
  List<HopeItem> items = [];
  HopeShape shape = HopeShape.heart;
  double opacity = 0.85;
  bool enabled = true;

  List<HopeItem> get visible => items.where((e) => e.show).toList();

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p.getString('hopeItems');
    if (raw != null) {
      items = (jsonDecode(raw) as List)
          .map((e) => HopeItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final si = _p.getInt('hopeShape') ?? 0;
    shape = HopeShape.values[si.clamp(0, HopeShape.values.length - 1)];
    opacity = _p.getDouble('hopeOpacity') ?? 0.85;
    enabled = _p.getBool('hopeOn') ?? true;
  }

  Future<void> _save() async {
    await _p.setString('hopeItems', jsonEncode(items.map((e) => e.toJson()).toList()));
    await _p.setInt('hopeShape', shape.index);
    await _p.setDouble('hopeOpacity', opacity);
    await _p.setBool('hopeOn', enabled);
  }

  void update(VoidCallback fn) {
    fn();
    notifyListeners();
    _save();
  }

  Future<void> wipe() async {
    items = [];
    shape = HopeShape.heart;
    opacity = 0.85;
    enabled = true;
    notifyListeners();
    await _p.remove('hopeItems');
  }
}

final hope = HopeStore();

// ───────────────────────── Halaman Hope Box ─────────────────────────

class HopeBoxPage extends StatelessWidget {
  const HopeBoxPage({super.key});

  Widget _settings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: kBlueSoft, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show on dashboard',
              style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Memories float softly behind your check-in button.'),
          value: hope.enabled,
          activeColor: Colors.white,
          activeTrackColor: kBlue,
          onChanged: (v) => hope.update(() => hope.enabled = v),
        ),
        const SizedBox(height: 6),
        const Text('Shape', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final s in HopeShape.values)
            GestureDetector(
              onTap: () => hope.update(() => hope.shape = s),
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: hope.shape == s ? kBlueDark : kGrey, width: 2),
                  ),
                  child: CustomPaint(
                      painter: _ShapePreview(s, hope.shape == s ? kBlueDark : kBlue)),
                ),
                const SizedBox(height: 4),
                Text(hopeShapeLabel(s), style: const TextStyle(fontSize: 11)),
              ]),
            ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          const Text('Opacity', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${(hope.opacity * 100).round()}%'),
        ]),
        Slider(
          value: hope.opacity,
          min: 0.1,
          max: 1.0,
          activeColor: kBlue,
          onChanged: (v) => hope.update(() => hope.opacity = v),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Hope Box', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: hope,
          builder: (context, _) {
            return ListView(padding: const EdgeInsets.all(20), children: [
              const Text(
                  'Keep photos of happy moments, funny finds, or anything that makes you feel a bit better. Add a short note or a link if you like.',
                  style: TextStyle(height: 1.45)),
              const SizedBox(height: 16),
              _settings(),
              const SizedBox(height: 18),
              BlueButton('Add a memory', () => showAddMemory(context)),
              const SizedBox(height: 20),
              if (hope.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(children: const [
                    HadiMascot(size: 140, pose: HadiPose.heart),
                    SizedBox(height: 12),
                    Text('Nothing here yet. Your first memory goes here 💙',
                        textAlign: TextAlign.center),
                  ]),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
                  itemCount: hope.items.length,
                  itemBuilder: (context, i) {
                    final it = hope.items[i];
                    return GestureDetector(
                      onTap: () => showHopeDetail(context, it),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.memory(it.bytes, fit: BoxFit.cover, gaplessPlayback: true),
                          if (!it.show) Container(color: Colors.white54),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.white70, shape: BoxShape.circle),
                              child: Icon(
                                  it.show ? Icons.visibility : Icons.visibility_off,
                                  size: 16,
                                  color: kBlueDark),
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
            ]);
          },
        ),
      ),
    );
  }
}

// ───────────────────────── Tambah kenangan ─────────────────────────

Future<void> showAddMemory(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _AddMemorySheet(),
    );

class _AddMemorySheet extends StatefulWidget {
  const _AddMemorySheet();

  @override
  State<_AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<_AddMemorySheet> {
  final _note = TextEditingController();
  final _link = TextEditingController();
  Uint8List? _bytes;
  bool _show = true;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 720, imageQuality: 70);
      if (x == null) return;
      final b = await x.readAsBytes();
      if (mounted) setState(() => _bytes = b);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't open the gallery.");
    }
  }

  void _save() {
    if (_bytes == null) {
      setState(() => _error = 'Pick a photo first.');
      return;
    }
    if (hope.items.length >= HopeStore.maxItems) {
      setState(() => _error = 'The box is full (${HopeStore.maxItems}). Remove one first.');
      return;
    }
    var link = _link.text.trim();
    if (link.isNotEmpty && !link.startsWith('http')) link = 'https://$link';
    hope.update(() => hope.items.insert(
        0,
        HopeItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          b64: base64Encode(_bytes!),
          note: _note.text.trim(),
          link: link,
          show: _show,
        )));
    Navigator.pop(context);
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        prefixIcon: Icon(icon, color: kInk),
        hintText: hint,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kBlue, width: 2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kBlueDark, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add a memory',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pick,
            child: Container(
              height: 180,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: kBlueSoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kBlue, width: 2),
              ),
              child: _bytes == null
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Icon(Icons.add_photo_alternate_outlined, size: 40, color: kBlueDark),
                      SizedBox(height: 6),
                      Text('Tap to pick a photo',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ])
                  : Image.memory(_bytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
              controller: _note,
              maxLength: 120,
              decoration: _dec('Short note (optional): why does this matter?', Icons.edit_note)),
          const SizedBox(height: 6),
          TextField(
              controller: _link,
              keyboardType: TextInputType.url,
              decoration: _dec('Link (optional): video, post, article', Icons.link)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show on dashboard',
                style: TextStyle(fontWeight: FontWeight.w700)),
            value: _show,
            activeColor: Colors.white,
            activeTrackColor: kBlue,
            onChanged: (v) => setState(() => _show = v),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: kRed)),
            ),
          BlueButton('Save to Hope Box', _save),
        ]),
      ),
    );
  }
}

// ───────────────────────── Detail ─────────────────────────

Future<void> showHopeDetail(BuildContext context, HopeItem item) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _HopeDetail(item: item),
    );

class _HopeDetail extends StatelessWidget {
  final HopeItem item;
  const _HopeDetail({required this.item});

  Future<void> _open(BuildContext context) async {
    try {
      final ok = await launchUrl(Uri.parse(item.link), mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Couldn't open this link.")));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Couldn't open this link.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: hope,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.memory(item.bytes,
                  width: double.infinity, height: 280, fit: BoxFit.cover),
            ),
            const SizedBox(height: 14),
            if (item.note.isNotEmpty)
              Text(item.note, style: const TextStyle(fontSize: 17, height: 1.4)),
            if (item.link.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlineBtn('Open link', () => _open(context), icon: Icons.open_in_new),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show on dashboard',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              value: item.show,
              activeColor: Colors.white,
              activeTrackColor: kBlue,
              onChanged: (v) => hope.update(() => item.show = v),
            ),
            Center(
              child: TextButton(
                onPressed: () {
                  hope.update(() => hope.items.removeWhere((e) => e.id == item.id));
                  Navigator.pop(context);
                },
                child: const Text('Remove from Hope Box',
                    style: TextStyle(color: kRed, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Foto melayang di dashboard ─────────────────────────

class FloatingMemories extends StatefulWidget {
  final double height;
  const FloatingMemories({super.key, this.height = 340});

  @override
  State<FloatingMemories> createState() => _FloatingMemoriesState();
}

class _FloatingMemoriesState extends State<FloatingMemories>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 14))
    ..repeat();

  static const _anchors = [
    Alignment(-0.88, -0.62),
    Alignment(0.88, -0.78),
    Alignment(-0.98, 0.18),
    Alignment(0.98, 0.22),
    Alignment(-0.62, 0.92),
    Alignment(0.66, 0.96),
  ];
  static const _sizes = [64.0, 56.0, 70.0, 60.0, 58.0, 66.0];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([hope, _c]),
        builder: (context, _) {
          if (!hope.enabled) return const SizedBox.shrink();
          final items = hope.visible.take(_anchors.length).toList();
          final t = _c.value * 2 * math.pi;
          return Stack(children: [
            for (var i = 0; i < items.length; i++)
              Align(
                alignment: _anchors[i],
                child: Transform.translate(
                  offset: Offset(math.sin(t + i * 1.3) * 9, math.cos(t + i * 0.9) * 11),
                  child: GestureDetector(
                    onTap: () => showHopeDetail(context, items[i]),
                    child: SizedBox(
                      width: _sizes[i],
                      height: _sizes[i],
                      child: ClipPath(
                        clipper: _ShapeClipper(hope.shape),
                        child: Opacity(
                          opacity: hope.opacity,
                          child: Image.memory(items[i].bytes,
                              fit: BoxFit.cover, gaplessPlayback: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}
