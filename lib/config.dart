// JUMLA — App configuration · Developed by GHANI CODE (ghanicode.com) · © All rights reserved

class AppConfig {
  /// رابط الـ API. يمكن تغييره وقت البناء:
  /// flutter run --dart-define=API_BASE=https://jumlapp.com/api
  static const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'https://jumlapp.com/api');
  static const appName = 'جملة';
  static const developer = 'GHANI CODE';
  static const developerUrl = 'https://ghanicode.com';
}
