// JUMLA — Checkout · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/ui.dart';
import 'auth_screen.dart';
import 'success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.quote});
  final Quote quote;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  String _city = 'بغداد';
  String _pay = 'zain';
  Map<String, String> _errors = {};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _prefill(context.read<AppState>());
  }

  void _prefill(AppState s) {
    final me = s.me;
    if (me != null) {
      _name.text = me.displayName;
      _phone.text = me.phone;
      _address.text = me.address;
      if (me.city.isNotEmpty) _city = me.city;
    }
    final pays = s.config?.payMethods ?? const <PayMethod>[];
    if (pays.isNotEmpty && !pays.any((p) => p.key == _pay)) _pay = pays.first.key;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(AppState s) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _errors = {};
    });
    try {
      final r = await Api.i.post('/orders', {
        'items': s.cartItems,
        'ship_method': s.ship,
        'pay_method': _pay,
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'city': _city,
        'address': _address.text.trim(),
        'notes': _notes.text.trim(),
      });
      final order = Order.fromJson(r.data);
      HapticFeedback.heavyImpact();
      if (!s.loggedIn) s.rememberGuestOrder(order.code, order.deliveryPhone);
      s.clearCart();
      if (s.loggedIn) s.refreshMe().catchError((_) {});
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(SuccessScreen(order: order)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _errors = e.fields;
      });
      toast(context, e.message, error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      toast(context, 'حدث خطأ، حاول مرة أخرى', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = widget.quote;
    final ship = s.config?.ship(s.ship);
    return Scaffold(
      backgroundColor: C.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(children: [
          LargeTitlePage(
            title: 'إتمام الطلب',
            bottomPadding: 150 + MediaQuery.paddingOf(context).bottom,
            slivers: [
              if (!s.loggedIn)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Pressable(
                      onTap: () async {
                        await Navigator.of(context).push(slideRoute(const AuthScreen()));
                        if (mounted) setState(() => _prefill(context.read<AppState>()));
                      },
                      child: CardBox(
                        color: const Color(0xFFF2F7FE),
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          const JIcon('user', size: 20, color: C.accent),
                          const SizedBox(width: 10),
                          Expanded(child: Text('عندك حساب؟ سجّل دخول حتى تتابع طلباتك من حسابك', style: ts(13.5, c: C.accent, h: 1.4))),
                          const JIcon('chevron-left', size: 16, color: C.accent),
                        ]),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: CardBox(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Field(label: 'اسم المحل / التاجر', controller: _name, error: _errors['name'], action: TextInputAction.next),
                      Field(
                        label: 'رقم الهاتف',
                        controller: _phone,
                        hint: '07xx xxx xxxx',
                        keyboard: TextInputType.phone,
                        ltr: true,
                        error: _errors['phone'],
                        autofill: const [AutofillHints.telephoneNumber],
                        action: TextInputAction.next,
                      ),
                      Padding(padding: const EdgeInsets.only(bottom: 6, top: 12), child: Text('المحافظة', style: ts(13, c: C.muted))),
                      Pressable(
                        scale: .985,
                        onTap: () async {
                          final v = await pickFrom(context, 'اختر المحافظة', s.config?.governorates ?? const ['بغداد'], selected: _city);
                          if (v != null) setState(() => _city = v);
                        },
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _errors['city'] != null ? C.bad : const Color(0x1F000000)),
                          ),
                          child: Row(children: [
                            Expanded(child: Text(_city, style: ts(16))),
                            const JIcon('chevron-down', size: 18, color: C.muted),
                          ]),
                        ),
                      ),
                      Field(label: 'العنوان التفصيلي', controller: _address, hint: 'المنطقة، الشارع، أقرب نقطة دالة', error: _errors['address']),
                    ]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SectionTitle('طريقة الدفع')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: s.config?.payMethods.length ?? 0,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final pm = s.config!.payMethods[i];
                    final on = pm.key == _pay;
                    return Pressable(
                      onTap: () => setState(() => _pay = pm.key),
                      haptic: true,
                      scale: .985,
                      child: AnimatedContainer(
                        duration: Motion.base,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: on ? const Color(0xFFF2F7FE) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: on ? C.accent : C.line, width: on ? 1.5 : 1),
                        ),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: Motion.base,
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: on ? C.accent : C.bg, borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: JIcon(pm.icon, size: 22, color: on ? Colors.white : C.text),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(pm.name, style: ts(15, w: FontWeight.w600)),
                              Text(pm.description, style: ts(12.5, c: C.muted)),
                            ]),
                          ),
                          AnimatedScale(
                            duration: Motion.base,
                            curve: Motion.spring,
                            scale: on ? 1 : 0,
                            child: const JIcon('check-circle', size: 22, color: C.accent),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              if (_errors['pay_method'] != null)
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), child: Text(_errors['pay_method']!, style: ts(12.5, c: C.bad)))),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: CardBox(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Field(label: 'ملاحظات (اختياري)', controller: _notes, hint: 'ألوان مفضلة، وقت التوصيل...', maxLines: 3),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SectionTitle('ملخص الطلب')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CardBox(
                    child: Column(children: [
                      for (final it in q.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Expanded(child: Text('${it.product.name} × ${it.qty}', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(14, c: C.muted))),
                            Text(s.money(it.line), style: ts(14)),
                          ]),
                        ),
                      const Divider(height: 20, color: C.line),
                      _line('${ship?.name ?? 'الشحن'} · ${ship?.days ?? ''}', s.money(q.totals.shipping)),
                      _line('الجمارك + الخدمة', s.money(Money(q.totals.customs.usd + q.totals.fee.usd, q.totals.customs.iqd + q.totals.fee.iqd))),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(child: Text('الإجمالي الواصل', style: ts(16, w: FontWeight.w700))),
                        Text(s.money(q.totals.total), style: ts(21, w: FontWeight.w700)),
                      ]),
                    ]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Text('السعر النهائي يُثبّت عند تأكيد الدفع. راح نتواصل وياك على رقمك لتأكيد الطلب.', textAlign: TextAlign.center, style: ts(12, c: C.muted, h: 1.5)),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBar(
              child: AppButton('تأكيد الطلب · ${s.money(q.totals.total)}', icon: 'check', loading: _sending, onTap: () => _submit(s)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Expanded(child: Text(k, style: ts(14, c: C.muted))), Text(v, style: ts(14))]),
      );
}
