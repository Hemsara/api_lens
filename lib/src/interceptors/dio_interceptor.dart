import 'dart:convert';
import 'package:api_lens/src/models/api_log.dart';
import 'package:api_lens/src/services/api_logger_service.dart';
import 'package:dio/dio.dart';



/// Dio interceptor that logs all requests and responses
class ApiLensDioInterceptor extends Interceptor {
  final ApiLoggerService _logger = ApiLoggerService();
  final bool enabled;

  ApiLensDioInterceptor({this.enabled = true});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['api_lens_start_time'] = DateTime.now();
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (enabled) {
      await _logResponse(response);
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (enabled) {
      await _logError(err);
    }
    super.onError(err, handler);
  }

  Future<void> _logResponse(Response response) async {
    final startTime =
        response.requestOptions.extra['api_lens_start_time'] as DateTime?;
    final endTime = DateTime.now();
    final duration =
        startTime != null ? endTime.difference(startTime).inMilliseconds : 0;

    final requestHeaders = jsonEncode(response.requestOptions.headers);
    final requestBody = _encodeBody(response.requestOptions.data);
    final responseHeaders = jsonEncode(response.headers.map);
    final responseBody = _encodeBody(response.data);

    await _logger.logRequest(ApiLog(
      url: response.requestOptions.uri.toString(),
      method: response.requestOptions.method,
      statusCode: response.statusCode ?? 0,
      duration: duration,
      timestamp: endTime.toIso8601String(),
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      responseHeaders: responseHeaders,
      responseBody: responseBody,
    ));
  }

  Future<void> _logError(DioException err) async {
    final startTime =
        err.requestOptions.extra['api_lens_start_time'] as DateTime?;
    final endTime = DateTime.now();
    final duration =
        startTime != null ? endTime.difference(startTime).inMilliseconds : 0;

    final requestHeaders = jsonEncode(err.requestOptions.headers);
    final requestBody = _encodeBody(err.requestOptions.data);
    final responseHeaders =
        err.response != null ? jsonEncode(err.response!.headers.map) : '{}';
    final responseBody = err.response != null
        ? _encodeBody(err.response!.data)
        : 'Error: ${err.message}';

    await _logger.logRequest(ApiLog(
      url: err.requestOptions.uri.toString(),
      method: err.requestOptions.method,
      statusCode: err.response?.statusCode ?? 0,
      duration: duration,
      timestamp: endTime.toIso8601String(),
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      responseHeaders: responseHeaders,
      responseBody: responseBody,
    ));
  }

  String _encodeBody(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    if (data is FormData) {
      return 'FormData: ${data.fields.length} fields, ${data.files.length} files';
    }
    try {
      return jsonEncode(data);
    } catch (e) {
      return data.toString();
    }
  }
}
