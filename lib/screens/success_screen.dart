// JUMLA — Order placed · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/ui.dart';
import 'order_detail_screen.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key, required this.order});
  final Order order;

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final o = widget.order;
    final pop = CurvedAnimation(parent: _c, curve: const Interval(0, .6, curve: Curves.elasticOut));
    final ring = CurvedAnimation(parent: _c, curve: const Interval(.1, 1, curve: Curves.easeOut));
    final rest = CurvedAnimation(parent: _c, curve: const Interval(.35, 1, curve: Curves.easeOutCubic));

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, 40, 20, MediaQuery.paddingOf(context).bottom + 24),
          children: [
            Center(
              child: SizedBox(
                width: 130,
                height: 130,
                child: Stack(alignment: Alignment.center, children: [
                  AnimatedBuilder(
                    animation: ring,
                    builder: (_, __) => Container(
                      width: 90 + 40 * ring.value,
                      height: 90 + 40 * ring.value,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: C.ok.withAlpha((60 * (1 - ring.value)).round())),
                    ),
                  ),
                  ScaleTransition(
                    scale: pop,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: C.ok),
                      alignment: Alignment.center,
                      child: const JIcon('check', size: 44, color: Colors.white, stroke: 2.4),
                    ),
                  ),
                ]),
              ),
            ),
            FadeTransition(
              opacity: rest,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(rest),
                child: Column(children: [
                  const SizedBox(height: 14),
                  Text('تم استلام طلبك', style: ts(26, w: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('رقم الطلب', style: ts(14, c: C.muted)),
                  Pressable(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: o.code));
                      toast(context, 'تم نسخ رقم الطلب');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(o.code, textDirection: TextDirection.ltr, style: ts(30, w: FontWeight.w700, ls: 1.5)),
                        const SizedBox(width: 8),
                        const JIcon('clipboard', size: 18, color: C.muted),
                      ]),
                    ),
                  ),
                  Text(s.money(o.total), style: ts(19, w: FontWeight.w600, c: C.accent)),
                  Text('≈ ${s.moneyAlt(o.total)}', style: ts(13, c: C.muted)),
                  const SizedBox(height: 22),
                  if (o.paymentInstructions.isNotEmpty)
                    CardBox(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          JIcon(o.payIcon.isEmpty ? 'card' : o.payIcon, size: 20, color: C.accent),
                          const SizedBox(width: 8),
                          Text(o.payName, style: ts(15.5, w: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 8),
                        Text(o.paymentInstructions, style: ts(14.5, h: 1.7)),
                        if (o.depositDue != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: C.accentSoft, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              Expanded(child: Text('مبلغ العربون', style: ts(14, w: FontWeight.w600, c: C.accent))),
                              Text(s.money(o.depositDue!), style: ts(16, w: FontWeight.w700, c: C.accent)),
                            ]),
                          ),
                        ],
                      ]),
                    ),
                  const SizedBox(height: 14),
                  Text('راح نتواصل وياك على ${o.deliveryPhone} لتأكيد الطلب.', textAlign: TextAlign.center, style: ts(13.5, c: C.muted, h: 1.5)),
                  const SizedBox(height: 24),
                  AppButton('تتبع الطلب', icon: 'pin', onTap: () {
                    Navigator.of(context).pushReplacement(slideRoute(OrderDetailScreen(code: o.code, phone: o.deliveryPhone)));
                  }),
                  const SizedBox(height: 10),
                  AppButton('متابعة التسوق', style: BtnStyle.ghost, onTap: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    s.tab.value = 0;
                  }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
