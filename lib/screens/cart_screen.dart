// JUMLA — Cart · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/ui.dart';
import 'checkout_screen.dart';
import 'product_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Quote? _quote;
  bool _loading = false;
  String? _error;
  String _lastSig = '';
  Timer? _debounce;
  int _req = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String _sig(AppState s) => '${jsonEncode(s.cart.map((k, v) => MapEntry('$k', v)))}|${s.ship}';

  void _schedule(AppState s, {bool now = false}) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: now ? 0 : 280), () => _fetch(s));
  }

  Future<void> _fetch(AppState s) async {
    if (s.cart.isEmpty) {
      if (mounted) setState(() => _quote = null);
      return;
    }
    final my = ++_req;
    if (mounted) setState(() => _loading = true);
    try {
      final r = await Api.i.post('/quote', {'items': s.cartItems, 'ship_method': s.ship});
      final q = Quote.fromJson(r.data);
      if (!mounted || my != _req) return;
      // منتجات حُذفت أو أُخفيت من المتجر
      if (q.unavailable.isNotEmpty) {
        s.removeMany(q.unavailable);
        toast(context, 'تم حذف ${q.unavailable.length} منتج غير متوفر من السلة', error: true);
      }
      // مطابقة الكميات مع السيري المعتمد من السيرفر
      for (final it in q.items) {
        if (s.cart[it.product.id] != it.qty) s.cart[it.product.id] = it.qty;
      }
      _lastSig = _sig(s);
      setState(() {
        _quote = q;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted && my == _req) setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final sig = _sig(s);
    if (sig != _lastSig) {
      _lastSig = sig;
      _schedule(s, now: _quote == null);
    }
    final q = _quote;
    final items = q?.items.where((i) => s.cart.containsKey(i.product.id)).toList() ?? const <QuoteItem>[];

    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(children: [
        LargeTitlePage(
          title: 'السلة',
          onRefresh: () => _fetch(s),
          bottomPadding: s.cart.isEmpty ? null : 150 + MediaQuery.paddingOf(context).bottom,
          trailing: s.cart.isEmpty
              ? null
              : Pressable(
                  onTap: () async {
                    if (await confirmDialog(context, 'تفريغ السلة؟', 'راح تنحذف كل المنتجات من السلة.', ok: 'تفريغ', destructive: true)) s.clearCart();
                  },
                  child: Padding(padding: const EdgeInsets.all(6), child: Text('تفريغ', style: ts(16, c: C.bad))),
                ),
          slivers: [
            if (s.cart.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: 'bag',
                  title: 'سلتك فارغة',
                  sub: 'ابدأ بإضافة موديلات بأسعار المصنع.',
                  action: 'تصفح المتجر',
                  onAction: () => s.tab.value = 1,
                ),
              )
            else if (q == null && _error != null)
              SliverToBoxAdapter(child: ErrorRetry(message: _error!, onRetry: () => _fetch(s)))
            else if (q == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [for (var i = 0; i < s.cart.length.clamp(1, 3); i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: Skeleton(height: 104, radius: 20))]),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: AnimatedText(
                    '${items.length} موديل · ${groupDigits(q.totals.itemsQty)} قطعة · ${q.totals.weightKg.toStringAsFixed(1)} كغم · ${q.totals.cbm.toStringAsFixed(2)} CBM',
                    style: ts(13, c: C.muted),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => FadeIn(index: i, child: _CartRow(item: items[i], qty: s.cart[items[i].product.id] ?? items[i].qty)),
                ),
              ),
              SliverToBoxAdapter(child: SectionTitle('طريقة الشحن', sub: 'الأسعار تشمل الشحن لمستودع بغداد')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: s.config?.shipMethods.length ?? 0,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final m = s.config!.shipMethods[i];
                    return _ShipOption(
                      method: m,
                      active: s.ship == m.key,
                      total: q.byMethod[m.key],
                      cheapest: q.cheapest == m.key,
                      onTap: () => s.setShip(m.key),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                  child: CardBox(
                    child: AnimatedOpacity(
                      duration: Motion.fast,
                      opacity: _loading ? .55 : 1,
                      child: Column(children: [
                        _sum(s, 'قيمة البضاعة', q.totals.subtotal),
                        _sum(s, s.config?.ship(s.ship)?.name ?? 'الشحن', q.totals.shipping),
                        _sum(s, 'جمارك تقديرية (${s.config?.customsPercent.toStringAsFixed(0) ?? 5}%)', q.totals.customs),
                        _sum(s, 'خدمة جملة (${s.config?.servicePercent.toStringAsFixed(0) ?? 3}%)', q.totals.fee),
                        const Divider(height: 22, color: C.line),
                        Row(children: [
                          Expanded(child: Text('الإجمالي الواصل', style: ts(16, w: FontWeight.w700))),
                          AnimatedText(s.money(q.totals.total), style: ts(22, w: FontWeight.w700)),
                        ]),
                        Align(alignment: AlignmentDirectional.centerEnd, child: AnimatedText('≈ ${s.moneyAlt(q.totals.total)}', style: ts(12.5, c: C.muted))),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        // شريط إتمام الطلب
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSlide(
            duration: Motion.base,
            curve: Motion.curve,
            offset: (s.cart.isNotEmpty && q != null) ? Offset.zero : const Offset(0, 1.2),
            child: GlassBar(
              child: Row(children: [
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('الإجمالي', style: ts(12, c: C.muted)),
                  AnimatedText(q == null ? '' : s.money(q.totals.total), style: ts(18, w: FontWeight.w700)),
                ]),
                const SizedBox(width: 14),
                Expanded(
                  child: AppButton(
                    'إتمام الطلب',
                    icon: 'arrow-left',
                    loading: _loading,
                    onTap: q == null ? null : () => Navigator.of(context).push(slideRoute(CheckoutScreen(quote: q))),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sum(AppState s, String k, Money v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(k, style: ts(14.5, c: C.muted))),
          AnimatedText(s.money(v), style: ts(15, w: FontWeight.w500)),
        ]),
      );
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item, required this.qty});
  final QuoteItem item;
  final int qty;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = item.product;
    return Dismissible(
      key: ValueKey('cart-${p.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        s.setQty(p.id, 0);
      },
      background: Container(
        decoration: BoxDecoration(color: C.bad, borderRadius: BorderRadius.circular(20)),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const JIcon('trash', size: 22, color: Colors.white),
      ),
      child: CardBox(
        padding: const EdgeInsets.all(12),
        radius: 20,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Pressable(
            onTap: () => Navigator.of(context).push(slideRoute(ProductScreen(id: p.id, preview: p))),
            child: SizedBox(width: 76, height: 92, child: NetImage(p.image, radius: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(14.5, w: FontWeight.w600, h: 1.35)),
              const SizedBox(height: 2),
              Text('${s.money(p.price)} / قطعة · ${qty ~/ p.packQty} سيري', style: ts(12, c: C.muted)),
              const SizedBox(height: 8),
              Row(children: [
                QtyStepper(value: qty, step: p.packQty, compact: true, onChanged: (v) => s.setQty(p.id, v)),
                const Spacer(),
                AnimatedText(s.money(item.line), style: ts(15.5, w: FontWeight.w700)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ShipOption extends StatelessWidget {
  const _ShipOption({required this.method, required this.active, required this.onTap, this.total, this.cheapest = false});
  final ShipMethod method;
  final bool active, cheapest;
  final Money? total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Pressable(
      onTap: onTap,
      haptic: true,
      scale: .985,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.curve,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF2F7FE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? C.accent : C.line, width: active ? 1.5 : 1),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: Motion.base,
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: active ? C.accent : C.bg, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: JIcon(method.icon, size: 22, color: active ? Colors.white : C.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(method.name, style: ts(15, w: FontWeight.w600))),
                if (cheapest) ...[const SizedBox(width: 6), const StatusBadge('الأوفر', kind: 'ok')],
              ]),
              Text(method.days, style: ts(12.5, c: C.muted)),
            ]),
          ),
          if (total != null) AnimatedText(s.money(total!), style: ts(15, w: FontWeight.w700)),
        ]),
      ),
    );
  }
}
