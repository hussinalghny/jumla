// JUMLA — Merchant app
// Developed by GHANI CODE · https://ghanicode.com · © All rights reserved.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFFFBFBFD),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const JumlaApp()));
}

class JumlaApp extends StatelessWidget {
  const JumlaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جملة',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        // منع تكبير الخط المبالغ فيه حتى لا ينكسر التصميم
        data: MediaQuery.of(context).copyWith(textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2)),
        child: child!,
      ),
      home: const SplashScreen(),
    );
  }
}
