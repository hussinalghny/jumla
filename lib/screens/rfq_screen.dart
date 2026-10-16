// JUMLA — Request for quotation · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class RfqScreen extends StatefulWidget {
  const RfqScreen({super.key, this.product});
  final Product? product;

  @override
  State<RfqScreen> createState() => _RfqScreenState();
}

class _RfqScreenState extends State<RfqScreen> {
  late final TextEditingController _product, _qty, _price, _specs, _link, _name, _phone;
  String _ship = 'sea';
  Map<String, String> _errors = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final me = context.read<AppState>().me;
    _product = TextEditingController(text: p?.name ?? '');
    _qty = TextEditingController(text: p == null ? '' : '${p.packQty * 10}');
    _price = TextEditingController();
    _specs = TextEditingController(text: p == null ? '' : 'أرغب بسعر أفضل لكمية أكبر.');
    _link = TextEditingController();
    _name = TextEditingController(text: me?.displayName ?? '');
    _phone = TextEditingController(text: me?.phone ?? '');
  }

  @override
  void dispose() {
    for (final c in [_product, _qty, _price, _specs, _link, _name, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _errors = {};
    });
    try {
      await Api.i.post('/rfqs', {
        'product_name': _product.text.trim(),
        'category': widget.product?.categoryName ?? '',
        'qty': int.tryParse(_qty.text.trim()) ?? 0,
        if (_price.text.trim().isNotEmpty) 'target_price': double.tryParse(_price.text.trim()),
        'ship_method': _ship,
        'specs': _specs.text.trim(),
        'link': _link.text.trim(),
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
      });
      if (!mounted) return;
      toast(context, 'تم إرسال طلب التسعيرة، راح نرد عليك خلال 48 ساعة');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errors = e.fields;
      });
      toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: C.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LargeTitlePage(title: 'طلب تسعيرة', slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text('وصف المنتج والكمية، ونجيبلك أفضل العروض من مصانع موثّقة خلال 48 ساعة.', style: ts(14, c: C.muted, h: 1.5)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CardBox(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!s.loggedIn) ...[
                    Field(label: 'الاسم / المحل', controller: _name, error: _errors['name']),
                    Field(label: 'رقم الهاتف', controller: _phone, hint: '07xx xxx xxxx', ltr: true, keyboard: TextInputType.phone, error: _errors['phone']),
                  ],
                  Field(label: 'اسم المنتج', controller: _product, hint: 'مثال: معاطف صوف نسائية', error: _errors['product_name']),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Field(label: 'الكمية (قطعة)', controller: _qty, keyboard: TextInputType.number, ltr: true, error: _errors['qty'])),
                    const SizedBox(width: 12),
                    Expanded(child: Field(label: 'السعر المستهدف \$', controller: _price, keyboard: const TextInputType.numberWithOptions(decimal: true), ltr: true, hint: 'اختياري')),
                  ]),
                  Padding(padding: const EdgeInsets.only(bottom: 6, top: 12), child: Text('الشحن المفضل', style: ts(13, c: C.muted))),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      groupValue: _ship,
                      children: {
                        for (final m in s.config?.shipMethods ?? const <ShipMethod>[])
                          m.key: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text(m.name.split(' ').take(2).join(' '), style: ts(12.5, w: FontWeight.w500))),
                      },
                      onValueChanged: (v) => setState(() => _ship = v ?? 'sea'),
                    ),
                  ),
                  Field(label: 'المواصفات والتفاصيل', controller: _specs, hint: 'الألوان، المقاسات، الخامة، طباعة شعار...', maxLines: 4),
                  Field(label: 'رابط منتج مشابه (اختياري)', controller: _link, hint: 'https://', ltr: true, keyboard: TextInputType.url, error: _errors['link']),
                  const SizedBox(height: 20),
                  AppButton('إرسال طلب التسعيرة', icon: 'mail', loading: _busy, onTap: _send),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class RfqListScreen extends StatefulWidget {
  const RfqListScreen({super.key});

  @override
  State<RfqListScreen> createState() => _RfqListScreenState();
}

class _RfqListScreenState extends State<RfqListScreen> {
  List<Rfq>? _list;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.i.get('/rfqs');
      if (mounted) setState(() {
        _list = (r.data as List).map((e) => Rfq.fromJson(e)).toList();
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _list;
    return Scaffold(
      backgroundColor: C.bg,
      body: LargeTitlePage(
        title: 'طلبات التسعير',
        onRefresh: _load,
        trailing: Pressable(
          onTap: () async {
            await Navigator.of(context).push(slideRoute(const RfqScreen()));
            _load();
          },
          child: Padding(padding: const EdgeInsets.all(6), child: Text('جديد', style: ts(16, c: C.accent))),
        ),
        slivers: [
          if (l == null && _error != null)
            SliverToBoxAdapter(child: ErrorRetry(message: _error!, onRetry: _load))
          else if (l == null)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Skeleton(height: 110, radius: 20)))
          else if (l.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(icon: 'inbox', title: 'ما عندك طلبات تسعير', action: 'اطلب تسعيرة', onAction: () async {
                await Navigator.of(context).push(slideRoute(const RfqScreen()));
                _load();
              }),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.separated(
                itemCount: l.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final r = l[i];
                  return FadeIn(
                    index: i,
                    child: CardBox(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(r.productName, style: ts(16, w: FontWeight.w700))),
                          StatusBadge(r.statusName, kind: r.status == 'quoted' ? 'ok' : (r.status == 'new' ? 'wait' : 'info')),
                        ]),
                        const SizedBox(height: 2),
                        Text('${groupDigits(r.qty)} قطعة · ${arDate(r.createdAt)}', style: ts(12.5, c: C.muted)),
                        if (r.reply != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFF2F7FE), borderRadius: BorderRadius.circular(12)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('رد الإدارة', style: ts(12.5, w: FontWeight.w700, c: C.accent)),
                              const SizedBox(height: 4),
                              Text(r.reply!, style: ts(14, h: 1.6)),
                            ]),
                          ),
                        ],
                      ]),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
