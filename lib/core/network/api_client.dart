import 'package:dio/dio.dart';

/// Dio HTTP client wrapper.
///
/// Phase 1: stub with base options and an error interceptor.
/// Phase 2: add real endpoints, auth headers, and retry logic.
class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  // DECISION: Base URL points to a public finance sandbox.
  // In Phase 2 we will point this at a real free API
  // (e.g. exchangerate.host or a mock server) and add an asset fallback.
  static const String _baseUrl = 'https://api.exchangerate.host';

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.addAll([
      _LogInterceptor(),
      _ErrorInterceptor(),
    ]);

  Dio get client => _dio;
}

/// Logs requests and responses in debug mode.
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO(Phase 2): add structured logging
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO(Phase 2): map DioException types to domain errors
    handler.next(err);
  }
}

/// Converts Dio errors into friendlier messages for the UI.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO(Phase 2): emit typed CredoError objects
    handler.next(err);
  }
}
