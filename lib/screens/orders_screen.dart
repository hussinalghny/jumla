// JUMLA — My orders / tracking · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/ui.dart';
import 'auth_screen.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'active';
  List<Order>? _orders;
  String? _error;
  bool? _wasLoggedIn;
  late final AppState _s;

  @override
  void initState() {
    super.initState();
    _s = context.read<AppState>();
    _s.tab.addListener(_onTab);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _s.tab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (_s.tab.value == 3) _load();
  }

  Future<void> _load() async {
    try {
      List<Order> list;
      if (_s.loggedIn) {
        final r = await Api.i.get('/orders', query: {'per_page': '50', if (_filter != 'all') 'status': _filter});
        list = (r.data as List).map((e) => Order.fromJson(e)).toList();
      } else {
        // طلبات الزائر المحفوظة على هذا الجهاز
        list = [];
        for (final g in _s.guestOrders.take(20)) {
          try {
            final r = await Api.i.get('/orders/${g.code}', query: {'phone': g.phone});
            list.add(Order.fromJson(r.data));
          } catch (_) {}
        }
      }
      if (mounted) setState(() {
        _orders = list;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (_wasLoggedIn != null && _wasLoggedIn != s.loggedIn) {
      _orders = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    _wasLoggedIn = s.loggedIn;
    final orders = _orders;

    return Scaffold(
      backgroundColor: C.bg,
      body: LargeTitlePage(
        title: 'طلباتي',
        onRefresh: _load,
        slivers: [
          if (s.loggedIn)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: _filter,
                    children: {
                      'active': Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('قيد التنفيذ', style: ts(13.5, w: FontWeight.w500))),
                      'done': Text('المكتملة', style: ts(13.5, w: FontWeight.w500)),
                      'all': Text('الكل', style: ts(13.5, w: FontWeight.w500)),
                    },
                    onValueChanged: (v) {
                      if (v == null || v == _filter) return;
                      setState(() {
                        _filter = v;
                        _orders = null;
                      });
                      _load();
                    },
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(child: _GuestBox(onTrack: (code, phone) => Navigator.of(context).push(slideRoute(OrderDetailScreen(code: code, phone: phone))))),
          if (orders == null && _error != null)
            SliverToBoxAdapter(child: ErrorRetry(message: _error!, onRetry: _load))
          else if (orders == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: Skeleton(height: 96, radius: 20))]),
              ),
            )
          else if (orders.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: 'clipboard',
                title: s.loggedIn ? 'ما عندك طلبات هنا' : 'ما عندك طلبات بعد',
                sub: 'طلباتك تظهر هنا وتگدر تتابع كل مرحلة من المصنع لمحلك.',
                action: 'تصفح المتجر',
                onAction: () => s.tab.value = 1,
              ),
            )
          else ...[
            if (!s.loggedIn) const SliverToBoxAdapter(child: SectionTitle('طلبات هذا الجهاز')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final o = orders[i];
                  GuestOrder? g;
                  if (!s.loggedIn) {
                    for (final x in s.guestOrders) {
                      if (x.code == o.code) {
                        g = x;
                        break;
                      }
                    }
                  }
                  return FadeIn(
                    index: i,
                    child: _OrderCard(
                      order: o,
                      onTap: () async {
                        await Navigator.of(context).push(slideRoute(OrderDetailScreen(code: o.code, phone: g?.phone)));
                        _load();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});
  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final o = order;
    return Pressable(
      onTap: onTap,
      scale: .98,
      child: CardBox(
        padding: const EdgeInsets.all(12),
        radius: 20,
        child: Row(children: [
          SizedBox(width: 64, height: 76, child: NetImage(o.firstImage, radius: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(o.code, textDirection: TextDirection.ltr, style: ts(15.5, w: FontWeight.w700)),
                const Spacer(),
                orderBadge(o),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                JIcon(o.shipIcon.isEmpty ? 'package' : o.shipIcon, size: 14, color: C.muted),
                const SizedBox(width: 4),
                Flexible(child: Text('${arDate(o.createdAt)} · ${o.piecesCount} قطعة', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12.5, c: C.muted))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Text(s.money(o.total), style: ts(16, w: FontWeight.w700)),
                const Spacer(),
                if (o.remaining.usd > 0 && !o.cancelled) Text('المتبقي ${s.money(o.remaining)}', style: ts(12, c: C.warn)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _GuestBox extends StatefulWidget {
  const _GuestBox({required this.onTrack});
  final void Function(String code, String phone) onTrack;

  @override
  State<_GuestBox> createState() => _GuestBoxState();
}

class _GuestBoxState extends State<_GuestBox> {
  final _code = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _go() {
    var code = _code.text.trim().toUpperCase();
    if (code.isEmpty || _phone.text.trim().isEmpty) {
      toast(context, 'أدخل رقم الطلب ورقم الهاتف', error: true);
      return;
    }
    if (RegExp(r'^\d+$').hasMatch(code)) code = 'JM-$code';
    FocusScope.of(context).unfocus();
    widget.onTrack(code, _phone.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(children: [
        CardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const JIcon('pin', size: 20, color: C.accent), const SizedBox(width: 8), Text('تتبع شحنة', style: ts(17, w: FontWeight.w700))]),
            Field(label: 'رقم الطلب', controller: _code, hint: 'JM-123456', ltr: true, action: TextInputAction.next),
            Field(label: 'رقم الهاتف المسجل بالطلب', controller: _phone, hint: '07xx xxx xxxx', ltr: true, keyboard: TextInputType.phone, onSubmitted: (_) => _go()),
            const SizedBox(height: 16),
            AppButton('تتبع', style: BtnStyle.dark, onTap: _go),
          ]),
        ),
        const SizedBox(height: 10),
        Pressable(
          onTap: () => Navigator.of(context).push(slideRoute(const AuthScreen())),
          child: CardBox(
            color: const Color(0xFFF2F7FE),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const JIcon('user', size: 20, color: C.accent),
              const SizedBox(width: 10),
              Expanded(child: Text('سجّل دخول حتى تشوف كل طلباتك بمكان واحد', style: ts(13.5, c: C.accent))),
              const JIcon('chevron-left', size: 16, color: C.accent),
            ]),
          ),
        ),
      ]),
    );
  }
}
