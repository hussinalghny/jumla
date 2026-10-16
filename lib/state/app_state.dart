// JUMLA — App state (config, auth, cart) · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import '../api/models.dart';

class GuestOrder {
  GuestOrder(this.code, this.phone);
  final String code, phone;
  Map<String, String> toJson() => {'code': code, 'phone': phone};
}

class AppState extends ChangeNotifier {
  ConfigData? config;
  Customer? me;
  String currency = 'USD';
  String ship = 'land';
  final Map<int, int> cart = {};
  final List<GuestOrder> guestOrders = [];

  /// التبويب الحالي (للتنقل من أي شاشة)
  final ValueNotifier<int> tab = ValueNotifier<int>(0);

  late SharedPreferences _prefs;
  static const _secure = FlutterSecureStorage();
  static const _tokenKey = 'jumla_token';

  bool get loggedIn => me != null;
  int get cartCount => cart.length;

  /* ---------------- تشغيل ---------------- */
  bool _started = false;

  Future<void> init() async {
    if (_started) {
      // إعادة المحاولة بعد فشل الاتصال: نعيد تحميل الإعدادات فقط
      await loadConfig();
      if (Api.i.token != null && me == null) {
        try {
          await refreshMe();
        } catch (_) {}
      }
      notifyListeners();
      return;
    }
    _started = true;
    _prefs = await SharedPreferences.getInstance();
    currency = _prefs.getString('cur') ?? 'USD';
    ship = _prefs.getString('ship') ?? 'land';
    try {
      final raw = _prefs.getString('cart');
      if (raw != null) {
        (jsonDecode(raw) as Map).forEach((k, v) => cart[int.parse('$k')] = (v as num).toInt());
      }
      final go = _prefs.getString('guest_orders');
      if (go != null) {
        for (final e in jsonDecode(go) as List) {
          guestOrders.add(GuestOrder('${e['code']}', '${e['phone']}'));
        }
      }
    } catch (_) {}
    Api.i.token = await _readToken();
    await loadConfig();
    if (Api.i.token != null) {
      try {
        await refreshMe();
      } on ApiException catch (e) {
        if (e.status == 401) await _writeToken(null);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> loadConfig() async {
    final r = await Api.i.get('/config');
    config = ConfigData.fromJson(r.data);
    if (config!.ship(ship) == null && config!.shipMethods.isNotEmpty) ship = config!.shipMethods.first.key;
  }

  /* ---------------- العملة ---------------- */
  void setCurrency(String c) {
    currency = c;
    _prefs.setString('cur', c);
    notifyListeners();
  }

  String money(Money m) => currency == 'IQD' ? '${groupDigits(m.iqd)} د.ع' : '\$${m.usd.toStringAsFixed(2)}';
  String moneyAlt(Money m) => currency == 'IQD' ? '\$${m.usd.toStringAsFixed(2)}' : '${groupDigits(m.iqd)} د.ع';

  /* ---------------- السلة ---------------- */
  int qtyInCart(int id) => cart[id] ?? 0;

  void addToCart(Product p, int qty) {
    cart[p.id] = (cart[p.id] ?? 0) + qty;
    _saveCart();
  }

  void setQty(int id, int qty) {
    if (qty <= 0) {
      cart.remove(id);
    } else {
      cart[id] = qty;
    }
    _saveCart();
  }

  void removeMany(Iterable<int> ids) {
    for (final id in ids) {
      cart.remove(id);
    }
    _saveCart();
  }

  void clearCart() {
    cart.clear();
    _saveCart();
  }

  void setShip(String key) {
    ship = key;
    _prefs.setString('ship', key);
    notifyListeners();
  }

  List<Map<String, int>> get cartItems => cart.entries.map((e) => {'product_id': e.key, 'qty': e.value}).toList();

  void _saveCart() {
    _prefs.setString('cart', jsonEncode(cart.map((k, v) => MapEntry('$k', v))));
    notifyListeners();
  }

  /* ---------------- الطلبات (زائر) ---------------- */
  void rememberGuestOrder(String code, String phone) {
    guestOrders.removeWhere((g) => g.code == code);
    guestOrders.insert(0, GuestOrder(code, phone));
    _prefs.setString('guest_orders', jsonEncode(guestOrders.map((g) => g.toJson()).toList()));
    notifyListeners();
  }

  /* ---------------- الحساب ---------------- */
  String get _device => 'JUMLA ${defaultTargetPlatform.name}';

  Future<void> login(String phone, String password) async {
    final r = await Api.i.post('/auth/login', {'phone': phone, 'password': password, 'device': _device});
    await _afterAuth(r.data);
  }

  Future<void> register(Map<String, String> data) async {
    final r = await Api.i.post('/auth/register', {...data, 'device': _device});
    await _afterAuth(r.data);
  }

  Future<void> _afterAuth(dynamic data) async {
    await _writeToken('${data['token']}');
    me = Customer.fromJson(data['customer']);
    notifyListeners();
    try {
      await refreshMe();
    } catch (_) {}
  }

  Future<void> refreshMe() async {
    final r = await Api.i.get('/me');
    me = Customer.fromJson(r.data);
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, String> data) async {
    final r = await Api.i.patch('/me', data);
    me = Customer.fromJson(r.data);
    notifyListeners();
    try {
      await refreshMe();
    } catch (_) {}
  }

  Future<void> changePassword(String current, String next) async {
    await Api.i.post('/me/password', {'current_password': current, 'new_password': next});
  }

  Future<void> logout() async {
    try {
      await Api.i.post('/auth/logout');
    } catch (_) {}
    await _writeToken(null);
    me = null;
    notifyListeners();
  }

  Future<void> deleteAccount(String password) async {
    await Api.i.delete('/me', {'password': password});
    await _writeToken(null);
    me = null;
    notifyListeners();
  }

  /* ---------------- تخزين التوكن ---------------- */
  Future<String?> _readToken() async {
    try {
      return await _secure.read(key: _tokenKey);
    } catch (_) {
      return _prefs.getString(_tokenKey);
    }
  }

  Future<void> _writeToken(String? t) async {
    Api.i.token = t;
    try {
      if (t == null) {
        await _secure.delete(key: _tokenKey);
      } else {
        await _secure.write(key: _tokenKey, value: t);
      }
    } catch (_) {
      if (t == null) {
        await _prefs.remove(_tokenKey);
      } else {
        await _prefs.setString(_tokenKey, t);
      }
    }
  }
}

/// 1234567 → 1,234,567
String groupDigits(num n) {
  final s = n.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

/// "2026-10-08 13:20:11" → "8 تشرين الأول 2026"
String arDate(String raw, {bool time = false}) {
  final d = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (d == null) return raw;
  const months = ['كانون الثاني', 'شباط', 'آذار', 'نيسان', 'أيار', 'حزيران', 'تموز', 'آب', 'أيلول', 'تشرين الأول', 'تشرين الثاني', 'كانون الأول'];
  final t = time ? ' · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}' : '';
  return '${d.day} ${months[d.month - 1]} ${d.year}$t';
}
