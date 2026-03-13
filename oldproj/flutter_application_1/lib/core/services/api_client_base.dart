class ApiError implements Exception {
  ApiError({required this.code, required this.message, this.statusCode, this.extra});

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
}

abstract class ApiClientBase implements ApiClient {
  ApiClientBase({required this.baseUrl});

  @override
  String baseUrl;
}
