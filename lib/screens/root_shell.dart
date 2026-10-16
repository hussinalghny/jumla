// JUMLA — Tab shell · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/ui.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'shop_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _built = <int>{0};
  // كل Navigator داخلي يحتاج HeroController خاص حتى تشتغل حركة Hero للصور
  final _heroes = List.generate(5, (_) => HeroController());

  static const _tabs = [
    ('home', 'الرئيسية'),
    ('grid', 'المتجر'),
    ('bag', 'السلة'),
    ('clipboard', 'طلباتي'),
    ('user', 'حسابي'),
  ];

  Widget _page(int i) => switch (i) {
        0 => const HomeScreen(),
        1 => const ShopScreen(),
        2 => const CartScreen(),
        3 => const OrdersScreen(),
        _ => const AccountScreen(),
      };

  void _select(AppState s, int i) {
    HapticFeedback.selectionClick();
    if (s.tab.value == i) {
      // الضغط على نفس التبويب يرجع لأول صفحة
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      s.tab.value = i;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<AppState>(context, listen: false);
    return ValueListenableBuilder<int>(
      valueListenable: s.tab,
      builder: (context, idx, _) {
        _built.add(idx);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final nav = _navKeys[idx].currentState;
            if (nav != null && nav.canPop()) {
              nav.pop();
            } else if (idx != 0) {
              s.tab.value = 0;
            } else {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            extendBody: true,
            body: Stack(fit: StackFit.expand, children: [
              for (var i = 0; i < 5; i++)
                // كل تبويب له Navigator خاص (مثل تطبيقات iOS) مع انتقال ناعم بين التبويبات
                IgnorePointer(
                  ignoring: i != idx,
                  child: AnimatedOpacity(
                    opacity: i == idx ? 1 : 0,
                    duration: Motion.fast,
                    child: TickerMode(
                      enabled: i == idx,
                      child: _built.contains(i)
                          ? Navigator(
                              key: _navKeys[i],
                              observers: [_heroes[i]],
                              onGenerateRoute: (_) => slideRoute(_page(i)),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
            ]),
            bottomNavigationBar: GlassBar(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(child: _TabItem(icon: _tabs[i].$1, label: _tabs[i].$2, active: i == idx, badge: i == 2, onTap: () => _select(s, i))),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label, required this.active, required this.onTap, this.badge = false});
  final String icon, label;
  final bool active, badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? C.accent : C.muted;
    return Pressable(
      onTap: onTap,
      scale: .9,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          AnimatedScale(
            scale: active ? 1.08 : 1,
            duration: Motion.base,
            curve: Motion.spring,
            child: JIcon(icon, size: 24, color: color, stroke: active ? 2 : 1.75),
          ),
          if (badge) const PositionedDirectional(top: -5, end: -10, child: _CartBadge()),
        ]),
        const SizedBox(height: 3),
        AnimatedDefaultTextStyle(
          duration: Motion.fast,
          style: ts(10.5, w: active ? FontWeight.w600 : FontWeight.w400, c: color),
          child: Text(label),
        ),
      ]),
    );
  }
}

/// شارة عدد السلة — تقفز عند التغيير
class _CartBadge extends StatelessWidget {
  const _CartBadge();

  @override
  Widget build(BuildContext context) {
    final n = context.select<AppState, int>((s) => s.cartCount);
    return AnimatedSwitcher(
      duration: Motion.base,
      transitionBuilder: (child, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: child),
      child: n == 0
          ? const SizedBox.shrink(key: ValueKey(0))
          : Container(
              key: ValueKey(n),
              constraints: const BoxConstraints(minWidth: 18),
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(color: C.accent, borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white, width: 1.5)),
              alignment: Alignment.center,
              child: Text('$n', style: ts(10.5, w: FontWeight.w700, c: Colors.white, h: 1.1)),
            ),
    );
  }
}
