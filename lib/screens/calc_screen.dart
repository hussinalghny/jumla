// JUMLA — Shipping calculator · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../api/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/ui.dart';

class CalcScreen extends StatefulWidget {
  const CalcScreen({super.key});

  @override
  State<CalcScreen> createState() => _CalcScreenState();
}

class _CalcResult {
  _CalcResult(this.key, this.name, this.icon, this.days, this.cost);
  final String key, name, icon, days;
  final Money cost;
}

class _CalcScreenState extends State<CalcScreen> {
  final _l = TextEditingController(text: '60');
  final _w = TextEditingController(text: '40');
  final _h = TextEditingController(text: '40');
  final _n = TextEditingController(text: '20');
  final _kg = TextEditingController(text: '18');
  Timer? _t;
  double _cbm = 0, _weight = 0;
  List<_CalcResult> _res = [];

  @override
  void initState() {
    super.initState();
    for (final c in [_l, _w, _h, _n, _kg]) {
      c.addListener(_changed);
    }
    _calc();
  }

  @override
  void dispose() {
    _t?.cancel();
    for (final c in [_l, _w, _h, _n, _kg]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() {
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 350), _calc);
  }

  double _v(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  Future<void> _calc() async {
    try {
      final r = await Api.i.post('/shipping/calc', {'length': _v(_l), 'width': _v(_w), 'height': _v(_h), 'cartons': _v(_n), 'carton_kg': _v(_kg)});
      final d = r.data as Map;
      if (!mounted) return;
      setState(() {
        _cbm = (d['cbm'] as num).toDouble();
        _weight = (d['weight_kg'] as num).toDouble();
        _res = (d['methods'] as List)
            .map((m) => _CalcResult('${m['key']}', '${m['name']}', '${m['icon']}', '${m['days']}', Money.fromJson(m['cost'])))
            .toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    double? best;
    for (final r in _res) {
      if (r.cost.usd > 0 && (best == null || r.cost.usd < best)) best = r.cost.usd;
    }
    return Scaffold(
      backgroundColor: C.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LargeTitlePage(title: 'حاسبة الشحن', slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text('احسب كلفة الشحن من مستودعنا في الصين لمستودع بغداد.', style: ts(14, c: C.muted)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CardBox(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(top: 12), child: Text('أبعاد الكارتون (سم)', style: ts(13, c: C.muted))),
                  Row(children: [
                    Expanded(child: _num('الطول', _l)),
                    const SizedBox(width: 8),
                    Expanded(child: _num('العرض', _w)),
                    const SizedBox(width: 8),
                    Expanded(child: _num('الارتفاع', _h)),
                  ]),
                  Row(children: [
                    Expanded(child: _num('عدد الكراتين', _n)),
                    const SizedBox(width: 8),
                    Expanded(child: _num('وزن الكارتون (كغم)', _kg)),
                  ]),
                ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(children: [
                Expanded(child: _metric('الحجم الكلي', '${_cbm.toStringAsFixed(2)} CBM')),
                const SizedBox(width: 10),
                Expanded(child: _metric('الوزن الكلي', '${groupDigits(_weight)} كغم')),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList.separated(
              itemCount: _res.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = _res[i];
                final isBest = best != null && r.cost.usd == best;
                return AnimatedContainer(
                  duration: Motion.base,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isBest ? C.accent : C.line, width: isBest ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: isBest ? C.accent : C.bg, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: JIcon(r.icon, size: 22, color: isBest ? Colors.white : C.text),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(r.name, style: ts(15, w: FontWeight.w600)),
                          if (isBest) ...[const SizedBox(width: 6), const StatusBadge('الأوفر', kind: 'ok')],
                        ]),
                        Text(r.days, style: ts(12.5, c: C.muted)),
                      ]),
                    ),
                    AnimatedText(s.money(r.cost), style: ts(16, w: FontWeight.w700)),
                  ]),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Text('* الأسعار تقديرية. الجمارك تُحسب حسب نوع البضاعة.', textAlign: TextAlign.center, style: ts(12, c: C.muted)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _num(String label, TextEditingController c) =>
      Field(label: label, controller: c, keyboard: const TextInputType.numberWithOptions(decimal: true), ltr: true);

  Widget _metric(String k, String v) => CardBox(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(children: [
          Text(k, style: ts(12.5, c: C.muted)),
          AnimatedText(v, style: ts(19, w: FontWeight.w700)),
        ]),
      );
}
