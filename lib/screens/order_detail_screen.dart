// JUMLA — Order details & tracking · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/ui.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.code, this.phone});
  final String code;
  final String? phone;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _o;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.i.get('/orders/${widget.code}', query: widget.phone == null ? null : {'phone': widget.phone!});
      if (mounted) setState(() {
        _o = Order.fromJson(r.data);
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _whatsapp(AppState s, Order o) async {
    final wa = s.config?.site.whatsapp;
    if (wa == null) return;
    final msg = Uri.encodeComponent('مرحباً، استفسار بخصوص طلبي رقم ${o.code}');
    await launchUrl(Uri.parse('https://wa.me/$wa?text=$msg'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final o = _o;
    return Scaffold(
      backgroundColor: C.bg,
      body: LargeTitlePage(
        title: 'طلب ${widget.code}',
        onRefresh: _load,
        slivers: [
          if (o == null && _error != null)
            SliverToBoxAdapter(child: ErrorRetry(message: _error!, onRetry: _load))
          else if (o == null)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(children: [Skeleton(height: 140, radius: 22), SizedBox(height: 12), Skeleton(height: 320, radius: 22)]),
              ),
            )
          else ...[
            // الحالة
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: FadeIn(
                  child: CardBox(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(o.statusName, style: ts(22, w: FontWeight.w700))),
                        orderBadge(o),
                      ]),
                      const SizedBox(height: 4),
                      Text('${arDate(o.createdAt)} · ${o.shipName} (${o.shipDays})', style: ts(13, c: C.muted)),
                      const SizedBox(height: 16),
                      if (!o.cancelled)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: (o.stage.clamp(0, 8)) / 8),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(value: v, minHeight: 8, backgroundColor: C.soft, color: o.delivered ? C.ok : C.accent),
                          ),
                        )
                      else
                        Text('هذا الطلب ملغي. للاستفسار تواصل مع خدمة العملاء.', style: ts(14, c: C.bad)),
                    ]),
                  ),
                ),
              ),
            ),
            // المراحل
            if (!o.cancelled) ...[
              const SliverToBoxAdapter(child: SectionTitle('مراحل الشحنة')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CardBox(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                    child: Column(children: [
                      for (var i = 0; i < o.timeline.length; i++) FadeIn(index: i, child: _Step(step: o.timeline[i], last: i == o.timeline.length - 1)),
                    ]),
                  ),
                ),
              ),
            ],
            // تعليمات الدفع
            if (o.stage == 0 && o.paymentInstructions.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionTitle('الدفع')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CardBox(
                    color: const Color(0xFFF2F7FE),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [JIcon(o.payIcon.isEmpty ? 'card' : o.payIcon, size: 20, color: C.accent), const SizedBox(width: 8), Text(o.payName, style: ts(15, w: FontWeight.w700))]),
                      const SizedBox(height: 8),
                      Text(o.paymentInstructions, style: ts(14, h: 1.7)),
                      if (o.depositDue != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('العربون: ${s.money(o.depositDue!)}', style: ts(15, w: FontWeight.w700, c: C.accent))),
                    ]),
                  ),
                ),
              ),
            ],
            // المنتجات
            const SliverToBoxAdapter(child: SectionTitle('المنتجات')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: o.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final it = o.items[i];
                  return CardBox(
                    padding: const EdgeInsets.all(10),
                    radius: 18,
                    child: Row(children: [
                      SizedBox(width: 58, height: 70, child: NetImage(it.image, radius: 12)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(14, w: FontWeight.w600, h: 1.35)),
                          Text('${it.qty} قطعة · ${it.packs} سيري · ${s.money(it.unitPrice)}', style: ts(12, c: C.muted)),
                        ]),
                      ),
                      Text(s.money(it.line), style: ts(14.5, w: FontWeight.w700)),
                    ]),
                  );
                },
              ),
            ),
            // الحساب
            const SliverToBoxAdapter(child: SectionTitle('الحساب')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CardBox(
                  child: Column(children: [
                    if (o.totals['subtotal'] != null) _row('قيمة البضاعة', s.money(o.totals['subtotal']!)),
                    if (o.totals['shipping'] != null) _row('الشحن', s.money(o.totals['shipping']!)),
                    if (o.totals['customs'] != null) _row('الجمارك', s.money(o.totals['customs']!)),
                    if (o.totals['fee'] != null) _row('الخدمة', s.money(o.totals['fee']!)),
                    const Divider(height: 20, color: C.line),
                    _row('الإجمالي', s.money(o.total), bold: true),
                    _row('المدفوع', s.money(o.paid), color: C.ok),
                    _row('المتبقي', s.money(o.remaining), color: o.remaining.usd > 0 ? C.bad : C.ok, bold: true),
                  ]),
                ),
              ),
            ),
            // التوصيل
            const SliverToBoxAdapter(child: SectionTitle('التوصيل')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CardBox(
                  child: Column(children: [
                    _row('الاسم', o.deliveryName),
                    _row('الهاتف', o.deliveryPhone),
                    _row('العنوان', '${o.deliveryCity} — ${o.deliveryAddress}'),
                    if (o.notes.isNotEmpty) _row('ملاحظات', o.notes),
                  ]),
                ),
              ),
            ),
            if (s.config?.site.whatsapp != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: AppButton('استفسار عن الطلب على واتساب', icon: 'chat', style: BtnStyle.ghost, onTap: () => _whatsapp(s, o)),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Pressable(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: o.code));
                      toast(context, 'تم نسخ رقم الطلب');
                    },
                    child: Padding(padding: const EdgeInsets.all(8), child: Text('نسخ رقم الطلب', style: ts(14, c: C.accent))),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String k, String v, {Color color = C.text, bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 96, child: Text(k, style: ts(14, c: C.muted))),
          Expanded(child: Text(v, textAlign: TextAlign.left, style: ts(14.5, w: bold ? FontWeight.w700 : FontWeight.w500, c: color))),
        ]),
      );
}

class _Step extends StatelessWidget {
  const _Step({required this.step, required this.last});
  final TimelineStep step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final done = step.state == 'done', cur = step.state == 'current';
    final color = done ? C.ok : (cur ? C.accent : const Color(0xFFD2D2D7));
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 26,
          child: Column(children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || cur ? color : Colors.white,
                border: Border.all(color: color, width: 2),
                boxShadow: cur ? [BoxShadow(color: C.accent.withAlpha(60), blurRadius: 0, spreadRadius: 5)] : null,
              ),
              alignment: Alignment.center,
              child: done ? const JIcon('check', size: 13, color: Colors.white, stroke: 3) : null,
            ),
            if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 3), color: done ? C.ok : const Color(0xFFE5E5EA))),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(step.name, style: ts(15, w: done || cur ? FontWeight.w600 : FontWeight.w400, c: done || cur ? C.text : C.muted)),
              Text(step.date != null ? '${step.description} · ${arDate(step.date!, time: true)}' : step.description, style: ts(12.5, c: C.muted, h: 1.4)),
            ]),
          ),
        ),
      ]),
    );
  }
}
