// JUMLA — Shared UI (Apple-style) · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'jicon.dart';

/* =================== الحركة =================== */

/// يصغر قليلاً عند اللمس — مثل أزرار iOS
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97, this.haptic = false});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.fast,
        curve: Curves.easeOut,
        child: AnimatedOpacity(opacity: _down ? .85 : 1, duration: Motion.fast, child: widget.child),
      ),
    );
  }
}

/// ظهور تدريجي مع انزلاق بسيط للأعلى (متتالي حسب الترتيب)
class FadeIn extends StatefulWidget {
  const FadeIn({super.key, required this.child, this.index = 0, this.offset = 14});
  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.slow);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Motion.curve);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: math.min(widget.index, 8) * 45), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, (1 - _a.value) * widget.offset), child: child),
      ),
    );
  }
}

/// مستطيل تحميل نابض
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 10});
  final double? width;
  final double height, radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: .45, end: 1.0).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: const Color(0xFFE8E8ED), borderRadius: BorderRadius.circular(widget.radius)),
      ),
    );
  }
}

/// رقم/نص يتغير بحركة ناعمة
class AnimatedText extends StatelessWidget {
  const AnimatedText(this.text, {super.key, required this.style, this.textAlign});
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.base,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(position: Tween(begin: const Offset(0, .25), end: Offset.zero).animate(a), child: child),
      ),
      child: Text(text, key: ValueKey(text), style: style, textAlign: textAlign),
    );
  }
}

/* =================== عناصر أساسية =================== */

class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.radius = 0});
  final String? url;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ph = Container(
      color: C.soft,
      alignment: Alignment.center,
      child: Text('JUMLA', textDirection: TextDirection.ltr, style: ts(13, w: FontWeight.w700, c: C.faint, ls: 3)),
    );
    final img = url == null
        ? ph
        : CachedNetworkImage(
            imageUrl: url!,
            fit: fit,
            fadeInDuration: Motion.base,
            placeholder: (_, __) => Container(color: C.soft),
            errorWidget: (_, __, ___) => ph,
          );
    return radius > 0 ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: img) : img;
  }
}

class CardBox extends StatelessWidget {
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 22, this.color = C.card});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(padding: padding, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)), child: child);
}

