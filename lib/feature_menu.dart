// Menu dua kotak yang bisa digeser (Diary, Cek Emosi, Hope Box, Letter Box).
// Letakkan di: lib/feature_menu.dart

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'diary.dart';
import 'hope_box.dart';
import 'letters.dart';
import 'screening_screens.dart';

class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder page;
  const _Feature(this.icon, this.title, this.subtitle, this.page);
}

class FeatureCarousel extends StatefulWidget {
  const FeatureCarousel({super.key});

  @override
  State<FeatureCarousel> createState() => _FeatureCarouselState();
}

class _FeatureCarouselState extends State<FeatureCarousel> {
  final _pc = PageController();
  int _page = 0;

  static final _pages = <List<_Feature>>[
    [
      _Feature(Icons.menu_book_rounded, 'Diary', 'Write how your day felt',
          (_) => const DiaryPage()),
      _Feature(Icons.favorite_border, 'Emotional Check', '100 questions, private',
          (_) => const ScreeningIntroPage()),
    ],
    [
      _Feature(Icons.inventory_2_outlined, 'Hope Box', 'Photos that make you smile',
          (_) => const HopeBoxPage()),
      _Feature(Icons.mail_outline, 'Letter Box', 'Letters Hadi delivered',
          (_) => const LettersArchivePage()),
    ],
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _go(int p) => _pc.animateToPage(p,
      duration: const Duration(milliseconds: 320), curve: Curves.easeOut);

  Widget _arrow(IconData icon, bool enabled, VoidCallback onTap) => IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 30),
        color: kBlueDark,
        disabledColor: kGrey,
        visualDensity: VisualDensity.compact,
      );

  Widget _tile(_Feature f) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: f.page)),
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: kBlueSoft, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration:
                  const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(f.icon, color: kBlueDark),
            ),
            const Spacer(),
            Text(f.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(f.subtitle, style: const TextStyle(fontSize: 12.5, height: 1.3)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _arrow(Icons.chevron_left, _page > 0, () => _go(_page - 1)),
        Expanded(
          child: SizedBox(
            height: 150,
            child: PageView(
              controller: _pc,
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                for (final pair in _pages)
                  Row(children: [
                    _tile(pair[0]),
                    const SizedBox(width: 12),
                    _tile(pair[1]),
                  ]),
              ],
            ),
          ),
        ),
        _arrow(Icons.chevron_right, _page < _pages.length - 1, () => _go(_page + 1)),
      ]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < _pages.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == _page ? 18 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
                color: i == _page ? kBlueDark : kBlueSoft,
                borderRadius: BorderRadius.circular(4)),
          ),
      ]),
    ]);
  }
}
