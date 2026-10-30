import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kInk = Color(0xFF0A1020);
const Color kPanel = Color(0xFF121B2E);
const Color kPanel2 = Color(0xFF18243A);
const Color kBlue = Color(0xFF7795FF);
const Color kCyan = Color(0xFF55D6D0);
const Color kText = Color(0xFFF4F7FF);
const Color kMuted = Color(0xFF9AA8C0);

Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

Future<void> saveJson(String key, Object value) async {
  final prefs = await _prefs;
  await prefs.setString(key, jsonEncode(value));
}

Future<List<dynamic>> loadJsonList(String key) async {
  final prefs = await _prefs;
  final raw = prefs.getString(key);
  if (raw == null || raw.isEmpty) return <dynamic>[];
  try {
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded : <dynamic>[];
  } catch (_) {
    return <dynamic>[];
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

class ToolItem {
  const ToolItem(this.id, this.title, this.subtitle, this.category, this.icon, this.tint);
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color tint;
}

const List<ToolItem> kTools = [
  ToolItem('calculator', 'الحاسبة', 'عمليات حسابية سريعة', 'أدوات يومية', Icons.calculate_rounded, Color(0xFF8FA8FF)),
  ToolItem('todo', 'قائمة المهام', 'رتّب يومك وأنجز مهامك', 'الإنتاجية', Icons.checklist_rounded, Color(0xFF65D6C2)),
  ToolItem('guess', 'تخمين الرقم', 'لعبة أرقام خفيفة', 'ألعاب', Icons.casino_rounded, Color(0xFFFFC56D)),
  ToolItem('password', 'مولّد كلمات المرور', 'أنشئ كلمة مرور عشوائية', 'أدوات يومية', Icons.password_rounded, Color(0xFFB59AFF)),
  ToolItem('telegram', 'دليل بوت تيليجرام', 'خطوات وقائمة تجهيز', 'التطوير', Icons.smart_toy_rounded, Color(0xFF67BDF2)),
  ToolItem('currency', 'محول العملات', 'تحويل بسعر تدخله يدوياً', 'أدوات يومية', Icons.currency_exchange_rounded, Color(0xFF68D6AA)),
  ToolItem('timer', 'المؤقت', 'مؤقت وتركيز', 'الإنتاجية', Icons.timer_rounded, Color(0xFFFFA477)),
  ToolItem('notes', 'دفتر الملاحظات', 'احفظ أفكارك محلياً', 'الإنتاجية', Icons.edit_note_rounded, Color(0xFFFFD36E)),
  ToolItem('wordcount', 'عداد الكلمات', 'احسب الكلمات والحروف', 'النصوص', Icons.text_fields_rounded, Color(0xFF8FB4FF)),
  ToolItem('rps', 'حجر ورقة مقص', 'تحدّ CPU بجولة سريعة', 'ألعاب', Icons.sports_esports_rounded, Color(0xFFFF8FA8)),
  ToolItem('files', 'مستعرض الملفات', 'اختر ملفات جهازك', 'الملفات', Icons.folder_open_rounded, Color(0xFFFFC56D)),
  ToolItem('prices', 'سجل الأسعار', 'تابع الأسعار التي تدخلها', 'الإنتاجية', Icons.price_change_rounded, Color(0xFF64D6D0)),
  ToolItem('snake', 'لعبة الثعبان', 'لعبة كلاسيكية مصغّرة', 'ألعاب', Icons.grid_4x4_rounded, Color(0xFF91D67D)),
  ToolItem('weather', 'الطقس', 'حالة الطقس حسب المدينة', 'الإنترنت', Icons.cloud_rounded, Color(0xFF80C8FF)),
  ToolItem('expenses', 'المصاريف', 'سجّل مصروفاتك اليومية', 'الإنتاجية', Icons.account_balance_wallet_rounded, Color(0xFF7ED6AD)),
  ToolItem('shortlink', 'مختصر الروابط', 'اختصر رابطاً عبر الإنترنت', 'الإنترنت', Icons.link_rounded, Color(0xFFB59AFF)),
  ToolItem('quiz', 'اختبار الأسئلة', 'اختبر معلوماتك', 'التعلّم', Icons.quiz_rounded, Color(0xFFFFA477)),
  ToolItem('pdf', 'قارئ PDF', 'افتح ملفات PDF على جهازك', 'الملفات', Icons.picture_as_pdf_rounded, Color(0xFFFF8585)),
  ToolItem('qr', 'استوديو QR والباركود', 'أنشئ رمزاً أو امسح رمزاً', 'أدوات يومية', Icons.qr_code_2_rounded, Color(0xFF70D6C8)),
  ToolItem('website', 'منشئ صفحة ويب', 'أنشئ قالب HTML بسيطاً', 'التطوير', Icons.language_rounded, Color(0xFF8FA8FF)),
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OmniApp());
}

class OmniApp extends StatefulWidget {
  const OmniApp({super.key});
  @override
  State<OmniApp> createState() => _OmniAppState();
}

class _OmniAppState extends State<OmniApp> {
  int _tab = 0;
  bool _dark = true;
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final p = await _prefs;
    if (!mounted) return;
    setState(() {
      _favorites = p.getStringList('favorites') ?? [];
      _dark = p.getBool('dark_mode') ?? true;
    });
  }

  Future<void> _toggleFavorite(String id) async {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
    final p = await _prefs;
    await p.setStringList('favorites', _favorites);
  }

  Future<void> _setDark(bool value) async {
    setState(() => _dark = value);
    final p = await _prefs;
    await p.setBool('dark_mode', value);
  }

  void _openTool(ToolItem tool) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ToolRoute(
        tool: tool,
        isFavorite: _favorites.contains(tool.id),
        onFavorite: () => _toggleFavorite(tool.id),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kBlue,
      brightness: _dark ? Brightness.dark : Brightness.light,
      surface: _dark ? kInk : const Color(0xFFF5F7FC),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OMNI',
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: kInk,
        cardColor: kPanel,
        snackBarTheme: const SnackBarThemeData(backgroundColor: kPanel2),
        inputDecorationTheme: _inputTheme(true),
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
        cardColor: Colors.white,
        inputDecorationTheme: _inputTheme(false),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(onOpen: _openTool, favorites: _favorites),
            CatalogScreen(onOpen: _openTool, favorites: _favorites),
            FavoritesScreen(onOpen: _openTool, favorites: _favorites),
            SettingsScreen(dark: _dark, onDarkChanged: _setDark),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) => setState(() => _tab = value),
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'الأدوات'),
            NavigationDestination(icon: Icon(LucideIcons.heart), label: 'المفضلة'),
            NavigationDestination(icon: Icon(LucideIcons.settings), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }
}

