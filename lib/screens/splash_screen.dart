// JUMLA — Splash · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'root_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (_error != null) setState(() => _error = null);
    final minDelay = Future.delayed(const Duration(milliseconds: 1100));
    try {
      await context.read<AppState>().init();
      await minDelay;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(const RootShell()));
    } catch (e) {
      await minDelay;
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween(begin: .92, end: 1.0).animate(fade),
              child: Text('JUMLA', textDirection: TextDirection.ltr, style: ts(40, w: FontWeight.w700, ls: 10)),
            ),
          ),
          const SizedBox(height: 10),
          FadeTransition(
            opacity: CurvedAnimation(parent: _c, curve: const Interval(.4, 1, curve: Curves.easeOut)),
            child: Text('من مصانع الصين إلى مخزنك', style: ts(15, c: C.muted)),
          ),
          AnimatedSize(
            duration: Motion.base,
            child: _error == null
                ? const SizedBox(height: 0, width: 200)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(40, 36, 40, 0),
                    child: Column(children: [
                      Text('تعذر الاتصال بالخادم', style: ts(16, w: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(_error!, textAlign: TextAlign.center, style: ts(13.5, c: C.muted)),
                      const SizedBox(height: 18),
                      AppButton('إعادة المحاولة', icon: 'refresh', expand: false, onTap: _start),
                    ]),
                  ),
          ),
        ]),
      ),
    );
  }
}
