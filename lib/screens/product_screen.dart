// JUMLA — Product details · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/product_card.dart';
import '../widgets/ui.dart';
import 'rfq_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.id, this.preview, this.heroTag});
  final int id;
  final Product? preview;
  final String? heroTag;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Product? _p;
  bool _full = false;
  String? _error;
  int _qty = 0;
  int _img = 0;
  bool _added = false;
  final _pager = PageController();

  @override
  void initState() {
    super.initState();
    _p = widget.preview;
    if (_p != null) _qty = _p!.packQty;
    _load();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Api.i.get('/products/${widget.id}');
      if (!mounted) return;
      setState(() {
        _p = Product.fromJson(r.data);
        _full = true;
        _error = null;
        if (_qty == 0 || _qty % _p!.packQty != 0) _qty = _p!.packQty;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  void _add(AppState s) {
    final p = _p!;
    HapticFeedback.mediumImpact();
    s.addToCart(p, _qty);
    setState(() => _added = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = _p;
    final top = MediaQuery.paddingOf(context).top;

    if (p == null) {
      return Scaffold(
        backgroundColor: C.bg,
        body: Stack(children: [
          Center(child: _error != null ? ErrorRetry(message: _error!, onRetry: _load) : const _Loading()),
          PositionedDirectional(top: top + 8, start: 16, child: GlassCircle(icon: 'chevron-right', onTap: () => Navigator.pop(context))),
        ]),
      );
    }

    final gallery = p.gallery;
    final packs = _qty ~/ p.packQty;
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // معرض الصور
            SliverToBoxAdapter(
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(fit: StackFit.expand, children: [
                  PageView.builder(
                    controller: _pager,
                    itemCount: gallery.isEmpty ? 1 : gallery.length,
                    onPageChanged: (i) => setState(() => _img = i),
                    itemBuilder: (_, i) {
                      final img = NetImage(gallery.isEmpty ? null : gallery[i]);
                      return i == 0 && widget.heroTag != null ? Hero(tag: widget.heroTag!, child: img) : img;
                    },
                  ),
                  if (gallery.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (var i = 0; i < gallery.length; i++)
                          AnimatedContainer(
                            duration: Motion.base,
                            curve: Motion.curve,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _img ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(color: i == _img ? Colors.white : const Color(0x99FFFFFF), borderRadius: BorderRadius.circular(4)),
                          ),
                      ]),
                    ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (p.categoryName.isNotEmpty) Text(p.categoryName, style: ts(13, w: FontWeight.w600, c: C.accent)),
                  const SizedBox(height: 4),
                  Text(p.name, style: ts(24, w: FontWeight.w700, h: 1.3)),
                  const SizedBox(height: 8),
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const JIcon('star', size: 15, color: C.star, fill: true),
                      const SizedBox(width: 3),
                      Text(p.rating.toStringAsFixed(1), style: ts(13, w: FontWeight.w600)),
                    ]),
                    Text('${groupDigits(p.sold)} قطعة مباعة', style: ts(13, c: C.muted)),
                    if (_full) Text('تجهيز خلال ${p.leadDays} أيام', style: ts(13, c: C.muted)),
                  ]),
                  const SizedBox(height: 18),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    AnimatedText(s.money(p.price), style: ts(32, w: FontWeight.w700, h: 1.1)),
                    Padding(padding: const EdgeInsets.only(bottom: 4, right: 6), child: Text('/ قطعة', style: ts(14, c: C.muted))),
                  ]),
                  Text('≈ ${s.moneyAlt(p.price)}', style: ts(13, c: C.muted)),
                  if (p.colors.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('الألوان: ${p.colors}${gallery.length > 1 ? ' — السيري لكل لون' : ''}', style: ts(14.5, c: C.muted, h: 1.5)),
                  ],
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (p.sizes.isEmpty)
                      _SizeChip(size: 'Free Size', qty: p.packQty)
                    else
                      for (final sz in p.sizes) _SizeChip(size: sz.size, qty: sz.qty),
                  ]),
                  const SizedBox(height: 22),
                  Text('الكمية · السيري = ${p.packQty} قطع', style: ts(13, c: C.muted)),
                  if (p.sizesText.isNotEmpty) Text(p.sizesText, textDirection: TextDirection.ltr, style: ts(12.5, c: C.faint)),
                  const SizedBox(height: 10),
                  Row(children: [
                    QtyStepper(value: _qty, step: p.packQty, onChanged: (v) => setState(() => _qty = v)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        AnimatedText('$packs سيري', style: ts(13, c: C.muted)),
                        AnimatedText(s.money(p.price.times(_qty)), style: ts(19, w: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  if (_full && p.landedPerPiece != null)
                    FadeIn(
                      child: CardBox(
                        child: Column(children: [
                          _row('سعر القطعة', s.money(p.price)),
                          _row('أوفر شحن', s.config?.ship(p.landedMethod ?? '')?.name ?? '—'),
                          _row('التكلفة الواصلة للقطعة', s.money(p.landedPerPiece!), strong: true),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('تشمل الشحن والجمارك التقديرية وعمولة الخدمة. كلما زادت الكمية قلّت كلفة الشحن للقطعة.',
                                style: ts(12, c: C.muted, h: 1.5)),
                          ),
                        ]),
                      ),
                    ),
                  if (_full && p.supplier != null) ...[
                    const SizedBox(height: 12),
                    FadeIn(index: 1, child: _SupplierCard(p.supplier!)),
                  ],
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('الوصف', style: ts(17, w: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(p.description, style: ts(15, c: C.muted, h: 1.7)),
                  ],
                  const SizedBox(height: 14),
                  Center(
                    child: Pressable(
                      onTap: () => Navigator.of(context).push(slideRoute(RfqScreen(product: p))),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('تريد كمية كبيرة؟ تفاوض على السعر', style: ts(14.5, c: C.accent)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            if (p.related.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionTitle('قد يعجبك أيضاً')),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: cardExtent(156),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: p.related.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => SizedBox(width: 156, child: ProductCard(product: p.related[i], heroPrefix: 'rel-${p.id}')),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: 120 + MediaQuery.paddingOf(context).bottom)),
          ],
        ),
        // زر الرجوع
        PositionedDirectional(top: top + 8, start: 16, child: GlassCircle(icon: 'chevron-right', onTap: () => Navigator.pop(context))),
        // شريط الإضافة للسلة
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GlassBar(
            child: Row(children: [
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$_qty قطعة', style: ts(12, c: C.muted)),
                AnimatedText(s.money(p.price.times(_qty)), style: ts(18, w: FontWeight.w700)),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.base,
                  transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(a), child: c)),
                  child: _added
                      ? AppButton('تمت الإضافة · عرض السلة', key: const ValueKey('added'), icon: 'check', style: BtnStyle.dark, onTap: () {
                          s.tab.value = 2;
                        })
                      : AppButton('أضف إلى السلة', key: const ValueKey('add'), icon: 'bag', onTap: () => _add(s)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _row(String k, String v, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(k, style: ts(14.5, c: C.muted))),
          AnimatedText(v, style: ts(15, w: FontWeight.w700, c: strong ? C.accent : C.text)),
        ]),
      );
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.size, required this.qty});
  final String size;
  final int qty;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 58),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.line)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(size, textDirection: TextDirection.ltr, style: ts(15, w: FontWeight.w700)),
          Text('$qty قطع', style: ts(11, c: C.muted)),
        ]),
      );
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard(this.s);
  final Supplier s;

  @override
  Widget build(BuildContext context) => CardBox(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: C.text, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const JIcon('factory', size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, textDirection: TextDirection.ltr, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(14.5, w: FontWeight.w600)),
              Text('${s.city} · ${s.years} سنوات · التزام ${s.rating}%', style: ts(12.5, c: C.muted)),
            ]),
          ),
          Row(children: [const JIcon('shield', size: 16, color: C.ok), const SizedBox(width: 3), Text('موثّق', style: ts(12, w: FontWeight.w600, c: C.ok))]),
        ]),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Column(mainAxisSize: MainAxisSize.min, children: [
        Skeleton(width: 220, height: 260, radius: 22),
        SizedBox(height: 16),
        Skeleton(width: 180, height: 16),
        SizedBox(height: 8),
        Skeleton(width: 120, height: 16),
      ]);
}