InputDecorationTheme _inputTheme(bool dark) => InputDecorationTheme(
  filled: true,
  fillColor: dark ? kPanel2 : const Color(0xFFEEF1F8),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBlue, width: 1.4)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpen, required this.favorites});
  final ValueChanged<ToolItem> onOpen;
  final List<String> favorites;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = kTools.where((t) => t.title.toLowerCase().contains(query) || t.subtitle.toLowerCase().contains(query)).toList();
    final featured = kTools.where((t) => ['calculator', 'todo', 'qr', 'pdf', 'expenses', 'timer'].contains(t.id)).toList();
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [kBlue, kCyan]), borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('OMNI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
                    Text('كل أدواتك، بمكان واحد', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                  ]),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                    child: IconButton(onPressed: () => showMessage(context, 'أهلاً بك في OMNI'), icon: const Icon(Icons.notifications_none_rounded)),
                  ),
                ],
              ).animate().fadeIn(duration: 380.ms).slideY(begin: -0.08),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF243A71), Color(0xFF172541), Color(0xFF172E3B)]),
                  boxShadow: [BoxShadow(color: kBlue.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 12))],
                ),
                child: Stack(children: [
                  Positioned(left: -14, top: -20, child: Icon(Icons.auto_awesome, size: 100, color: Colors.white.withValues(alpha: 0.05))),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(30)), child: const Text('مساحة أدواتك الذكية', style: TextStyle(color: Color(0xFFDCE6FF), fontSize: 11))),
                    const SizedBox(height: 14),
                    const Text('شنو ننجز اليوم؟', style: TextStyle(fontSize: 23, height: 1.3, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 6),
                    const Text('اختَر أداة وابدأ مباشرة، بدون تعقيد.', style: TextStyle(color: Color(0xFFC2D0EA), fontSize: 13)),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن أداة...', hintStyle: const TextStyle(color: Color(0xFFACBBD8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFCAD8F1)),
                        filled: true, fillColor: Colors.white.withValues(alpha: 0.10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF8DAAFF))),
                      ),
                    ),
                  ]),
                ]),
              ).animate().fadeIn(duration: 480.ms).slideY(begin: 0.06),
            ),
          ),
          if (query.isNotEmpty) ...[
            _sectionHeader('نتائج البحث', '${filtered.length} أداة'),
            SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), sliver: SliverGrid.builder(
              itemCount: filtered.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.55),
              itemBuilder: (context, index) => ToolCard(tool: filtered[index], isFavorite: widget.favorites.contains(filtered[index].id), onTap: () => widget.onOpen(filtered[index])),
            )),
          ] else ...[
            _sectionHeader('وصول سريع', 'الأكثر استخداماً'),
            SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), sliver: SliverGrid.builder(
              itemCount: featured.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.55),
              itemBuilder: (context, index) => ToolCard(tool: featured[index], isFavorite: widget.favorites.contains(featured[index].id), onTap: () => widget.onOpen(featured[index])).animate().fadeIn(delay: (index * 55).ms).slideY(begin: 0.06),
            )),
            _sectionHeader('استكشف OMNI', '20 أداة في مكان واحد'),
            SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), sliver: SliverList.builder(
              itemCount: kTools.length,
              itemBuilder: (context, index) {
                final tool = kTools[index];
                return ToolListTile(tool: tool, isFavorite: widget.favorites.contains(tool.id), onTap: () => widget.onOpen(tool));
              },
            )),
          ],
        ],
      ),
    );
  }
}

SliverPadding _sectionHeader(String title, String subtitle) => SliverPadding(
  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
  sliver: SliverToBoxAdapter(child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 11))])),
    const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: kMuted),
  ])),
);

class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.tool, required this.onTap, required this.isFavorite});
  final ToolItem tool; final VoidCallback onTap; final bool isFavorite;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20), onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: tool.tint.withValues(alpha: 0.12))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: tool.tint.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)), child: Icon(tool.icon, color: tool.tint, size: 21)),
              const Spacer(),
              if (isFavorite) const Icon(Icons.favorite_rounded, color: Color(0xFFFF7A9D), size: 16),
              const Icon(Icons.arrow_outward_rounded, size: 15, color: kMuted),
            ]),
            const Spacer(),
            Text(tool.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 3),
            Text(tool.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}

class ToolListTile extends StatelessWidget {
  const ToolListTile({super.key, required this.tool, required this.onTap, required this.isFavorite});
  final ToolItem tool; final VoidCallback onTap; final bool isFavorite;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(17), child: InkWell(
      borderRadius: BorderRadius.circular(17), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: tool.tint.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)), child: Icon(tool.icon, color: tool.tint)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tool.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 3), Text(tool.subtitle, style: const TextStyle(color: kMuted, fontSize: 11))])),
        if (isFavorite) const Icon(Icons.favorite_rounded, color: Color(0xFFFF7A9D), size: 17),
        const SizedBox(width: 6), const Icon(Icons.chevron_left_rounded, color: kMuted),
      ])),
    )),
  );
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.onOpen, required this.favorites});
  final ValueChanged<ToolItem> onOpen; final List<String> favorites;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}
class _CatalogScreenState extends State<CatalogScreen> {
  String _category = 'الكل';
  final List<String> _categories = const ['الكل', 'الإنتاجية', 'أدوات يومية', 'الملفات', 'الألعاب', 'الإنترنت', 'التعلّم', 'التطوير', 'النصوص'];
  @override
  Widget build(BuildContext context) {
    final tools = _category == 'الكل' ? kTools : kTools.where((t) => t.category == _category).toList();
    return SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 14), child: Row(children: [const Expanded(child: Text('كل الأدوات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), Text('${tools.length} أداة', style: const TextStyle(color: kMuted, fontSize: 12))])),
      SizedBox(height: 42, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 20), scrollDirection: Axis.horizontal, itemCount: _categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, index) {
        final category = _categories[index]; final selected = _category == category;
        return ChoiceChip(label: Text(category), selected: selected, onSelected: (_) => setState(() => _category = category), selectedColor: kBlue.withValues(alpha: 0.25), side: BorderSide(color: selected ? kBlue : Theme.of(context).dividerColor), labelStyle: TextStyle(fontSize: 11, color: selected ? kBlue : null, fontWeight: FontWeight.w600));
      })),
      const SizedBox(height: 14),
      Expanded(child: GridView.builder(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), itemCount: tools.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.45), itemBuilder: (context, index) => ToolCard(tool: tools[index], isFavorite: widget.favorites.contains(tools[index].id), onTap: () => widget.onOpen(tools[index])))),
    ]));
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.onOpen, required this.favorites});
  final ValueChanged<ToolItem> onOpen; final List<String> favorites;
  @override
  Widget build(BuildContext context) {
    final tools = kTools.where((t) => favorites.contains(t.id)).toList();
    return SafeArea(child: Column(children: [
      const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 15), child: Row(children: [Expanded(child: Text('المفضلة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), Icon(Icons.favorite_rounded, color: Color(0xFFFF7A9D))])),
      Expanded(child: tools.isEmpty ? const EmptyState(icon: Icons.favorite_border_rounded, title: 'ما عندك أدوات مفضلة', subtitle: 'افتح أي أداة واضغط القلب حتى تظهر هنا.') : ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: tools.map((t) => ToolListTile(tool: t, isFavorite: true, onTap: () => onOpen(t))).toList())),
    ]));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.dark, required this.onDarkChanged});
  final bool dark; final ValueChanged<bool> onDarkChanged;
  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('الإعدادات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
    const SizedBox(height: 18),
    Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.dark_mode_rounded, color: kBlue), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الوضع الليلي', style: TextStyle(fontWeight: FontWeight.w700)), Text('اختر المظهر المناسب لك', style: TextStyle(fontSize: 11, color: kMuted))])), Switch(value: dark, onChanged: onDarkChanged)])),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('عن OMNI', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 7), Text('نسخة أولية من صندوق أدوات يومي. بعض الخدمات مثل الطقس واختصار الروابط تحتاج اتصالاً بالإنترنت.', style: TextStyle(color: kMuted, height: 1.6, fontSize: 12)), SizedBox(height: 8), Text('الإصدار 0.1.0', style: TextStyle(color: kBlue, fontSize: 11, fontWeight: FontWeight.w700))])),
  ]));
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title; final String subtitle;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 48, color: kMuted), const SizedBox(height: 14), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 6), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, height: 1.5, fontSize: 12))])));
}

