import 'package:flutter_test/flutter_test.dart';

import 'package:api_lens/api_lens.dart';

void main() {
  group('ApiLoggerService', () {
    final logger = ApiLoggerService();

    test('should log and retrieve an API request', () async {
      final log = ApiLog(
        url: 'https://example.com',
        method: 'GET',
        statusCode: 200,
        duration: 150,
        timestamp: DateTime.now().toIso8601String(),
        requestHeaders: '{}',
        requestBody: '',
        responseHeaders: '{}',
        responseBody: '{"success": true}',
      );

      final id = await logger.logRequest(log);
      final retrievedLog = await logger.getLogById(id);

      expect(retrievedLog, isNotNull);
      expect(retrievedLog!.url, equals(log.url));
      expect(retrievedLog.method, equals(log.method));
      expect(retrievedLog.statusCode, equals(log.statusCode));
    });

    test('should retrieve all logs', () async {
      final logs = await logger.getAllLogs();
      expect(logs, isA<List<ApiLog>>());
    });
  });
}
