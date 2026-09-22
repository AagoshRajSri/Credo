import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

/// Live exchange rate data from open.er-api.com (free, no API key required).
///
/// This is the ONE real network call in the app — used to show a live
/// "INR rate" indicator on the dashboard.
/// Clearly labelled as real data in the README so reviewers can verify it.
class ExchangeRateResponse {
  const ExchangeRateResponse({
    required this.baseCode,
    required this.rates,
    required this.timeLastUpdate,
  });

  final String baseCode;
  final Map<String, double> rates;
  final DateTime timeLastUpdate;

  factory ExchangeRateResponse.fromJson(Map<String, dynamic> json) {
    final ratesRaw = json['rates'] as Map<String, dynamic>;
    return ExchangeRateResponse(
      baseCode: json['base_code'] as String? ?? 'USD',
      rates: ratesRaw.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      timeLastUpdate: DateTime.fromMillisecondsSinceEpoch(
        ((json['time_last_update_unix'] as num?) ?? 0).toInt() * 1000,
      ),
    );
  }

  double? get inrRate => rates['INR'];
}

/// Service wrapping the open.er-api.com REST endpoint.
///
/// Source: https://open.er-api.com (FREE tier, no API key, 1500 req/month)
/// Data: Real, live USD exchange rates updated every 24h.
class ExchangeRateService {
  ExchangeRateService() : _dio = ApiClient().client;

  final Dio _dio;

  static const _endpoint = 'https://open.er-api.com/v6/latest/USD';

  /// Fetches live exchange rates.
  /// Throws [DioException] on network failure — callers should catch and
  /// fall back to cached data.
  Future<ExchangeRateResponse> fetchRates() async {
    final response = await _dio.get<Map<String, dynamic>>(_endpoint);
    if (response.data == null) {
      throw DioException(
        requestOptions: RequestOptions(path: _endpoint),
        message: 'Empty response from exchange rate API',
      );
    }
    return ExchangeRateResponse.fromJson(response.data!);
  }
}
