import 'dart:async';
// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

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
    final uri = _buildUrl(path, query);
    final req = await _sendRequest(
      uri,
      method: method,
      bearerToken: bearerToken,
      body: body,
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

  Future<Uint8List> _requestBytes(
    String path, {
    required String? bearerToken,
    required Map<String, String>? query,
  }) async {
    final uri = _buildUrl(path, query);
    final req = await _sendRequest(
      uri,
      method: 'GET',
      bearerToken: bearerToken,
      responseType: 'arraybuffer',
    );
    final statusCode = req.status ?? 0;
    final contentType = req.getResponseHeader('content-type') ?? '';
    final bytes = _bytesFromResponse(req.response);
    if (statusCode >= 200 && statusCode < 300) {
      return bytes;
    }

    final raw = utf8.decode(bytes, allowMalformed: true);
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
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

  Future<html.HttpRequest> _sendRequest(
    Uri uri, {
    required String method,
    String? bearerToken,
    Object? body,
    String? responseType,
  }) async {
    final completer = Completer<html.HttpRequest>();
    final request = html.HttpRequest();
    try {
      request
        ..open(method, uri.toString(), async: true)
        ..responseType = responseType ?? ''
        ..setRequestHeader(
          'Accept',
          responseType == 'arraybuffer'
              ? 'text/csv,application/octet-stream,*/*'
              : 'application/json',
        )
        ..setRequestHeader('ngrok-skip-browser-warning', '1');
      if (body != null) {
        request.setRequestHeader(
          'Content-Type',
          'application/json; charset=utf-8',
        );
      }
      if (bearerToken != null && bearerToken.isNotEmpty) {
        request.setRequestHeader('Authorization', 'Bearer $bearerToken');
      }

      request.onLoad.first.then((_) {
        if (!completer.isCompleted) {
          completer.complete(request);
        }
      });
      request.onError.first.then((event) {
        if (!completer.isCompleted) {
          completer.completeError(event);
        }
      });
      request.onAbort.first.then((event) {
        if (!completer.isCompleted) {
          completer.completeError(event);
        }
      });
      request.onTimeout.first.then((event) {
        if (!completer.isCompleted) {
          completer.completeError(event);
        }
      });

      request.send(body == null ? null : jsonEncode(body));
      return await completer.future;
    } catch (e) {
      throw ApiError(
        code: _webRequestErrorCode(e),
        message: _webRequestErrorMessage(uri, e),
      );
    }
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

  String _webRequestErrorCode(Object e) {
    final text = e.toString().toLowerCase();
    if (text.contains('progressevent')) {
      return 'WEB_REQUEST_FAILED';
    }
    return 'REQUEST_FAILED';
  }

  String _webRequestErrorMessage(Uri uri, Object e) {
    final host = uri.host.isEmpty ? uri.toString() : uri.host;
    final text = e.toString().toLowerCase();
    if (text.contains('progressevent')) {
      return 'Request ke server gagal atau timeout. Cek koneksi, ngrok, dan akses ke $host.';
    }
    return 'Request ke server gagal. Cek koneksi ke $host.';
  }

  Uint8List _bytesFromResponse(Object? response) {
    if (response is ByteBuffer) {
      return response.asUint8List();
    }
    if (response is Uint8List) {
      return response;
    }
    if (response is List<int>) {
      return Uint8List.fromList(response);
    }
    if (response is String) {
      return Uint8List.fromList(utf8.encode(response));
    }
    return Uint8List(0);
  }
}
