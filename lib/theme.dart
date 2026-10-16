// JUMLA — Apple-style theme · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// ألوان التطبيق (نفس هوية الموقع)
class C {
  static const bg = Color(0xFFF5F5F7);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF1D1D1F);
  static const muted = Color(0xFF6E6E73);
  static const faint = Color(0xFFAEAEB2);
  static const line = Color(0x14000000);
  static const soft = Color(0xFFF0F0F2);
  static const accent = Color(0xFF0071E3);
  static const accentSoft = Color(0x140071E3);
  static const ok = Color(0xFF1A9F55);
  static const okSoft = Color(0x1F1A9F55);
  static const bad = Color(0xFFD70015);
  static const badSoft = Color(0x17D70015);
  static const warn = Color(0xFFBF6A02);
  static const warnSoft = Color(0x1FBF6A02);
  static const star = Color(0xFFF5A623);
  static const brand = Color(0xFF00A2AE);
}

TextStyle ts(double size, {FontWeight w = FontWeight.w400, Color c = C.text, double? h, double? ls}) =>
    TextStyle(fontFamily: 'Plex', fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);

/// منحنيات وأزمنة الحركة — قصيرة وناعمة بأسلوب Apple
class Motion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;
  static const spring = Curves.easeOutBack;
}

ThemeData buildTheme() {
  const plex = 'Plex';
  return ThemeData(
    useMaterial3: true,
    fontFamily: plex,
    brightness: Brightness.light,
    scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: C.accent, primary: C.accent, surface: C.card, brightness: Brightness.light),
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    dividerColor: C.line,
    textSelectionTheme: const TextSelectionThemeData(cursorColor: C.accent, selectionColor: C.accentSoft, selectionHandleColor: C.accent),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xEB1D1D1F),
      contentTextStyle: ts(14, c: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: C.accent,
      barBackgroundColor: Color(0xF0F5F5F7),
      scaffoldBackgroundColor: C.bg,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(fontFamily: plex, fontSize: 16, color: C.text),
        actionTextStyle: TextStyle(fontFamily: plex, fontSize: 16, color: C.accent),
        navTitleTextStyle: TextStyle(fontFamily: plex, fontSize: 17, fontWeight: FontWeight.w600, color: C.text),
        navLargeTitleTextStyle: TextStyle(fontFamily: plex, fontSize: 30, fontWeight: FontWeight.w700, color: C.text),
        navActionTextStyle: TextStyle(fontFamily: plex, fontSize: 16, color: C.accent),
      ),
    ),
  );
}
