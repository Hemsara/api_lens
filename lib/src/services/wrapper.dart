// api_lens.dart
import 'package:flutter/foundation.dart';

import '../services/api_logger_service.dart';
import '../services/config.dart';

class ApiLens {
  static final ApiLens _instance = ApiLens._internal();
  factory ApiLens() => _instance;
  ApiLens._internal();

  ApiLoggerConfig _config = const ApiLoggerConfig();
  final ApiLoggerService _logger = ApiLoggerService();

  ApiLoggerConfig get config => _config;
  ApiLoggerService get logger => _logger;
  static ApiLens get instance => _instance;
  static bool get isEnabled => _instance._config.enabled;
  static bool get showDebugButton => _instance._config.showDebugButton;

  static void init({ApiLoggerConfig? config}) {
    _instance._config = config ?? const ApiLoggerConfig();

    if (_instance._config.showConsoleLogs && kDebugMode) {
      debugPrint('🔍 API Lens initialized');
      debugPrint('   • Enabled: ${_instance._config.enabled}');
      debugPrint('   • Debug Button: ${_instance._config.showDebugButton}');
      debugPrint('   • Max Logs: ${_instance._config.maxLogs}');
      debugPrint(
          '   • Auto Delete: ${_instance._config.autoDeleteAfterDays} days');
    }

    if (_instance._config.autoDeleteAfterDays > 0) {
      _instance._logger.cleanOldLogs(
        _instance._config.autoDeleteAfterDays,
        showLogs: _instance._config.showConsoleLogs,
      );
    }
  }

  static void updateConfig(ApiLoggerConfig config) {
    _instance._config = config;
    if (config.showConsoleLogs && kDebugMode) {
      debugPrint('🔍 API Lens configuration updated');
    }
  }

  static Future<void> enforceMaxLogs() async {
    await _instance._logger.enforceMaxLogs(
      _instance._config.maxLogs,
      showLogs: _instance._config.showConsoleLogs,
    );
  }

  static Future<void> clearAllLogs() async {
    await _instance._logger.clearAllLogs();
    if (_instance._config.showConsoleLogs && kDebugMode) {
      debugPrint('🔍 API Lens: All logs cleared');
    }
  }
}
