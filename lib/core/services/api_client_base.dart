import 'dart:typed_data';

class ApiError implements Exception {
  ApiError({
    required this.code,
    required this.message,
    this.statusCode,
    this.extra,
  });

  final String code;
  final String message;
  final int? statusCode;
  final Object? extra;

  @override
  String toString() => 'ApiError($code): $message';
}

abstract class ApiClient {
  String get baseUrl;
  set baseUrl(String value);

  Future<Object?> getJson(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
  });

  Future<Object?> postJson(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
    Object? body,
  });

  Future<Object?> deleteJson(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
  });

  Future<Uint8List> getBytes(
    String path, {
    String? bearerToken,
    Map<String, String>? query,
  });
}

abstract class ApiClientBase implements ApiClient {
  ApiClientBase({required this.baseUrl});

  @override
  String baseUrl;
}
