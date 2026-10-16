// JUMLA — SVG-path icon widget · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'package:flutter/widgets.dart';

import 'jicon_data.dart';

/// أيقونة خطية بنفس تصميم أيقونات الموقع.
class JIcon extends StatelessWidget {
  const JIcon(this.name, {super.key, this.size = 22, this.color, this.fill = false, this.stroke = 1.75});

  final String name;
  final double size;
  final Color? color;
  final bool fill;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF1D1D1F);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _IconPainter(_IconCache.get(name), c, fill, stroke)),
    );
  }
}

class _IconCache {
  static final Map<String, Path> _cache = {};
  static Path get(String name) =>
      _cache.putIfAbsent(name, () => parseSvgPath(kIconPaths[name] ?? kIconPaths['tag']!));
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.path, this.color, this.fill, this.stroke);
  final Path path;
  final Color color;
  final bool fill;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    if (fill) {
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.path != path || old.color != color || old.fill != fill || old.stroke != stroke;
}

final RegExp _tokenRe = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
final RegExp _cmdRe = RegExp(r'^[MmLlHhVvCcSsQqTtAaZz]$');

/// محلل مسارات SVG (يدعم كل أوامر path القياسية).
Path parseSvgPath(String d) {
  final t = _tokenRe.allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var cmd = 'M';
  var last = '';
  double cx = 0, cy = 0, sx = 0, sy = 0, ctrlX = 0, ctrlY = 0;

  double n() => double.parse(t[i++]);

  while (i < t.length) {
    if (_cmdRe.hasMatch(t[i])) {
      cmd = t[i];
      i++;
    }
    switch (cmd) {
      case 'M':
        cx = n();
        cy = n();
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        cmd = 'L';
        break;
      case 'm':
        cx += n();
        cy += n();
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        cmd = 'l';
        break;
      case 'L':
        cx = n();
        cy = n();
        path.lineTo(cx, cy);
        break;
      case 'l':
        cx += n();
        cy += n();
        path.lineTo(cx, cy);
        break;
      case 'H':
        cx = n();
        path.lineTo(cx, cy);
        break;
      case 'h':
        cx += n();
        path.lineTo(cx, cy);
        break;
      case 'V':
        cy = n();
        path.lineTo(cx, cy);
        break;
      case 'v':
        cy += n();
        path.lineTo(cx, cy);
        break;
      case 'C':
      case 'c':
        {
          final rel = cmd == 'c';
          final ox = rel ? cx : 0.0, oy = rel ? cy : 0.0;
          final x1 = ox + n(), y1 = oy + n(), x2 = ox + n(), y2 = oy + n(), x = ox + n(), y = oy + n();
          path.cubicTo(x1, y1, x2, y2, x, y);
          ctrlX = x2;
          ctrlY = y2;
          cx = x;
          cy = y;
        }
        break;
      case 'S':
      case 's':
        {
          final rel = cmd == 's';
          final ox = rel ? cx : 0.0, oy = rel ? cy : 0.0;
          final reflect = last.isNotEmpty && 'CcSs'.contains(last);
          final x1 = reflect ? 2 * cx - ctrlX : cx, y1 = reflect ? 2 * cy - ctrlY : cy;
          final x2 = ox + n(), y2 = oy + n(), x = ox + n(), y = oy + n();
          path.cubicTo(x1, y1, x2, y2, x, y);
          ctrlX = x2;
          ctrlY = y2;
          cx = x;
          cy = y;
        }
        break;
      case 'Q':
      case 'q':
        {
          final rel = cmd == 'q';
          final ox = rel ? cx : 0.0, oy = rel ? cy : 0.0;
          final x1 = ox + n(), y1 = oy + n(), x = ox + n(), y = oy + n();
          path.quadraticBezierTo(x1, y1, x, y);
          ctrlX = x1;
          ctrlY = y1;
          cx = x;
          cy = y;
        }
        break;
      case 'T':
      case 't':
        {
          final rel = cmd == 't';
          final ox = rel ? cx : 0.0, oy = rel ? cy : 0.0;
          final reflect = last.isNotEmpty && 'QqTt'.contains(last);
          final x1 = reflect ? 2 * cx - ctrlX : cx, y1 = reflect ? 2 * cy - ctrlY : cy;
          final x = ox + n(), y = oy + n();
          path.quadraticBezierTo(x1, y1, x, y);
          ctrlX = x1;
          ctrlY = y1;
          cx = x;
          cy = y;
        }
        break;
      case 'A':
      case 'a':
        {
          final rel = cmd == 'a';
          final rx = n(), ry = n(), rot = n();
          final large = n() != 0, sweep = n() != 0;
          final x = (rel ? cx : 0.0) + n(), y = (rel ? cy : 0.0) + n();
          path.arcToPoint(Offset(x, y), radius: Radius.elliptical(rx, ry), rotation: rot, largeArc: large, clockwise: sweep);
          cx = x;
          cy = y;
        }
        break;
      case 'Z':
      case 'z':
        path.close();
        cx = sx;
        cy = sy;
        // تجاهل أي أرقام شاذة بعد Z لتجنب حلقة لا نهائية
        if (i < t.length && !_cmdRe.hasMatch(t[i])) i++;
        break;
      default:
        i++;
    }
    last = cmd;
  }
  return path;
}