class ToolRoute extends StatefulWidget {
  const ToolRoute({super.key, required this.tool, required this.isFavorite, required this.onFavorite});
  final ToolItem tool; final bool isFavorite; final VoidCallback onFavorite;
  @override
  State<ToolRoute> createState() => _ToolRouteState();
}
class _ToolRouteState extends State<ToolRoute> {
  late bool _favorite = widget.isFavorite;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.tool.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      actions: [IconButton(onPressed: () { widget.onFavorite(); setState(() => _favorite = !_favorite); }, icon: Icon(_favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _favorite ? const Color(0xFFFF7A9D) : null))],
    ),
    body: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(18, 6, 18, 18), child: _toolWidget(widget.tool.id))),
  );

  Widget _toolWidget(String id) {
    switch (id) {
      case 'calculator': return const CalculatorTool();
      case 'todo': return const TodoTool();
      case 'guess': return const GuessTool();
      case 'password': return const PasswordTool();
      case 'telegram': return const TelegramGuideTool();
      case 'currency': return const CurrencyTool();
      case 'timer': return const TimerTool();
      case 'notes': return const NotesTool();
      case 'wordcount': return const WordCountTool();
      case 'rps': return const RpsTool();
      case 'files': return const FilesTool();
      case 'prices': return const PriceLogTool();
      case 'snake': return const SnakeTool();
      case 'weather': return const WeatherTool();
      case 'expenses': return const ExpensesTool();
      case 'shortlink': return const ShortLinkTool();
      case 'quiz': return const QuizTool();
      case 'pdf': return const PdfTool();
      case 'qr': return const QrStudioTool();
      case 'website': return const WebsiteTool();
      default: return const EmptyState(icon: Icons.build_circle_outlined, title: 'الأداة غير متاحة', subtitle: 'هذه الأداة ستضاف في تحديث لاحق.');
    }
  }
}

class ToolPanel extends StatelessWidget {
  const ToolPanel({super.key, required this.child, this.title, this.subtitle});
  final Widget child; final String? title; final String? subtitle;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    if (title != null) Text(title!, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
    if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 5, bottom: 16), child: Text(subtitle!, style: const TextStyle(color: kMuted, fontSize: 12, height: 1.5))),
    child,
  ]));
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({super.key, required this.label, required this.onPressed, this.icon = Icons.arrow_forward_rounded});
  final String label; final VoidCallback? onPressed; final IconData icon;
  @override
  Widget build(BuildContext context) => FilledButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label), style: FilledButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))));
}

class CalculatorTool extends StatefulWidget { const CalculatorTool({super.key}); @override State<CalculatorTool> createState() => _CalculatorToolState(); }
class _CalculatorToolState extends State<CalculatorTool> {
  final a = TextEditingController(); final b = TextEditingController(); String op = '+'; String? result;
  @override void dispose() { a.dispose(); b.dispose(); super.dispose(); }
  void calculate() {
    final x = double.tryParse(a.text.trim()); final y = double.tryParse(b.text.trim());
    if (x == null || y == null) { setState(() => result = 'أدخل رقمين صحيحين'); return; }
    if (op == '÷' && y == 0) { setState(() => result = 'لا يمكن القسمة على صفر'); return; }
    final value = switch (op) {'+' => x + y, '−' => x - y, '×' => x * y, _ => x / y};
    setState(() => result = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 4));
  }
  @override Widget build(BuildContext context) => ToolPanel(title: 'حاسبة سريعة', subtitle: 'أدخل الرقمين واختر العملية الحسابية.', child: Column(children: [
    TextField(controller: a, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الرقم الأول')),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(value: op, items: ['+', '−', '×', '÷'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 19)))).toList(), onChanged: (v) => setState(() => op = v ?? '+'), decoration: const InputDecoration(labelText: 'العملية')),
    const SizedBox(height: 12),
    TextField(controller: b, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الرقم الثاني')),
    const SizedBox(height: 16), PrimaryAction(label: 'احسب النتيجة', onPressed: calculate, icon: Icons.calculate_rounded),
    if (result != null) _ResultBox(label: 'النتيجة', value: result!),
  ]));
}

class TodoTool extends StatefulWidget { const TodoTool({super.key}); @override State<TodoTool> createState() => _TodoToolState(); }
class _TodoToolState extends State<TodoTool> {
  final input = TextEditingController(); List<Map<String, dynamic>> items = []; bool loaded = false;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final list = await loadJsonList('todo_items'); if (!mounted) return; setState(() { items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList(); loaded = true; }); }
  Future<void> _save() => saveJson('todo_items', items);
  void add() { final value = input.text.trim(); if (value.isEmpty) return; setState(() { items.insert(0, {'text': value, 'done': false}); input.clear(); }); _save(); }
  @override void dispose() { input.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'قائمة مهامك', subtitle: 'المهام تحفظ على جهازك.', child: Column(children: [
    Row(children: [Expanded(child: TextField(controller: input, onSubmitted: (_) => add(), decoration: const InputDecoration(hintText: 'أضف مهمة جديدة'))), const SizedBox(width: 8), IconButton.filled(onPressed: add, icon: const Icon(Icons.add_rounded), style: IconButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white, fixedSize: const Size(52, 52)))]),
    const SizedBox(height: 12),
    if (!loaded) const LinearProgressIndicator(),
    if (items.isEmpty && loaded) const EmptyState(icon: Icons.task_alt_rounded, title: 'قائمتك فارغة', subtitle: 'أضف أول مهمة حتى تبدأ.'),
    ...items.asMap().entries.map((entry) { final i = entry.key; final item = entry.value; final done = item['done'] == true; return Card(color: Theme.of(context).cardColor, margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: Checkbox(value: done, onChanged: (v) { setState(() => items[i]['done'] = v ?? false); _save(); }), title: Text('${item['text'] ?? ''}', style: TextStyle(fontSize: 13, decoration: done ? TextDecoration.lineThrough : null, color: done ? kMuted : null)), trailing: IconButton(onPressed: () { setState(() => items.removeAt(i)); _save(); }, icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF8A9D))))); }),
  ]));
}

class GuessTool extends StatefulWidget { const GuessTool({super.key}); @override State<GuessTool> createState() => _GuessToolState(); }
class _GuessToolState extends State<GuessTool> {
  final guess = TextEditingController(); int target = Random().nextInt(20) + 1; String message = 'خمّن رقماً بين 1 و20'; int tries = 0; bool won = false;
  void check() { final n = int.tryParse(guess.text.trim()); if (n == null || n < 1 || n > 20) { showMessage(context, 'أدخل رقماً من 1 إلى 20'); return; } setState(() { tries++; if (n == target) { message = 'أحسنت! وجدت الرقم بعد $tries محاولة.'; won = true; } else { message = n < target ? 'أعلى من ذلك ↑' : 'أقل من ذلك ↓'; } }); }
  void reset() { setState(() { target = Random().nextInt(20) + 1; tries = 0; won = false; message = 'خمّن رقماً بين 1 و20'; guess.clear(); }); }
  @override void dispose() { guess.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'تحدي التخمين', subtitle: 'عندك عدد محاولات مفتوح. حاول توصل للرقم الصحيح.', child: Column(children: [Container(width: 150, height: 150, decoration: BoxDecoration(color: kBlue.withValues(alpha: .12), shape: BoxShape.circle), child: Icon(won ? Icons.emoji_events_rounded : Icons.casino_rounded, size: 70, color: kBlue)), const SizedBox(height: 18), Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 6), Text('المحاولات: $tries', style: const TextStyle(color: kMuted)), const SizedBox(height: 18), TextField(controller: guess, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: 'اكتب تخمينك')), const SizedBox(height: 12), PrimaryAction(label: won ? 'العب مرة أخرى' : 'تحقق', onPressed: won ? reset : check, icon: Icons.casino_rounded)]));
}