enum BtnStyle { primary, dark, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton(this.label,
      {super.key, this.onTap, this.style = BtnStyle.primary, this.icon, this.loading = false, this.expand = true, this.small = false});
  final String label;
  final VoidCallback? onTap;
  final BtnStyle style;
  final String? icon;
  final bool loading, expand, small;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (style) {
      BtnStyle.primary => (C.accent, Colors.white),
      BtnStyle.dark => (C.text, Colors.white),
      BtnStyle.ghost => (const Color(0x0F000000), C.text),
      BtnStyle.danger => (C.badSoft, C.bad),
    };
    final disabled = onTap == null || loading;
    return Pressable(
      onTap: disabled ? null : onTap,
      haptic: true,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: onTap == null ? .45 : 1,
        child: Container(
          height: small ? 38 : 52,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: small ? 14 : 22),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: Motion.fast,
            child: loading
                ? CupertinoActivityIndicator(key: const ValueKey('l'), color: fg)
                : Row(
                    key: ValueKey(label),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[JIcon(icon!, size: small ? 16 : 19, color: fg), const SizedBox(width: 8)],
                      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(small ? 13.5 : 16, w: FontWeight.w600, c: fg))),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class Field extends StatelessWidget {
  const Field({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.keyboard,
    this.obscure = false,
    this.ltr = false,
    this.maxLines = 1,
    this.autofill,
    this.onSubmitted,
    this.action,
  });
  final String label;
  final TextEditingController controller;
  final String? hint, error;
  final TextInputType? keyboard;
  final bool obscure, ltr;
  final int maxLines;
  final Iterable<String>? autofill;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 6, top: 12), child: Text(label, style: ts(13, c: C.muted))),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          minLines: 1,
          autofillHints: autofill,
          textInputAction: action,
          onSubmitted: onSubmitted,
          textDirection: ltr ? TextDirection.ltr : null,
          textAlign: ltr ? TextAlign.right : TextAlign.start,
          style: ts(16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ts(15, c: C.faint),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x1F000000))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? C.bad : const Color(0x1F000000))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.accent, width: 1.5)),
          ),
        ),
        AnimatedSize(
          duration: Motion.fast,
          child: error == null
              ? const SizedBox(width: double.infinity)
              : Padding(padding: const EdgeInsets.only(top: 6), child: Text(error!, style: ts(12.5, c: C.bad))),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction, this.sub});
  final String title;
  final String? sub, action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: ts(22, w: FontWeight.w700)),
              if (sub != null) Text(sub!, style: ts(13.5, c: C.muted)),
            ]),
          ),
          if (action != null)
            Pressable(
              onTap: onAction,
              child: Row(children: [Text(action!, style: ts(14.5, c: C.accent)), const SizedBox(width: 2), const JIcon('chevron-left', size: 16, color: C.accent)]),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.sub, this.action, this.onAction});
  final String icon, title;
  final String? sub, action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: JIcon(icon, size: 38, color: C.faint),
          ),
          const SizedBox(height: 18),
          Text(title, style: ts(20, w: FontWeight.w700), textAlign: TextAlign.center),
          if (sub != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(sub!, style: ts(14.5, c: C.muted, h: 1.5), textAlign: TextAlign.center)),
          if (action != null) Padding(padding: const EdgeInsets.only(top: 22), child: AppButton(action!, onTap: onAction, expand: false)),
        ]),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      EmptyState(icon: 'refresh', title: 'تعذر التحميل', sub: message, action: 'إعادة المحاولة', onAction: onRetry);
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.kind = 'info'});
  final String label;
  final String kind; // info, ok, wait, bad

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (kind) {
      'ok' => (C.okSoft, C.ok),
      'wait' => (C.warnSoft, C.warn),
      'bad' => (C.badSoft, C.bad),
      _ => (C.accentSoft, C.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: ts(12, w: FontWeight.w600, c: fg)),
    );
  }
}

StatusBadge orderBadge(Order o) =>
    StatusBadge(o.statusName, kind: o.cancelled ? 'bad' : (o.delivered ? 'ok' : (o.stage == 0 ? 'wait' : 'info')));

/// سطر في قائمة إعدادات (مثل تطبيق الإعدادات بالآيفون)
class ListRow extends StatelessWidget {
  const ListRow({super.key, required this.icon, required this.title, this.value, this.onTap, this.color = C.text, this.iconBg = C.accent, this.trailing});
  final String icon, title;
  final String? value;
  final VoidCallback? onTap;
  final Color color, iconBg;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: .985,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: JIcon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: ts(16, c: color))),
          if (value != null) Text(value!, style: ts(15, c: C.muted)),
          if (trailing != null) trailing!,
          if (onTap != null && trailing == null) const Padding(padding: EdgeInsets.only(right: 6), child: JIcon('chevron-left', size: 18, color: C.faint)),
        ]),
      ),
    );
  }
}

class Group extends StatelessWidget {
  const Group({super.key, required this.children, this.title});
  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const Padding(padding: EdgeInsets.only(right: 62), child: Divider(height: 1, thickness: .5, color: C.line)));
      rows.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null) Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), child: Text(title!, style: ts(13, c: C.muted))),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(color: Colors.white, child: Column(children: rows)),
        ),
      ]),
    );
  }
}

/// عداد الكمية بالسيري
class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.step, required this.onChanged, this.min, this.compact = false});
  final int value, step;
  final int? min;
  final bool compact;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final minV = min ?? step;
    final h = compact ? 34.0 : 46.0;
    Widget btn(String icon, VoidCallback? f) => Pressable(
          onTap: f,
          haptic: true,
          scale: .9,
          child: SizedBox(width: h, height: h, child: Center(child: JIcon(icon, size: compact ? 16 : 19, color: f == null ? C.faint : C.text))),
        );
    return Container(
      height: h,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x1F000000))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn('plus', () => onChanged(value + step)),
        SizedBox(
          width: compact ? 44 : 60,
          child: AnimatedText('$value', textAlign: TextAlign.center, style: ts(compact ? 14.5 : 17, w: FontWeight.w600)),
        ),
        btn('minus', value - step >= minV ? () => onChanged(value - step) : null),
      ]),
    );
  }
}

