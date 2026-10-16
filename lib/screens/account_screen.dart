// JUMLA — Account · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';
import '../config.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/ui.dart';
import 'account_forms.dart';
import 'auth_screen.dart';
import 'calc_screen.dart';
import 'rfq_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Future<void> _deleteAccount(BuildContext context, AppState s) async {
    final ctrl = TextEditingController();
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text('حذف الحساب نهائياً', style: ts(17, w: FontWeight.w600)),
        content: Column(children: [
          const SizedBox(height: 6),
          Text('راح ينحذف حسابك وبياناتك. طلباتك السابقة تبقى بسجلات الشركة بدون ربط بحسابك. أدخل كلمة السر للتأكيد.', style: ts(13.5, h: 1.5)),
          const SizedBox(height: 12),
          CupertinoTextField(controller: ctrl, obscureText: true, placeholder: 'كلمة السر', style: ts(15), textDirection: TextDirection.ltr),
        ]),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(c, false), child: Text('إلغاء', style: ts(16, c: C.accent))),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(c, true), child: Text('حذف', style: ts(16, w: FontWeight.w600, c: C.bad))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await s.deleteAccount(ctrl.text);
      if (context.mounted) toast(context, 'تم حذف الحساب');
    } on ApiException catch (e) {
      if (context.mounted) toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.me;
    final site = s.config?.site;
    void push(Widget w) => Navigator.of(context).push(slideRoute(w));

    return Scaffold(
      backgroundColor: C.bg,
      body: LargeTitlePage(
        title: 'حسابي',
        onRefresh: () async {
          if (s.loggedIn) {
            try {
              await s.refreshMe();
            } catch (_) {}
          }
        },
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: Motion.base,
              child: me == null
                  ? Padding(
                      key: const ValueKey('guest'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: CardBox(
                        padding: const EdgeInsets.all(22),
                        child: Column(children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(color: C.bg, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: const JIcon('user', size: 30, color: C.muted),
                          ),
                          const SizedBox(height: 12),
                          Text('سجّل دخولك', style: ts(20, w: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('تابع طلباتك وتسعيراتك وادفع بسهولة', textAlign: TextAlign.center, style: ts(14, c: C.muted)),
                          const SizedBox(height: 18),
                          AppButton('تسجيل الدخول', onTap: () => push(const AuthScreen())),
                          const SizedBox(height: 8),
                          AppButton('فتح حساب تاجر', style: BtnStyle.ghost, onTap: () => push(const AuthScreen(register: true))),
                        ]),
                      ),
                    )
                  : Padding(
                      key: const ValueKey('me'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: CardBox(
                        child: Column(children: [
                          Row(children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF0071E3), Color(0xFF3AA0FF)]),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(me.name.isEmpty ? '؟' : me.name.characters.first, style: ts(24, w: FontWeight.w700, c: Colors.white)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(me.name, style: ts(19, w: FontWeight.w700)),
                                if (me.shopName.isNotEmpty) Text(me.shopName, style: ts(14, c: C.muted)),
                                Text(me.phone, textDirection: TextDirection.ltr, style: ts(13.5, c: C.muted)),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          Row(children: [
                            _Stat('الطلبات', '${me.ordersCount}'),
                            _Stat('قيد التنفيذ', '${me.activeOrders}'),
                            _Stat('المشتريات', s.money(me.totalSpent)),
                          ]),
                          if (me.wallet.usd != 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: C.okSoft, borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                const JIcon('banknote', size: 20, color: C.ok),
                                const SizedBox(width: 8),
                                Expanded(child: Text('رصيد المحفظة', style: ts(14, w: FontWeight.w600, c: C.ok))),
                                Text(s.money(me.wallet), style: ts(15, w: FontWeight.w700, c: C.ok)),
                              ]),
                            ),
                          ],
                        ]),
                      ),
                    ),
            ),
          ),
          if (me != null)
            SliverToBoxAdapter(
              child: Group(title: 'الحساب', children: [
                ListRow(icon: 'edit', title: 'تعديل البيانات', onTap: () => push(const ProfileScreen())),
                ListRow(icon: 'lock', title: 'تغيير كلمة السر', iconBg: const Color(0xFF8E8E93), onTap: () => push(const PasswordScreen())),
              ]),
            ),
          SliverToBoxAdapter(
            child: Group(title: 'الخدمات', children: [
              ListRow(icon: 'mail', title: 'طلب تسعيرة', iconBg: const Color(0xFF5856D6), onTap: () => push(const RfqScreen())),
              if (me != null) ListRow(icon: 'inbox', title: 'طلبات التسعير', iconBg: const Color(0xFFFF9500), onTap: () => push(const RfqListScreen())),
              ListRow(icon: 'calculator', title: 'حاسبة الشحن', iconBg: const Color(0xFF34C759), onTap: () => push(const CalcScreen())),
            ]),
          ),
          SliverToBoxAdapter(
            child: Group(title: 'الإعدادات', children: [
              ListRow(icon: 'currency', title: 'العملة', iconBg: C.brand, trailing: const CurrencySwitch()),
            ]),
          ),
          if (site != null && (site.whatsapp != null || site.phone.isNotEmpty || site.instagram.isNotEmpty))
            SliverToBoxAdapter(
              child: Group(title: 'تواصل معنا', children: [
                if (site.whatsapp != null) ListRow(icon: 'chat', title: 'واتساب', iconBg: const Color(0xFF25D366), onTap: () => _open('https://wa.me/${site.whatsapp}')),
                if (site.phone.isNotEmpty) ListRow(icon: 'phone', title: 'اتصال', value: site.phone, iconBg: const Color(0xFF34C759), onTap: () => _open('tel:${site.phone}')),
                if (site.instagram.isNotEmpty) ListRow(icon: 'globe', title: 'إنستغرام', iconBg: const Color(0xFFE1306C), onTap: () => _open(site.instagram)),
              ]),
            ),
          if (me != null)
            SliverToBoxAdapter(
              child: Group(children: [
                ListRow(
                  icon: 'logout',
                  title: 'تسجيل الخروج',
                  color: C.bad,
                  iconBg: C.bad,
                  onTap: () async {
                    if (await confirmDialog(context, 'تسجيل الخروج؟', 'تگدر ترجع تسجل دخول بأي وقت.', ok: 'خروج', destructive: true)) {
                      await s.logout();
                    }
                  },
                ),
                ListRow(icon: 'trash', title: 'حذف الحساب', color: C.bad, iconBg: const Color(0xFF8E8E93), onTap: () => _deleteAccount(context, s)),
              ]),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Column(children: [
                Text('${site?.name ?? 'JUMLA'} · الإصدار 1.0.0', style: ts(12, c: C.faint)),
                const SizedBox(height: 6),
                Pressable(
                  onTap: () => _open(AppConfig.developerUrl),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('برمجة وتطوير ', style: ts(12, c: C.muted)),
                    Container(width: 14, height: 14, decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 5),
                    Text(AppConfig.developer, textDirection: TextDirection.ltr, style: ts(12, w: FontWeight.w700, ls: 1)),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            AnimatedText(value, style: ts(15.5, w: FontWeight.w700)),
            Text(label, style: ts(11.5, c: C.muted)),
          ]),
        ),
      );
}