class PasswordTool extends StatefulWidget { const PasswordTool({super.key}); @override State<PasswordTool> createState() => _PasswordToolState(); }
class _PasswordToolState extends State<PasswordTool> {
  double length = 16; bool upper = true, lower = true, digits = true, symbols = true; String generated = '';
  void generate() { var chars = ''; if (upper) chars += 'ABCDEFGHJKLMNPQRSTUVWXYZ'; if (lower) chars += 'abcdefghijkmnopqrstuvwxyz'; if (digits) chars += '23456789'; if (symbols) chars += '!@#%&*_-+='; if (chars.isEmpty) { showMessage(context, 'فعّل نوعاً واحداً على الأقل'); return; } final random = Random.secure(); setState(() => generated = List.generate(length.round(), (_) => chars[random.nextInt(chars.length)]).join()); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'مولّد كلمات المرور', subtitle: 'تُنشأ الكلمة على جهازك ولا يتم إرسالها لأي جهة.', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    _OptionTile(title: 'أحرف كبيرة', value: upper, onChanged: (v) => setState(() => upper = v)), _OptionTile(title: 'أحرف صغيرة', value: lower, onChanged: (v) => setState(() => lower = v)), _OptionTile(title: 'أرقام', value: digits, onChanged: (v) => setState(() => digits = v)), _OptionTile(title: 'رموز', value: symbols, onChanged: (v) => setState(() => symbols = v)),
    const SizedBox(height: 8), Text('طول كلمة المرور: ${length.round()}', style: const TextStyle(fontWeight: FontWeight.w700)), Slider(value: length, min: 8, max: 40, divisions: 32, onChanged: (v) => setState(() => length = v)),
    PrimaryAction(label: 'إنشاء كلمة مرور', onPressed: generate, icon: Icons.key_rounded),
    if (generated.isNotEmpty) Container(margin: const EdgeInsets.only(top: 14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: kBlue.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: Row(children: [Expanded(child: SelectableText(generated, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 1.1))), IconButton(onPressed: () { Clipboard.setData(ClipboardData(text: generated)); showMessage(context, 'تم نسخ كلمة المرور'); }, icon: const Icon(Icons.copy_rounded))])),
  ]));
}

class TelegramGuideTool extends StatelessWidget { const TelegramGuideTool({super.key});
  @override Widget build(BuildContext context) => ToolPanel(title: 'دليل إنشاء بوت تيليجرام', subtitle: 'مساعد تجهيز مختصر. لا يطلب منك إدخال أو مشاركة رمز البوت هنا.', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const _InfoStep(number: '01', title: 'افتح BotFather داخل تيليجرام', text: 'هذه هي الأداة الرسمية لإدارة إنشاء البوتات.'),
    const _InfoStep(number: '02', title: 'ابدأ محادثة جديدة', text: 'اتبع تعليمات BotFather واختر أمر إنشاء بوت جديد.'),
    const _InfoStep(number: '03', title: 'احتفظ بالرمز بسرية', text: 'رمز البوت مثل كلمة المرور. لا ترسله لأي شخص ولا تضعه داخل تطبيق منشور.'),
    const _InfoStep(number: '04', title: 'اربطه بخادم آمن', text: 'يحتاج البوت إلى برنامج يعمل على خادم أو استضافة حتى يرد على المستخدمين.'),
    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFB84D).withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: const Text('تنبيه أمان: لا تلصق مفاتيح API أو رموز الدخول في المحادثات أو الصور أو مستودعات GitHub العامة.', style: TextStyle(fontSize: 12, height: 1.6))),
  ]));
}

class CurrencyTool extends StatefulWidget { const CurrencyTool({super.key}); @override State<CurrencyTool> createState() => _CurrencyToolState(); }
class _CurrencyToolState extends State<CurrencyTool> {
  final amount = TextEditingController(text: '1'); final rate = TextEditingController(text: ''); String result = 'أدخل سعر الصرف الحالي بنفسك';
  void convert() { final a = double.tryParse(amount.text); final r = double.tryParse(rate.text); if (a == null || r == null || r <= 0) { setState(() => result = 'تحقق من المبلغ وسعر الصرف'); return; } setState(() => result = (a * r).toStringAsFixed(2)); }
  @override void dispose() { amount.dispose(); rate.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'محول العملات', subtitle: 'محول يدوي يعمل دون إنترنت. أدخل السعر الذي تريد الحساب عليه؛ لا يتم جلب أسعار مباشرة.', child: Column(children: [TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المبلغ')), const SizedBox(height: 12), TextField(controller: rate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعر الصرف اليدوي')), const SizedBox(height: 16), PrimaryAction(label: 'حوّل المبلغ', onPressed: convert, icon: Icons.currency_exchange_rounded), _ResultBox(label: 'الناتج', value: result)]));
}

class TimerTool extends StatefulWidget { const TimerTool({super.key}); @override State<TimerTool> createState() => _TimerToolState(); }
class _TimerToolState extends State<TimerTool> {
  int seconds = 300; int remaining = 300; Timer? timer; bool running = false;
  String get display => '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';
  void start() { if (running) return; if (remaining == 0) remaining = seconds; setState(() => running = true); timer = Timer.periodic(const Duration(seconds: 1), (t) { if (remaining <= 1) { t.cancel(); if (mounted) setState(() { remaining = 0; running = false; }); } else if (mounted) { setState(() => remaining--); } }); }
  void pause() { timer?.cancel(); setState(() => running = false); }
  void reset() { timer?.cancel(); setState(() { running = false; remaining = seconds; }); }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'مؤقت التركيز', subtitle: 'اختَر مدة مناسبة، ثم ابدأ. يعمل المؤقت داخل التطبيق.', child: Column(children: [Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: kBlue.withValues(alpha: .10), border: Border.all(color: kBlue.withValues(alpha: .45), width: 8)), child: Center(child: Text(display, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()])))), const SizedBox(height: 20), Wrap(spacing: 8, children: [for (final m in [5, 10, 15, 25, 45]) ChoiceChip(label: Text('$m دقيقة'), selected: seconds == m * 60, onSelected: running ? null : (_) => setState(() { seconds = m * 60; remaining = seconds; }))]), const SizedBox(height: 18), Row(children: [Expanded(child: PrimaryAction(label: running ? 'إيقاف مؤقت' : 'ابدأ', onPressed: running ? pause : start, icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded)), const SizedBox(width: 10), IconButton.filledTonal(onPressed: reset, icon: const Icon(Icons.replay_rounded), style: IconButton.styleFrom(fixedSize: const Size(52, 52)))]) ]));
}

