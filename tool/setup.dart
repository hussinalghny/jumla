// JUMLA — One-time project setup · Developed by GHANI CODE (ghanicode.com)
// شغّله مرة وحدة بعد فك الضغط:   dart tool/setup.dart
// ينشئ مجلدات Android/iOS، يضيف صلاحية الإنترنت، اسم التطبيق، والأيقونة.
import 'dart:io';

Future<void> _run(String cmd, List<String> args) async {
  stdout.writeln('\n> $cmd ${args.join(' ')}');
  final p = await Process.start(cmd, args, runInShell: true, mode: ProcessStartMode.inheritStdio);
  final code = await p.exitCode;
  if (code != 0) {
    stderr.writeln('فشل الأمر: $cmd ${args.join(' ')}');
    exit(code);
  }
}

Future<void> main() async {
  if (!Directory('android').existsSync() || !Directory('ios').existsSync()) {
    await _run('flutter', ['create', '.', '--org', 'com.jumlapp', '--project-name', 'jumla', '--platforms', 'android,ios']);
  }

  // Android: صلاحية الإنترنت (ضرورية لنسخة الإصدار) + اسم التطبيق
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (manifest.existsSync()) {
    var s = manifest.readAsStringSync();
    if (!s.contains('android.permission.INTERNET')) {
      s = s.replaceFirst('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application');
    }
    s = s.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="جملة"');
    manifest.writeAsStringSync(s);
    stdout.writeln('✓ AndroidManifest.xml');
  }

  // iOS: اسم التطبيق + روابط واتساب والاتصال
  final plist = File('ios/Runner/Info.plist');
  if (plist.existsSync()) {
    var s = plist.readAsStringSync();
    s = s.replaceFirstMapped(RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'), (m) => '${m[1]}جملة${m[2]}');
    if (!s.contains('LSApplicationQueriesSchemes')) {
      s = s.replaceFirst('<dict>',
          '<dict>\n\t<key>LSApplicationQueriesSchemes</key>\n\t<array>\n\t\t<string>https</string>\n\t\t<string>tel</string>\n\t\t<string>whatsapp</string>\n\t</array>');
    }
    plist.writeAsStringSync(s);
    stdout.writeln('✓ Info.plist');
  }

  await _run('flutter', ['pub', 'get']);
  await _run('dart', ['run', 'flutter_launcher_icons']);
  stdout.writeln('\n✓ المشروع جاهز. شغّل التطبيق:  flutter run');
}
