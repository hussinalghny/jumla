// JUMLA — Profile & password forms · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AppState _s;
  late final TextEditingController _name, _shop, _address;
  String _city = 'بغداد';
  Map<String, String> _errors = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _s = context.read<AppState>();
    final me = _s.me;
    _name = TextEditingController(text: me?.name ?? '');
    _shop = TextEditingController(text: me?.shopName ?? '');
    _address = TextEditingController(text: me?.address ?? '');
    if (me != null && me.city.isNotEmpty) _city = me.city;
  }

  @override
  void dispose() {
    _name.dispose();
    _shop.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _errors = {};
    });
    try {
      await _s.updateProfile({'name': _name.text.trim(), 'shop_name': _shop.text.trim(), 'city': _city, 'address': _address.text.trim()});
      if (!mounted) return;
      toast(context, 'تم حفظ البيانات');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errors = e.fields;
      });
      toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LargeTitlePage(title: 'تعديل البيانات', slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: CardBox(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Field(label: 'الاسم', controller: _name, error: _errors['name']),
                  Field(label: 'اسم المحل', controller: _shop),
                  Padding(padding: const EdgeInsets.only(bottom: 6, top: 12), child: Text('المحافظة', style: ts(13, c: C.muted))),
                  Pressable(
                    scale: .985,
                    onTap: () async {
                      final v = await pickFrom(context, 'اختر المحافظة', _s.config?.governorates ?? const ['بغداد'], selected: _city);
                      if (v != null) setState(() => _city = v);
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x1F000000))),
                      child: Row(children: [Expanded(child: Text(_city, style: ts(16))), const JIcon('chevron-down', size: 18, color: C.muted)]),
                    ),
                  ),
                  Field(label: 'العنوان', controller: _address),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text('رقم الهاتف: ${_s.me?.phone ?? ''} — لتغييره تواصل مع خدمة العملاء.', style: ts(12.5, c: C.muted)),
                  ),
                  const SizedBox(height: 20),
                  AppButton('حفظ', loading: _busy, onTap: _save),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  Map<String, String> _errors = {};
  bool _busy = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_new.text.length < 8) {
      setState(() => _errors = {'new_password': '8 أحرف على الأقل'});
      return;
    }
    setState(() {
      _busy = true;
      _errors = {};
    });
    try {
      await context.read<AppState>().changePassword(_old.text, _new.text);
      if (!mounted) return;
      toast(context, 'تم تغيير كلمة السر');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errors = e.fields;
      });
      toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: LargeTitlePage(title: 'كلمة السر', slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: CardBox(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Field(label: 'كلمة السر الحالية', controller: _old, obscure: true, ltr: true, error: _errors['current_password']),
                Field(label: 'كلمة السر الجديدة', controller: _new, obscure: true, ltr: true, error: _errors['new_password'], hint: '8 أحرف على الأقل'),
                const SizedBox(height: 8),
                Text('بعد التغيير راح يطلع حسابك من باقي الأجهزة.', style: ts(12.5, c: C.muted)),
                const SizedBox(height: 20),
                AppButton('تغيير كلمة السر', style: BtnStyle.dark, loading: _busy, onTap: _save),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