class NotesTool extends StatefulWidget { const NotesTool({super.key}); @override State<NotesTool> createState() => _NotesToolState(); }
class _NotesToolState extends State<NotesTool> {
  final note = TextEditingController(); Timer? debounce; bool loaded = false;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await _prefs; if (!mounted) return; note.text = p.getString('omni_note') ?? ''; setState(() => loaded = true); }
  void _scheduleSave(String value) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 450), () async { final p = await _prefs; await p.setString('omni_note', value); if (mounted) showMessage(context, 'تم حفظ الملاحظة'); }); }
  @override void dispose() { debounce?.cancel(); note.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'دفتر الملاحظات', subtitle: loaded ? 'تُحفظ ملاحظاتك تلقائياً على هذا الجهاز.' : 'جارٍ تحميل الملاحظة...', child: TextField(controller: note, minLines: 12, maxLines: 24, onChanged: _scheduleSave, decoration: const InputDecoration(hintText: 'اكتب فكرتك هنا...', alignLabelWithHint: true)));
}

class WordCountTool extends StatefulWidget { const WordCountTool({super.key}); @override State<WordCountTool> createState() => _WordCountToolState(); }
class _WordCountToolState extends State<WordCountTool> {
  final text = TextEditingController();
  @override void dispose() { text.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final words = text.text.trim().isEmpty ? 0 : text.text.trim().split(RegExp(r'\s+')).length; return ToolPanel(title: 'عداد النصوص', subtitle: 'اكتب أو الصق النص لمعرفة إحصاءاته.', child: Column(children: [TextField(controller: text, onChanged: (_) => setState(() {}), minLines: 8, maxLines: 18, decoration: const InputDecoration(hintText: 'الصق النص هنا...', alignLabelWithHint: true)), const SizedBox(height: 14), Row(children: [Expanded(child: _StatCard(title: 'الكلمات', value: '$words')), const SizedBox(width: 9), Expanded(child: _StatCard(title: 'الحروف', value: '${text.text.replaceAll(RegExp(r'\s'), '').length}')), const SizedBox(width: 9), Expanded(child: _StatCard(title: 'المسافات', value: '${RegExp(r'\s').allMatches(text.text).length}'))]), const SizedBox(height: 10), OutlinedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: text.text)); showMessage(context, 'تم نسخ النص'); }, icon: const Icon(Icons.copy_rounded), label: const Text('نسخ النص'))])); }
}

class RpsTool extends StatefulWidget { const RpsTool({super.key}); @override State<RpsTool> createState() => _RpsToolState(); }
class _RpsToolState extends State<RpsTool> {
  final options = ['حجر', 'ورقة', 'مقص']; final icons = [Icons.circle_rounded, Icons.description_rounded, Icons.content_cut_rounded]; String? user, cpu, result; int wins = 0, losses = 0, draws = 0;
  void play(String choice) { final other = options[Random().nextInt(3)]; final outcome = choice == other ? 'تعادل!' : ((choice == 'حجر' && other == 'مقص') || (choice == 'ورقة' && other == 'حجر') || (choice == 'مقص' && other == 'ورقة')) ? 'فزت بالجولة!' : 'فاز الجهاز هذه المرة'; setState(() { user = choice; cpu = other; result = outcome; if (outcome == 'تعادل!') draws++; else if (outcome.startsWith('فزت')) wins++; else losses++; }); }
  @override
  Widget build(BuildContext context) => ToolPanel(
    title: 'حجر · ورقة · مقص',
    subtitle: 'اختر حركة واحدة وشاهد نتيجة الجولة.',
    child: Column(children: [
      Row(children: [
        Expanded(child: _StatCard(title: 'فوزك', value: '$wins')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'تعادل', value: '$draws')),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'خسارة', value: '$losses')),
      ]),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _ChoiceBox(label: 'اختيارك', value: user)),
        const SizedBox(width: 12),
        Expanded(child: _ChoiceBox(label: 'اختيار الجهاز', value: cpu)),
      ]),
      const SizedBox(height: 18),
      Text(result ?? 'جاهز للجولة؟', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      Row(children: List.generate(3, (i) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FilledButton.tonal(
            onPressed: () => play(options[i]),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
            child: Column(children: [
              Icon(icons[i], size: 23),
              const SizedBox(height: 5),
              Text(options[i], style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ),
      ))),
    ]),
  );
}

class FilesTool extends StatefulWidget { const FilesTool({super.key}); @override State<FilesTool> createState() => _FilesToolState(); }
class _FilesToolState extends State<FilesTool> {
  List<PlatformFile> files = [];
  Future<void> pick() async { try { final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: false); if (result == null) return; setState(() => files = result.files); } catch (e) { if (mounted) showMessage(context, 'تعذر فتح الملفات: $e'); } }
  String sizeLabel(int bytes) { if (bytes < 1024) return '$bytes B'; if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB'; return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'; }
  @override Widget build(BuildContext context) => ToolPanel(title: 'مستعرض الملفات', subtitle: 'افتح منتقي ملفات أندرويد واختر ملفاً أو أكثر. لا ينقل التطبيق ملفاتك أو يرفعها.', child: Column(children: [PrimaryAction(label: 'اختيار الملفات', onPressed: pick, icon: Icons.folder_open_rounded), const SizedBox(height: 14), if (files.isEmpty) const EmptyState(icon: Icons.folder_copy_outlined, title: 'لم تختر ملفات بعد', subtitle: 'يمكنك اختيار عدة ملفات من ذاكرة الجهاز أو من مزود ملفات متصل.'), ...files.map((f) => Card(color: Theme.of(context).cardColor, child: ListTile(leading: const Icon(Icons.insert_drive_file_outlined, color: kBlue), title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)), subtitle: Text(sizeLabel(f.size), style: const TextStyle(color: kMuted, fontSize: 10)))))]));
}

class PriceLogTool extends StatefulWidget { const PriceLogTool({super.key}); @override State<PriceLogTool> createState() => _PriceLogToolState(); }
class _PriceLogToolState extends State<PriceLogTool> {
  final name = TextEditingController(); final price = TextEditingController(); List<Map<String, dynamic>> rows = [];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final list = await loadJsonList('price_log'); if (!mounted) return; setState(() => rows = list.map((e) => Map<String, dynamic>.from(e as Map)).toList()); }
  Future<void> _save() => saveJson('price_log', rows);
  void add() { final n = name.text.trim(); final p = double.tryParse(price.text.trim()); if (n.isEmpty || p == null || p < 0) { showMessage(context, 'أدخل اسم المنتج وسعراً صحيحاً'); return; } setState(() { rows.insert(0, {'name': n, 'price': p}); name.clear(); price.clear(); }); _save(); }
  @override void dispose() { name.dispose(); price.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'سجل الأسعار', subtitle: 'سجل يدوي للأسعار للمقارنة لاحقاً. لا يقوم بسحب الأسعار تلقائياً من المتاجر.', child: Column(children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المنتج أو الخدمة')), const SizedBox(height: 10), TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'السعر')), const SizedBox(height: 12), PrimaryAction(label: 'أضف إلى السجل', onPressed: add, icon: Icons.add_rounded), const SizedBox(height: 14), ...rows.asMap().entries.map((e) => Card(color: Theme.of(context).cardColor, child: ListTile(title: Text('${e.value['name']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), subtitle: Text('${e.value['price']}', style: const TextStyle(color: kBlue)), trailing: IconButton(onPressed: () { setState(() => rows.removeAt(e.key)); _save(); }, icon: const Icon(Icons.delete_outline_rounded)))))]));
}