/// شريط سفلي زجاجي (blur)
class GlassBar extends StatelessWidget {
  const GlassBar({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: const BoxDecoration(color: Color(0xE6FBFBFD), border: Border(top: BorderSide(color: C.line, width: .5))),
          padding: padding,
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}

/// زر دائري زجاجي (للرجوع فوق الصور)
class GlassCircle extends StatelessWidget {
  const GlassCircle({super.key, required this.icon, required this.onTap});
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: .9,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(width: 40, height: 40, color: const Color(0xB3FFFFFF), alignment: Alignment.center, child: JIcon(icon, size: 20)),
        ),
      ),
    );
  }
}

/// مبدّل العملة $ / د.ع
class CurrencySwitch extends StatelessWidget {
  const CurrencySwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return CupertinoSlidingSegmentedControl<String>(
      groupValue: s.currency,
      padding: const EdgeInsets.all(2),
      children: {
        'USD': Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('\$', style: ts(13, w: FontWeight.w600))),
        'IQD': Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('د.ع', style: ts(13, w: FontWeight.w600))),
      },
      onValueChanged: (v) {
        if (v != null) {
          HapticFeedback.selectionClick();
          s.setCurrency(v);
        }
      },
    );
  }
}

/// صفحة بعنوان كبير قابل للطي (Large Title) مع سحب للتحديث
class LargeTitlePage extends StatelessWidget {
  const LargeTitlePage({super.key, required this.title, required this.slivers, this.trailing, this.onRefresh, this.controller, this.bottomPadding});
  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) {
    // المسافة السفلية = ارتفاع شريط التبويبات (يضيفه Scaffold عبر extendBody) + هامش
    final bottom = bottomPadding ?? MediaQuery.paddingOf(context).bottom + 24;
    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text(title),
          trailing: trailing,
          transitionBetweenRoutes: false,
          backgroundColor: const Color(0xF0F5F5F7),
          border: const Border(bottom: BorderSide(color: C.line, width: .5)),
        ),
        if (onRefresh != null) CupertinoSliverRefreshControl(onRefresh: onRefresh),
        ...slivers,
        SliverToBoxAdapter(child: SizedBox(height: bottom)),
      ],
    );
  }
}

void toast(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Row(children: [
      JIcon(error ? 'alert' : 'check-circle', size: 18, color: Colors.white),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: ts(14, c: Colors.white))),
    ]),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    duration: const Duration(milliseconds: 2200),
  ));
}

Future<bool> confirmDialog(BuildContext context, String title, String body, {String ok = 'تأكيد', bool destructive = false}) async {
  final r = await showCupertinoDialog<bool>(
    context: context,
    builder: (c) => CupertinoAlertDialog(
      title: Text(title, style: ts(17, w: FontWeight.w600)),
      content: Padding(padding: const EdgeInsets.only(top: 6), child: Text(body, style: ts(14, h: 1.5))),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(c, false), child: Text('إلغاء', style: ts(16, c: C.accent))),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok, style: ts(16, w: FontWeight.w600, c: destructive ? C.bad : C.accent)),
        ),
      ],
    ),
  );
  return r == true;
}

/// قائمة اختيار من الأسفل (مثل iOS Action Sheet)
Future<String?> pickFrom(BuildContext context, String title, List<String> options, {String? selected}) {
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (c) => CupertinoActionSheet(
      title: Text(title, style: ts(13, c: C.muted)),
      actions: [
        for (final o in options)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(c, o),
            child: Text(o, style: ts(17, w: o == selected ? FontWeight.w700 : FontWeight.w400, c: C.accent)),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text('إلغاء', style: ts(17, w: FontWeight.w600, c: C.accent))),
    ),
  );
}

Route<T> slideRoute<T>(Widget page) => CupertinoPageRoute<T>(builder: (_) => page);

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: Motion.slow,
      reverseTransitionDuration: Motion.base,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Motion.curve),
        child: ScaleTransition(scale: Tween(begin: .98, end: 1.0).animate(CurvedAnimation(parent: a, curve: Motion.curve)), child: child),
      ),
    );
