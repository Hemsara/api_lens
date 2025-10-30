import 'dart:convert';
import 'package:api_lens/src/models/api_log.dart';
import 'package:api_lens/src/services/api_logger_service.dart';
import 'package:http/http.dart' as http;



/// A wrapper around http.Client that logs all requests and responses
class ApiLensHttpClient extends http.BaseClient {
  final http.Client _inner;
  final ApiLoggerService _logger = ApiLoggerService();
  final bool enabled;

  ApiLensHttpClient({
    http.Client? client,
    this.enabled = true,
  }) : _inner = client ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!enabled) {
      return _inner.send(request);
    }

    final startTime = DateTime.now();
    final timestamp = startTime.toIso8601String();

    // Capture request details
    final requestHeaders = jsonEncode(request.headers);
    String requestBody = '';

    if (request is http.Request) {
      requestBody = request.body;
    }

    http.StreamedResponse? response;
    int statusCode = 0;
    String responseHeaders = '{}';
    String responseBody = '';

    try {
      response = await _inner.send(request);
      statusCode = response.statusCode;
      responseHeaders = jsonEncode(response.headers);

      // Read response body
      final responseBytes = await response.stream.toBytes();
      responseBody = utf8.decode(responseBytes);

      // Create a new response with the same data
      final newResponse = http.StreamedResponse(
        http.ByteStream.fromBytes(responseBytes),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      // Log the request
      await _logger.logRequest(ApiLog(
        url: request.url.toString(),
        method: request.method,
        statusCode: statusCode,
        duration: duration,
        timestamp: timestamp,
        requestHeaders: requestHeaders,
        requestBody: requestBody,
        responseHeaders: responseHeaders,
        responseBody: responseBody,
      ));

      return newResponse;
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      // Log failed request
      await _logger.logRequest(ApiLog(
        url: request.url.toString(),
        method: request.method,
        statusCode: 0,
        duration: duration,
        timestamp: timestamp,
        requestHeaders: requestHeaders,
        requestBody: requestBody,
        responseHeaders: responseHeaders,
        responseBody: 'Error: ${e.toString()}',
      ));

      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
  }
}
