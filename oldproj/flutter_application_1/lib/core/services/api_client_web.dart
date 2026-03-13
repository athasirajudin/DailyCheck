// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

import 'api_client_base.dart';

class ApiClientImpl extends ApiClientBase {
  ApiClientImpl({required super.baseUrl});
  static const int _bodySnippetMax = 220;

  @override
  Future<Object?> getJson(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
  }) {
    return _request(
      'GET',
      path,
      bearerToken: bearerToken,
      query: query,
      body: null,
    );
  }

  @override
  Future<Object?> postJson(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
    Object? body,
  }) {
    return _request(
      'POST',
      path,
      bearerToken: bearerToken,
      query: query,
      body: body,
    );
  }

  Future<Object?> _request(
    String method,
    String path, {
    required String? bearerToken,
    required Map<String, String>? query,
    required Object? body,
  }) async {
    final uri = _buildUrl(path, query);
    final req = await html.HttpRequest.request(
      uri.toString(),
      method: method,
      sendData: body == null ? null : jsonEncode(body),
      requestHeaders: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': '1',
        if (body != null) 'Content-Type': 'application/json; charset=utf-8',
        if (bearerToken != null && bearerToken.isNotEmpty)
          'Authorization': 'Bearer $bearerToken',
      },
    );
    final statusCode = req.status ?? 0;
    final contentType = req.getResponseHeader('content-type') ?? '';
    Object? decoded;
    try {
      decoded = jsonDecode(req.responseText ?? '');
    } catch (_) {
      final raw = req.responseText ?? '';
      final snippet = _snippet(raw);
      throw ApiError(
        code: _nonJsonCode(raw),
        message: _nonJsonMessage(
          statusCode: statusCode,
          contentType: contentType,
          body: raw,
        ),
        statusCode: statusCode,
        extra: {'contentType': contentType, 'bodySnippet': snippet},
      );
    }
    if (decoded is! Map) {
      throw ApiError(
        code: 'BAD_RESPONSE',
        message: 'Format response tidak valid.',
        statusCode: statusCode,
      );
    }
    final map = Map<String, dynamic>.from(decoded);
    final ok = map['ok'] == true;
    if (ok) {
      return map['data'];
    }
    final err = map['error'];
    if (err is Map) {
      final errMap = Map<String, dynamic>.from(err);
      throw ApiError(
        code: (errMap['code'] ?? 'ERROR').toString(),
        message: (errMap['message'] ?? 'Terjadi error.').toString(),
        statusCode: statusCode,
        extra: map['extra'],
      );
    }
    throw ApiError(
      code: 'ERROR',
      message: 'Terjadi error.',
      statusCode: statusCode,
      extra: map['extra'],
    );
  }

  Uri _buildUrl(String path, Map<String, String>? query) {
    final b = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$b$p');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  String _nonJsonCode(String body) {
    final lower = body.toLowerCase();
    if (lower.contains('ngrok')) {
      return 'NGROK_HTML_RESPONSE';
    }
    return 'BAD_RESPONSE';
  }

  String _nonJsonMessage({
    required int statusCode,
    required String contentType,
    required String body,
  }) {
    final lower = body.toLowerCase();
    if (lower.contains('ngrok')) {
      return 'Response dari ngrok bukan JSON. Cek tunnel aktif dan URL base benar.';
    }
    if (contentType.contains('text/html') || lower.contains('<html')) {
      return 'Response server berupa HTML (status $statusCode), bukan JSON API.';
    }
    return 'Response server bukan JSON (status $statusCode).';
  }

  String _snippet(String body) {
    final compact = body.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    if (compact.length <= _bodySnippetMax) {
      return compact;
    }
    return '${compact.substring(0, _bodySnippetMax)}...';
  }
}