class SnakeTool extends StatefulWidget { const SnakeTool({super.key}); @override State<SnakeTool> createState() => _SnakeToolState(); }
class _SnakeToolState extends State<SnakeTool> {
  static const int size = 12;
  List<Point<int>> snake = [const Point(5, 6), const Point(4, 6), const Point(3, 6)];
  Point<int> direction = const Point(1, 0); Point<int> food = const Point(8, 6); Timer? timer; bool running = false, over = false; int score = 0;
  void start() { if (running) return; if (over) reset(); setState(() => running = true); timer = Timer.periodic(const Duration(milliseconds: 260), (_) => tick()); }
  void pause() { timer?.cancel(); setState(() => running = false); }
  void reset() { timer?.cancel(); setState(() { snake = [const Point(5, 6), const Point(4, 6), const Point(3, 6)]; direction = const Point(1, 0); food = const Point(8, 6); score = 0; over = false; running = false; }); }
  void change(Point<int> d) { if (d.x == -direction.x && d.y == -direction.y) return; setState(() => direction = d); }
  void tick() { final head = snake.first; final next = Point(head.x + direction.x, head.y + direction.y); if (next.x < 0 || next.y < 0 || next.x >= size || next.y >= size || snake.contains(next)) { timer?.cancel(); setState(() { over = true; running = false; }); return; } setState(() { snake.insert(0, next); if (next == food) { score++; _spawnFood(); } else { snake.removeLast(); } }); }
  void _spawnFood() { final r = Random(); Point<int> next; do { next = Point(r.nextInt(size), r.nextInt(size)); } while (snake.contains(next)); food = next; }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'لعبة الثعبان', subtitle: 'اجمع النقاط وتجنب الاصطدام. استخدم الأسهم للتحكم.', child: Column(children: [Row(children: [Expanded(child: _StatCard(title: 'النقاط', value: '$score')), const SizedBox(width: 10), Expanded(child: _StatCard(title: 'الحالة', value: over ? 'انتهت' : running ? 'تعمل' : 'متوقفة'))]), const SizedBox(height: 12), AspectRatio(aspectRatio: 1, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFF101A2D), borderRadius: BorderRadius.circular(16)), child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: size * size, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: size), itemBuilder: (_, i) { final p = Point(i % size, i ~/ size); final isHead = p == snake.first; final isBody = snake.contains(p); final isFood = p == food; return Container(margin: const EdgeInsets.all(1), decoration: BoxDecoration(color: isHead ? kCyan : isBody ? const Color(0xFF328F83) : isFood ? const Color(0xFFFFC56D) : const Color(0xFF1B2940), borderRadius: BorderRadius.circular(3))); }))), const SizedBox(height: 14), if (over) const Text('انتهت اللعبة! جرّب مرة أخرى.', style: TextStyle(color: Color(0xFFFF8A9D), fontWeight: FontWeight.w700)), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton.filledTonal(onPressed: () => change(const Point(0, -1)), icon: const Icon(Icons.keyboard_arrow_up_rounded)), const SizedBox(width: 6), IconButton.filledTonal(onPressed: () => change(const Point(-1, 0)), icon: const Icon(Icons.keyboard_arrow_left_rounded)), const SizedBox(width: 6), IconButton.filledTonal(onPressed: () => change(const Point(1, 0)), icon: const Icon(Icons.keyboard_arrow_right_rounded)), const SizedBox(width: 6), IconButton.filledTonal(onPressed: () => change(const Point(0, 1)), icon: const Icon(Icons.keyboard_arrow_down_rounded))]), const SizedBox(height: 8), Row(children: [Expanded(child: PrimaryAction(label: running ? 'إيقاف' : 'ابدأ', onPressed: running ? pause : start, icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded)), const SizedBox(width: 9), IconButton.filledTonal(onPressed: reset, icon: const Icon(Icons.replay_rounded), style: IconButton.styleFrom(fixedSize: const Size(52, 52)))]) ]));
}

