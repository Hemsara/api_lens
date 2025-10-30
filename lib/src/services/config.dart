import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Configuration class for API Logger
class ApiLoggerConfig {
  /// Enable/disable the logger (default: true in debug, false in release)
  final bool enabled;

  /// Show floating debug button (default: true in debug, false in release)
  final bool showDebugButton;

  /// Position of the floating button
  final FloatingButtonPosition buttonPosition;

  /// Maximum number of logs to keep (default: 200)
  final int maxLogs;

  /// Auto-delete logs older than X days (0 = disabled)
  final int autoDeleteAfterDays;

  /// Show console logs when API requests are made
  final bool showConsoleLogs;

  /// Custom button color (optional)
  final Color? buttonColor;

  /// Button icon (optional)
  final IconData? buttonIcon;

  /// Button size
  final double buttonSize;

  const ApiLoggerConfig({
    bool? enabled,
    bool? showDebugButton,
    this.buttonPosition = FloatingButtonPosition.bottomRight,
    this.maxLogs = 200,
    this.autoDeleteAfterDays = 7,
    this.showConsoleLogs = true,
    this.buttonColor,
    this.buttonIcon,
    this.buttonSize = 56.0,
  })  : enabled = enabled ?? kDebugMode,
        showDebugButton = showDebugButton ?? kDebugMode;

  /// Default configuration for debug mode
  static const debug = ApiLoggerConfig(
    enabled: true,
    showDebugButton: true,
    showConsoleLogs: true,
  );

  /// Default configuration for release mode
  static const release = ApiLoggerConfig(
    enabled: false,
    showDebugButton: false,
    showConsoleLogs: false,
  );

  /// Minimal configuration (logging enabled, no UI)
  static const minimal = ApiLoggerConfig(
    enabled: true,
    showDebugButton: false,
    showConsoleLogs: false,
  );

  ApiLoggerConfig copyWith({
    bool? enabled,
    bool? showDebugButton,
    FloatingButtonPosition? buttonPosition,
    int? maxLogs,
    int? autoDeleteAfterDays,
    bool? showConsoleLogs,
    Color? buttonColor,
    IconData? buttonIcon,
    double? buttonSize,
  }) {
    return ApiLoggerConfig(
      enabled: enabled ?? this.enabled,
      showDebugButton: showDebugButton ?? this.showDebugButton,
      buttonPosition: buttonPosition ?? this.buttonPosition,
      maxLogs: maxLogs ?? this.maxLogs,
      autoDeleteAfterDays: autoDeleteAfterDays ?? this.autoDeleteAfterDays,
      showConsoleLogs: showConsoleLogs ?? this.showConsoleLogs,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonIcon: buttonIcon ?? this.buttonIcon,
      buttonSize: buttonSize ?? this.buttonSize,
    );
  }
}

enum FloatingButtonPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}
