// JUMLA — Home · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/product_card.dart';
import '../widgets/ui.dart';
import 'rfq_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProductCategory> _cats = [];
  List<Product> _featured = [], _latest = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.i.get('/home');
      final d = r.data as Map;
      if (!mounted) return;
      setState(() {
        _cats = (d['categories'] as List).map((e) => ProductCategory.fromJson(e)).toList();
        _featured = (d['featured'] as List).map((e) => Product.fromJson(e)).toList();
        _latest = (d['latest'] as List).map((e) => Product.fromJson(e)).toList();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _openShop({String? cat, String? catName, bool search = false}) {
    Navigator.of(context).push(slideRoute(ShopScreen(standalone: true, category: cat, categoryName: catName, autofocusSearch: search)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final site = s.config?.site;
    return Scaffold(
      backgroundColor: C.bg,
      body: LargeTitlePage(
        title: site?.nameAr.isNotEmpty == true ? site!.nameAr : 'جملة',
        trailing: const CurrencySwitch(),
        onRefresh: _load,
        slivers: [
          // البحث
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Pressable(
                onTap: () => _openShop(search: true),
                scale: .985,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: const Color(0x14767680), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const JIcon('search', size: 18, color: C.muted),
                    const SizedBox(width: 8),
                    Text('ابحث عن موديل أو لون...', style: ts(15.5, c: C.muted)),
                  ]),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 0), child: _RouteHero())),
          if (_error != null && _featured.isEmpty)
            SliverToBoxAdapter(child: ErrorRetry(message: _error!, onRetry: () {
              setState(() => _loading = true);
              _load();
            }))
          else ...[
            // الأقسام
            SliverToBoxAdapter(child: SectionTitle('الأقسام', action: 'الكل', onAction: () => _openShop())),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 108,
                child: _loading
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, __) => const SizedBox(width: 84, child: Column(children: [Skeleton(width: 64, height: 64, radius: 20)])),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => FadeIn(
                          index: i,
                          child: CategoryTile(category: _cats[i], onTap: () => _openShop(cat: _cats[i].slug, catName: _cats[i].name)),
                        ),
                      ),
              ),
            ),
            // الأكثر طلباً
            if (_loading || _featured.isNotEmpty) ...[
              SliverToBoxAdapter(child: SectionTitle('الأكثر طلباً', sub: 'البيع بالسيري حسب المقاسات', action: 'المتجر', onAction: () => _openShop())),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: cardExtent(164),
                  child: _loading
                      ? ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                          for (var i = 0; i < 3; i++)
                            const Padding(padding: EdgeInsetsDirectional.only(end: 12), child: Skeleton(width: 164, height: 300, radius: 20)),
                        ])
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _featured.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => SizedBox(
                            width: 164,
                            child: FadeIn(index: i, child: ProductCard(product: _featured[i], heroPrefix: 'home-f')),
                          ),
                        ),
                ),
              ),
            ],
            // طلب تسعيرة
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                child: Pressable(
                  onTap: () => Navigator.of(context).push(slideRoute(const RfqScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(colors: [Color(0xFF0071E3), Color(0xFF3AA0FF)], begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('تدور على موديل مو موجود؟', style: ts(17, w: FontWeight.w700, c: Colors.white)),
                          const SizedBox(height: 4),
                          Text('اطلب تسعيرة ونجيبلك عروض المصانع خلال 48 ساعة', style: ts(13, c: const Color(0xD9FFFFFF), h: 1.4)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const JIcon('arrow-left', size: 20, color: C.accent),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            // وصل حديثاً
            SliverToBoxAdapter(child: SectionTitle('وصل حديثاً', action: 'الكل', onAction: () => _openShop())),
            if (_loading) const ProductGridSkeleton() else ProductGrid(products: _latest, heroPrefix: 'home-l'),
          ],
        ],
      ),
    );
  }
}

/// بطاقة المسار: الصين ← العراق مع حركة سفينة بسيطة
class _RouteHero extends StatefulWidget {
  const _RouteHero();

  @override
  State<_RouteHero> createState() => _RouteHeroState();
}

class _RouteHeroState extends State<_RouteHero> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _city(String icon, String country, String cities) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: JIcon(icon, size: 26),
        ),
        const SizedBox(height: 6),
        Text(country, style: ts(11.5, w: FontWeight.w600, c: C.accent)),
        Text(cities, style: ts(11, c: C.muted)),
      ]);

  @override
  Widget build(BuildContext context) {
    return CardBox(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(children: [
        Text('من مصانع الصين إلى مخزنك في العراق', textAlign: TextAlign.center, style: ts(17, w: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('نشتري، نفحص، نشحن، ونخلّص جمركياً', textAlign: TextAlign.center, style: ts(13, c: C.muted)),
        const SizedBox(height: 16),
        Row(children: [
          _city('factory', 'الصين', 'قوانغتشو · ييوو'),
          Expanded(
            child: SizedBox(
              height: 40,
              child: LayoutBuilder(builder: (context, box) {
                return Stack(alignment: Alignment.center, children: [
                  Container(height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 8), color: const Color(0xFFD2D2D7)),
                  AnimatedBuilder(
                    animation: _c,
                    builder: (_, child) {
                      final t = Curves.easeInOut.transform(_c.value);
                      // RTL: البداية يمين (الصين) والنهاية يسار (العراق)
                      return PositionedDirectional(start: 4 + t * (box.maxWidth - 36), child: child!);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.white,
                      child: const JIcon('ship', size: 22, color: C.accent),
                    ),
                  ),
                ]);
              }),
            ),
          ),
          _city('store', 'العراق', 'بغداد · البصرة'),
        ]),
      ]),
    );
  }
}