class WeatherTool extends StatefulWidget { const WeatherTool({super.key}); @override State<WeatherTool> createState() => _WeatherToolState(); }
class _WeatherToolState extends State<WeatherTool> {
  final city = TextEditingController(); bool loading = false; String? error; String? description; double? temp; double? wind;
  Future<void> fetchWeather() async {
    final q = city.text.trim(); if (q.isEmpty) { showMessage(context, 'اكتب اسم المدينة'); return; }
    setState(() { loading = true; error = null; });
    try {
      final geo = await http.get(Uri.https('geocoding-api.open-meteo.com', '/v1/search', {'name': q, 'count': '1', 'language': 'ar', 'format': 'json'})).timeout(const Duration(seconds: 12));
      if (geo.statusCode != 200) throw Exception('تعذر الوصول إلى خدمة تحديد المدينة');
      final places = (jsonDecode(geo.body)['results'] as List?) ?? [];
      if (places.isEmpty) throw Exception('لم نعثر على المدينة');
      final place = places.first as Map;
      final forecast = await http.get(Uri.https('api.open-meteo.com', '/v1/forecast', {'latitude': '${place['latitude']}', 'longitude': '${place['longitude']}', 'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m', 'timezone': 'auto'})).timeout(const Duration(seconds: 12));
      if (forecast.statusCode != 200) throw Exception('تعذر جلب حالة الطقس');
      final current = jsonDecode(forecast.body)['current'] as Map;
      if (!mounted) return;
      setState(() { temp = (current['temperature_2m'] as num).toDouble(); wind = (current['wind_speed_10m'] as num).toDouble(); description = '${place['name']}, ${place['country'] ?? ''}'; });
    } catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override void dispose() { city.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'حالة الطقس', subtitle: 'يحتاج اتصال إنترنت. تُجلب البيانات من Open-Meteo بعد إدخال اسم المدينة.', child: Column(children: [TextField(controller: city, onSubmitted: (_) => fetchWeather(), decoration: const InputDecoration(labelText: 'اسم المدينة', hintText: 'مثلاً: الناصرية')), const SizedBox(height: 12), PrimaryAction(label: loading ? 'جارٍ البحث...' : 'اعرض الطقس', onPressed: loading ? null : fetchWeather, icon: Icons.cloud_sync_rounded), if (error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(error!, style: const TextStyle(color: Color(0xFFFF8A9D)))), if (temp != null) Container(margin: const EdgeInsets.only(top: 18), padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF29477B), Color(0xFF1A304D)])), child: Column(children: [const Icon(Icons.cloud_rounded, color: Colors.white, size: 46), const SizedBox(height: 8), Text(description ?? '', style: const TextStyle(color: Colors.white70)), Text('${temp!.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 46, color: Colors.white, fontWeight: FontWeight.w900)), Text('سرعة الرياح ${wind!.toStringAsFixed(1)} كم/س', style: const TextStyle(color: Colors.white70))]))]));
}

class ExpensesTool extends StatefulWidget { const ExpensesTool({super.key}); @override State<ExpensesTool> createState() => _ExpensesToolState(); }
class _ExpensesToolState extends State<ExpensesTool> {
  final title = TextEditingController(); final amount = TextEditingController(); List<Map<String, dynamic>> expenses = [];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final l = await loadJsonList('expenses'); if (!mounted) return; setState(() => expenses = l.map((e) => Map<String, dynamic>.from(e as Map)).toList()); }
  Future<void> _save() => saveJson('expenses', expenses);
  void add() { final t = title.text.trim(); final a = double.tryParse(amount.text.trim()); if (t.isEmpty || a == null || a <= 0) { showMessage(context, 'أدخل وصفاً ومبلغاً صحيحاً'); return; } setState(() { expenses.insert(0, {'title': t, 'amount': a, 'date': DateTime.now().toIso8601String()}); title.clear(); amount.clear(); }); _save(); }
  @override void dispose() { title.dispose(); amount.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final total = expenses.fold<double>(0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0)); return ToolPanel(title: 'متابعة المصاريف', subtitle: 'سجل مبالغك محلياً. لا توجد مزامنة مالية أو ربط بحساب مصرفي.', child: Column(children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: kBlue.withValues(alpha: .13), borderRadius: BorderRadius.circular(18)), child: Column(children: [const Text('إجمالي المصروفات المسجلة', style: TextStyle(color: kMuted, fontSize: 11)), const SizedBox(height: 6), Text(total.toStringAsFixed(2), style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900, color: kBlue))])), const SizedBox(height: 14), TextField(controller: title, decoration: const InputDecoration(labelText: 'وصف المصروف')), const SizedBox(height: 10), TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المبلغ')), const SizedBox(height: 12), PrimaryAction(label: 'أضف المصروف', onPressed: add, icon: Icons.add_rounded), const SizedBox(height: 12), ...expenses.asMap().entries.map((e) => Card(color: Theme.of(context).cardColor, child: ListTile(title: Text('${e.value['title']}', style: const TextStyle(fontSize: 13)), subtitle: Text('${e.value['amount']}', style: const TextStyle(color: kBlue)), trailing: IconButton(onPressed: () { setState(() => expenses.removeAt(e.key)); _save(); }, icon: const Icon(Icons.delete_outline_rounded)))))])); }
}

class ShortLinkTool extends StatefulWidget { const ShortLinkTool({super.key}); @override State<ShortLinkTool> createState() => _ShortLinkToolState(); }
class _ShortLinkToolState extends State<ShortLinkTool> {
  final link = TextEditingController(); String? output; bool loading = false;
  Future<void> shorten() async { final raw = link.text.trim(); final uri = Uri.tryParse(raw); if (uri == null || !['http', 'https'].contains(uri.scheme) || uri.host.isEmpty) { showMessage(context, 'أدخل رابطاً يبدأ بـ https:// أو http://'); return; } setState(() { loading = true; output = null; }); try { final response = await http.get(Uri.https('is.gd', '/create.php', {'format': 'simple', 'url': raw})).timeout(const Duration(seconds: 15)); if (response.statusCode != 200 || response.body.startsWith('Error')) throw Exception(response.body); if (mounted) setState(() => output = response.body.trim()); } catch (e) { if (mounted) showMessage(context, 'تعذر اختصار الرابط: ${e.toString().replaceFirst('Exception: ', '')}'); } finally { if (mounted) setState(() => loading = false); } }
  @override void dispose() { link.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'مختصر الروابط', subtitle: 'تحتاج الأداة إلى إنترنت وتستخدم خدمة is.gd خارج التطبيق. لا ترسل روابط خاصة أو حساسة.', child: Column(children: [TextField(controller: link, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'الرابط الطويل', hintText: 'https://example.com')), const SizedBox(height: 12), PrimaryAction(label: loading ? 'جارٍ الاختصار...' : 'اختصر الرابط', onPressed: loading ? null : shorten, icon: Icons.link_rounded), if (output != null) Container(margin: const EdgeInsets.only(top: 14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: kBlue.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: Row(children: [Expanded(child: SelectableText(output!, style: const TextStyle(color: kBlue, fontWeight: FontWeight.w800))), IconButton(onPressed: () { Clipboard.setData(ClipboardData(text: output!)); showMessage(context, 'تم نسخ الرابط'); }, icon: const Icon(Icons.copy_rounded))]))]));
}

class QuizTool extends StatefulWidget { const QuizTool({super.key}); @override State<QuizTool> createState() => _QuizToolState(); }
class _QuizToolState extends State<QuizTool> {
  final questions = const [
    ('ما الكوكب المعروف بالكوكب الأحمر؟', ['الأرض', 'المريخ', 'الزهرة', 'زحل'], 1),
    ('كم عدد أضلاع المثلث؟', ['2', '3', '4', '5'], 1),
    ('ما وحدة قياس شدة التيار الكهربائي؟', ['الفولت', 'الأوم', 'الأمبير', 'الواط'], 2),
    ('أي غاز تمتصه النباتات غالباً في البناء الضوئي؟', ['الأوكسجين', 'النيتروجين', 'ثاني أكسيد الكربون', 'الهيدروجين'], 2),
  ];
  int index = 0, score = 0; bool answered = false; int? selected;
  void choose(int i) { if (answered) return; setState(() { selected = i; answered = true; if (i == questions[index].$3) score++; }); }
  void next() { setState(() { index++; answered = false; selected = null; }); }
  void restart() { setState(() { index = 0; score = 0; answered = false; selected = null; }); }
  @override Widget build(BuildContext context) { if (index >= questions.length) return ToolPanel(title: 'انتهى الاختبار', subtitle: 'هذه نتيجتك في الجولة.', child: Column(children: [const Icon(Icons.emoji_events_rounded, size: 68, color: Color(0xFFFFC56D)), Text('$score / ${questions.length}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)), const SizedBox(height: 16), PrimaryAction(label: 'إعادة الاختبار', onPressed: restart, icon: Icons.replay_rounded)])); final q = questions[index]; return ToolPanel(title: 'اختبار معلومات عامة', subtitle: 'السؤال ${index + 1} من ${questions.length} · النقاط $score', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [LinearProgressIndicator(value: (index + 1) / questions.length, minHeight: 7, borderRadius: BorderRadius.circular(10)), const SizedBox(height: 22), Text(q.$1, style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w800)), const SizedBox(height: 16), ...List.generate(q.$2.length, (i) { final correct = i == q.$3; final chosen = selected == i; Color? bg; if (answered && correct) bg = const Color(0xFF1E7D68); else if (answered && chosen) bg = const Color(0xFF8B3949); return Padding(padding: const EdgeInsets.only(bottom: 9), child: SizedBox(height: 52, child: OutlinedButton(onPressed: () => choose(i), style: OutlinedButton.styleFrom(backgroundColor: bg?.withValues(alpha: .20), side: BorderSide(color: bg ?? Theme.of(context).dividerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Align(alignment: Alignment.centerRight, child: Text(q.$2[i], style: const TextStyle(fontWeight: FontWeight.w700)))))); }), if (answered) Padding(padding: const EdgeInsets.only(top: 8), child: Text(selected == q.$3 ? 'إجابة صحيحة!' : 'الإجابة الصحيحة: ${q.$2[q.$3]}', style: TextStyle(color: selected == q.$3 ? kCyan : const Color(0xFFFF9BA8), fontWeight: FontWeight.w800))), const SizedBox(height: 12), if (answered) PrimaryAction(label: index == questions.length - 1 ? 'عرض النتيجة' : 'السؤال التالي', onPressed: next, icon: Icons.arrow_back_rounded)])); }
}

class PdfTool extends StatefulWidget { const PdfTool({super.key}); @override State<PdfTool> createState() => _PdfToolState(); }
class _PdfToolState extends State<PdfTool> {
  Future<void> openPdf() async { try { final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']); if (result == null || result.files.single.path == null) return; if (!mounted) return; Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PdfReaderPage(path: result.files.single.path!, name: result.files.single.name))); } catch (e) { if (mounted) showMessage(context, 'تعذر فتح ملف PDF: $e'); } }
  @override Widget build(BuildContext context) => ToolPanel(title: 'قارئ PDF', subtitle: 'اختر ملف PDF من جهازك لعرضه داخل التطبيق.', child: Column(children: [Container(height: 170, decoration: BoxDecoration(color: const Color(0xFFFF8585).withValues(alpha: .10), borderRadius: BorderRadius.circular(20)), child: const Center(child: Icon(Icons.picture_as_pdf_rounded, size: 75, color: Color(0xFFFF8585)))), const SizedBox(height: 18), PrimaryAction(label: 'اختيار ملف PDF', onPressed: openPdf, icon: Icons.upload_file_rounded)]));
}
class PdfReaderPage extends StatelessWidget {
  const PdfReaderPage({super.key, required this.path, required this.name});
  final String path, name;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)), body: PdfViewer.file(File(path)));
}

class QrStudioTool extends StatefulWidget { const QrStudioTool({super.key}); @override State<QrStudioTool> createState() => _QrStudioToolState(); }
class _QrStudioToolState extends State<QrStudioTool> {
  final content = TextEditingController(); String data = ''; bool scanMode = false;
  @override void dispose() { content.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'استوديو QR والباركود', subtitle: 'أنشئ رمز QR من نص أو رابط، أو افتح الكاميرا لمسح رمز. الإنشاء يعمل دون إنترنت.', child: Column(children: [SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('إنشاء QR'), icon: Icon(Icons.qr_code_2_rounded)), ButtonSegment(value: true, label: Text('مسح رمز'), icon: Icon(Icons.qr_code_scanner_rounded))], selected: {scanMode}, onSelectionChanged: (v) { if (v.first) { Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QrScannerPage())).then((_) { if (mounted) setState(() => scanMode = false); }); } else { setState(() => scanMode = false); } }), const SizedBox(height: 16), if (!scanMode) ...[TextField(controller: content, maxLines: 3, decoration: const InputDecoration(labelText: 'النص أو الرابط', hintText: 'اكتب ما تريد تحويله إلى QR')), const SizedBox(height: 12), PrimaryAction(label: 'إنشاء الرمز', onPressed: () { if (content.text.trim().isEmpty) { showMessage(context, 'اكتب نصاً أولاً'); return; } setState(() => data = content.text.trim()); }, icon: Icons.auto_awesome_rounded), if (data.isNotEmpty) Container(margin: const EdgeInsets.only(top: 18), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [QrImageView(data: data, version: QrVersions.auto, size: 220, backgroundColor: Colors.white), const SizedBox(height: 8), Text('OMNI QR', style: TextStyle(color: Colors.black.withValues(alpha: .6), fontWeight: FontWeight.w800, letterSpacing: 2))]))]]));
}
class QrScannerPage extends StatefulWidget { const QrScannerPage({super.key}); @override State<QrScannerPage> createState() => _QrScannerPageState(); }
class _QrScannerPageState extends State<QrScannerPage> {
  String? result;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('ماسح QR والباركود')), body: Stack(children: [MobileScanner(onDetect: (capture) { final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null; if (code != null && code.isNotEmpty && result == null) setState(() => result = code); }), Align(alignment: Alignment.bottomCenter, child: Container(width: double.infinity, margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kInk.withValues(alpha: .92), borderRadius: BorderRadius.circular(18)), child: result == null ? const Text('وجّه الكاميرا نحو الرمز', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)) : Column(mainAxisSize: MainAxisSize.min, children: [const Text('تم العثور على الرمز', style: TextStyle(color: kCyan, fontWeight: FontWeight.w800)), const SizedBox(height: 8), SelectableText(result!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)), const SizedBox(height: 8), Row(children: [Expanded(child: OutlinedButton(onPressed: () { Clipboard.setData(ClipboardData(text: result!)); showMessage(context, 'تم النسخ'); }, child: const Text('نسخ'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () => setState(() => result = null), child: const Text('مسح رمز آخر')))])])))]));
}

