import 'api_client_io.dart'
    if (dart.library.html) 'api_client_web.dart'
    as impl;

export 'api_client_base.dart';
import 'api_client_base.dart';

ApiClient createApiClient({required String baseUrl}) =>
    impl.ApiClientImpl(baseUrl: baseUrl);
