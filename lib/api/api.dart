// JUMLA — REST client · Developed by GHANI CODE (ghanicode.com) · © All rights reserved
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.code = 'error', this.status = 0, this.fields = const {}});
  final String message;
  final String code;
  final int status;
  final Map<String, String> fields;

  @override
  String toString() => message;
}

class ApiResult {
  ApiResult(this.data, this.meta);
  final dynamic data;
  final Map<String, dynamic>? meta;

  int get pages => (meta?['pages'] as num?)?.toInt() ?? 1;
  int get total => (meta?['total'] as num?)?.toInt() ?? 0;
}

class Api {
  Api._();
  static final Api i = Api._();

  String? token;
  final http.Client _client = http.Client();

  Uri _uri(String path, Map<String, String>? query) {
    var base = AppConfig.apiBase;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    final u = Uri.parse('$base$path');
    return (query == null || query.isEmpty) ? u : u.replace(queryParameters: query);
  }

  Future<ApiResult> _send(String method, String path, {Map<String, String>? query, Object? body}) async {
    final req = http.Request(method, _uri(path, query));
    req.headers['Accept'] = 'application/json';
    req.headers['Content-Type'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) req.body = jsonEncode(body);

    http.Response res;
    try {
      final streamed = await _client.send(req).timeout(const Duration(seconds: 25));
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('انتهت مهلة الاتصال، تحقق من الإنترنت', code: 'timeout');
    } catch (_) {
      throw ApiException('تعذر الاتصال بالخادم، تحقق من الإنترنت', code: 'network');
    }

    dynamic j;
    try {
      j = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ApiException('رد غير متوقع من الخادم', status: res.statusCode);
    }
    if (j is Map && j['ok'] == true) {
      final meta = j['meta'];
      return ApiResult(j['data'], meta is Map ? Map<String, dynamic>.from(meta) : null);
    }
    final err = (j is Map && j['error'] is Map) ? j['error'] as Map : const {};
    final fields = <String, String>{};
    final f = err['fields'];
    if (f is Map) f.forEach((k, v) => fields['$k'] = '$v');
    throw ApiException('${err['message'] ?? 'حدث خطأ غير متوقع'}',
        code: '${err['code'] ?? 'error'}', status: res.statusCode, fields: fields);
  }

  Future<ApiResult> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);
  Future<ApiResult> post(String path, [Object? body]) => _send('POST', path, body: body ?? const <String, dynamic>{});
  Future<ApiResult> patch(String path, Object body) => _send('PATCH', path, body: body);
  Future<ApiResult> delete(String path, [Object? body]) => _send('DELETE', path, body: body ?? const <String, dynamic>{});
}
