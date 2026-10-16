// JUMLA — Unit tests · Developed by GHANI CODE (ghanicode.com)
import 'package:flutter_test/flutter_test.dart';
import 'package:jumla/api/models.dart';
import 'package:jumla/state/app_state.dart';
import 'package:jumla/widgets/jicon.dart';
import 'package:jumla/widgets/jicon_data.dart';

void main() {
  test('تنسيق الأرقام', () {
    expect(groupDigits(1234567), '1,234,567');
    expect(groupDigits(250), '250');
    expect(groupDigits(0), '0');
  });

  test('كل الأيقونات تتحلل بشكل صحيح', () {
    final bad = <String>[];
    for (final e in kIconPaths.entries) {
      final b = parseSvgPath(e.value).getBounds();
      final ok = (b.width > 0 || b.height > 0) && b.left >= -2 && b.top >= -2 && b.right <= 26 && b.bottom <= 26;
      if (!ok) bad.add('${e.key}=${b.left.toStringAsFixed(1)},${b.top.toStringAsFixed(1)},${b.right.toStringAsFixed(1)},${b.bottom.toStringAsFixed(1)}');
    }
    expect(bad, isEmpty);
  });

  test('قراءة المنتج من الـ API', () {
    final p = Product.fromJson({
      'id': 13,
      'name': 'جاكيت',
      'price': {'usd': 12.22, 'iqd': 16000},
      'pack_qty': 10,
      'sizes': [
        {'size': 'M', 'qty': 5},
        {'size': 'L', 'qty': 5}
      ],
      'image': 'https://jumlapp.com/uploads/products/p13-1.jpg',
    });
    expect(p.packQty, 10);
    expect(p.sizesShort, 'M/L');
    expect(p.price.times(20).usd, closeTo(244.4, .001));
  });
}
