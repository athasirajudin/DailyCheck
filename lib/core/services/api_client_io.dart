import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'api_client_base.dart';

class ApiClientImpl extends ApiClientBase {
  ApiClientImpl({required super.baseUrl});

  final HttpClient _client = HttpClient();
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

  @override
  Future<Object?> deleteJson(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
  }) {
    return _request(
      'DELETE',
      path,
      bearerToken: bearerToken,
      query: query,
      body: null,
    );
  }

  @override
  Future<Uint8List> getBytes(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
  }) {
    return _requestBytes(path, bearerToken: bearerToken, query: query);
  }

  Future<Object?> _request(
    String method,
    String path, {
    required String? bearerToken,
    required Map<String, String>? query,
    required Object? body,
  }) async {
    final url = _buildUrl(path, query);
    final req = await _client.openUrl(method, url);
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    req.headers.set('ngrok-skip-browser-warning', '1');
    if (bearerToken != null && bearerToken.isNotEmpty) {
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
    }
    if (body != null) {
      req.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      req.add(utf8.encode(jsonEncode(body)));
    }

    final resp = await req.close();
    final respBody = await resp.transform(utf8.decoder).join();
    final statusCode = resp.statusCode;
    final contentType = resp.headers.value(HttpHeaders.contentTypeHeader) ?? '';

    Object? decoded;
    try {
      decoded = jsonDecode(respBody);
    } catch (_) {
      final snippet = _snippet(respBody);
      throw ApiError(
        code: _nonJsonCode(respBody),
        message: _nonJsonMessage(
          statusCode: statusCode,
          contentType: contentType,
          body: respBody,
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

  Future<Uint8List> _requestBytes(
    String path, {
    required String? bearerToken,
    required Map<String, String>? query,
  }) async {
    final url = _buildUrl(path, query);
    final req = await _client.openUrl('GET', url);
    req.headers.set(
      HttpHeaders.acceptHeader,
      'text/csv,application/octet-stream,*/*',
    );
    req.headers.set('ngrok-skip-browser-warning', '1');
    if (bearerToken != null && bearerToken.isNotEmpty) {
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
    }

    final resp = await req.close();
    final statusCode = resp.statusCode;
    final contentType = resp.headers.value(HttpHeaders.contentTypeHeader) ?? '';
    final bytes = await _readBytes(resp);
    if (statusCode >= 200 && statusCode < 300) {
      return bytes;
    }

    final respBody = utf8.decode(bytes, allowMalformed: true);
    Object? decoded;
    try {
      decoded = jsonDecode(respBody);
    } catch (_) {
      final snippet = _snippet(respBody);
      throw ApiError(
        code: _nonJsonCode(respBody),
        message: _nonJsonMessage(
          statusCode: statusCode,
          contentType: contentType,
          body: respBody,
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

  Future<Uint8List> _readBytes(Stream<List<int>> stream) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
