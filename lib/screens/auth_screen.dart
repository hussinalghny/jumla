// JUMLA — Login / Register · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/jicon.dart';
import '../widgets/ui.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.register = false});
  final bool register;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _register = widget.register;
  final _name = TextEditingController();
  final _shop = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _address = TextEditingController();
  String _city = 'بغداد';
  Map<String, String> _errors = {};
  bool _busy = false;
  bool _show = false;

  @override
  void dispose() {
    for (final c in [_name, _shop, _phone, _pass, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final s = context.read<AppState>();
    setState(() {
      _busy = true;
      _errors = {};
    });
    try {
      if (_register) {
        await s.register({
          'name': _name.text.trim(),
          'shop_name': _shop.text.trim(),
          'phone': _phone.text.trim(),
          'city': _city,
          'address': _address.text.trim(),
          'password': _pass.text,
        });
      } else {
        await s.login(_phone.text.trim(), _pass.text);
      }
      if (!mounted) return;
      toast(context, _register ? 'تم إنشاء حسابك، أهلاً بك' : 'أهلاً ${s.me?.name ?? ''}');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errors = e.fields;
      });
      if (e.fields.isEmpty || e.code != 'validation') toast(context, e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, 'حدث خطأ، حاول مرة أخرى', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: C.bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LargeTitlePage(
          title: _register ? 'حساب تاجر جديد' : 'تسجيل الدخول',
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(children: [
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<bool>(
                      groupValue: _register,
                      children: {
                        false: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text('دخول', style: ts(14, w: FontWeight.w600))),
                        true: Text('حساب جديد', style: ts(14, w: FontWeight.w600)),
                      },
                      onValueChanged: (v) => setState(() {
                        _register = v ?? false;
                        _errors = {};
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CardBox(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: AutofillGroup(
                      child: AnimatedSize(
                        duration: Motion.base,
                        curve: Motion.curve,
                        alignment: Alignment.topCenter,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (_register) ...[
                            Field(label: 'الاسم الكامل', controller: _name, error: _errors['name'], autofill: const [AutofillHints.name], action: TextInputAction.next),
                            Field(label: 'اسم المحل (اختياري)', controller: _shop, error: _errors['shop_name'], action: TextInputAction.next),
                          ],
                          Field(
                            label: 'رقم الهاتف',
                            controller: _phone,
                            hint: '07xx xxx xxxx',
                            keyboard: TextInputType.phone,
                            ltr: true,
                            error: _errors['phone'],
                            autofill: const [AutofillHints.telephoneNumber, AutofillHints.username],
                            action: TextInputAction.next,
                          ),
                          if (_register) ...[
                            Padding(padding: const EdgeInsets.only(bottom: 6, top: 12), child: Text('المحافظة', style: ts(13, c: C.muted))),
                            Pressable(
                              scale: .985,
                              onTap: () async {
                                final v = await pickFrom(context, 'اختر المحافظة', s.config?.governorates ?? const ['بغداد'], selected: _city);
                                if (v != null) setState(() => _city = v);
                              },
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x1F000000))),
                                child: Row(children: [Expanded(child: Text(_city, style: ts(16))), const JIcon('chevron-down', size: 18, color: C.muted)]),
                              ),
                            ),
                            Field(label: 'العنوان (اختياري)', controller: _address, action: TextInputAction.next),
                          ],
                          Stack(children: [
                            Field(
                              label: 'كلمة السر',
                              controller: _pass,
                              obscure: !_show,
                              ltr: true,
                              error: _errors['password'],
                              autofill: [_register ? AutofillHints.newPassword : AutofillHints.password],
                              action: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                            ),
                            PositionedDirectional(
                              end: 4,
                              top: 36,
                              child: Pressable(
                                onTap: () => setState(() => _show = !_show),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(_show ? 'إخفاء' : 'إظهار', style: ts(13, c: C.accent)),
                                ),
                              ),
                            ),
                          ]),
                          if (_register) Padding(padding: const EdgeInsets.only(top: 6), child: Text('8 أحرف على الأقل', style: ts(12, c: C.faint))),
                          const SizedBox(height: 20),
                          AppButton(_register ? 'إنشاء الحساب' : 'دخول', loading: _busy, onTap: _submit),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _register ? 'بإنشاء الحساب توافق على شروط الخدمة وسياسة الخصوصية.' : 'نسيت كلمة السر؟ تواصل مع خدمة العملاء لإعادة تعيينها.',
                    textAlign: TextAlign.center,
                    style: ts(12.5, c: C.muted, h: 1.5),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