class WebsiteTool extends StatefulWidget { const WebsiteTool({super.key}); @override State<WebsiteTool> createState() => _WebsiteToolState(); }
class _WebsiteToolState extends State<WebsiteTool> {
  final title = TextEditingController(text: 'صفحتي الأولى'); final body = TextEditingController(text: 'مرحباً بك في موقعي الجديد!'); String html = '';
  String escapeHtml(String value) => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#39;');
  void generate() { final safeTitle = escapeHtml(title.text); final safeBody = escapeHtml(body.text).replaceAll('\n', '<br>'); setState(() => html = '''<!doctype html>
<html lang="ar" dir="rtl">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>$safeTitle</title><style>body{margin:0;min-height:100vh;display:grid;place-items:center;background:#0b1220;color:#f4f7ff;font-family:Arial,sans-serif}.card{max-width:650px;margin:24px;padding:42px;border-radius:24px;background:#17243b;box-shadow:0 20px 70px #0005}h1{color:#8ea7ff}p{line-height:1.9;color:#c5d2ea}</style></head>
<body><main class="card"><h1>$safeTitle</h1><p>$safeBody</p></main></body></html>'''); }
  @override void dispose() { title.dispose(); body.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => ToolPanel(title: 'منشئ صفحة ويب', subtitle: 'اكتب عنواناً ونصاً، ثم أنشئ قالب HTML بسيطاً يمكنك نسخه وتعديله.', child: Column(children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان الصفحة')), const SizedBox(height: 10), TextField(controller: body, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'محتوى الصفحة', alignLabelWithHint: true)), const SizedBox(height: 12), PrimaryAction(label: 'إنشاء كود الصفحة', onPressed: generate, icon: Icons.code_rounded), if (html.isNotEmpty) Container(margin: const EdgeInsets.only(top: 14), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: Column(children: [const Row(children: [Icon(Icons.code_rounded, color: kCyan), SizedBox(width: 8), Text('كود HTML', style: TextStyle(fontWeight: FontWeight.w800))]), const SizedBox(height: 8), SizedBox(height: 180, child: SingleChildScrollView(child: SelectableText(html, style: const TextStyle(fontSize: 10, height: 1.45, fontFamily: 'monospace')))), const SizedBox(height: 8), OutlinedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: html)); showMessage(context, 'تم نسخ كود الصفحة'); }, icon: const Icon(Icons.copy_rounded), label: const Text('نسخ الكود'))]))]));
}

class _ResultBox extends StatelessWidget { const _ResultBox({required this.label, required this.value}); final String label, value; @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(16), width: double.infinity, decoration: BoxDecoration(color: kBlue.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: Column(children: [Text(label, style: const TextStyle(color: kMuted, fontSize: 11)), const SizedBox(height: 5), SelectableText(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: kBlue))])); }
class _StatCard extends StatelessWidget { const _StatCard({required this.title, required this.value}); final String title, value; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15)), child: Column(children: [Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 10, color: kMuted))])); }
class _OptionTile extends StatelessWidget { const _OptionTile({required this.title, required this.value, required this.onChanged}); final String title; final bool value; final ValueChanged<bool> onChanged; @override Widget build(BuildContext context) => SwitchListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(title, style: const TextStyle(fontSize: 13)), value: value, onChanged: onChanged); }
class _InfoStep extends StatelessWidget { const _InfoStep({required this.number, required this.title, required this.text}); final String number, title, text; @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: kBlue.withValues(alpha: .15), borderRadius: BorderRadius.circular(12)), child: Text(number, style: const TextStyle(color: kBlue, fontWeight: FontWeight.w900))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(text, style: const TextStyle(color: kMuted, height: 1.5, fontSize: 11))]))])); }
class _ChoiceBox extends StatelessWidget { const _ChoiceBox({required this.label, required this.value}); final String label; final String? value; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18)), child: Column(children: [Text(label, style: const TextStyle(color: kMuted, fontSize: 11)), const SizedBox(height: 8), Text(value ?? '—', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: kBlue))])); }
